-- Run in the SUPABASE SQL editor, AFTER 02_supabase_archive.sql.
--
-- Why the Neon view was slow: v_neon_analytics joins the Neon rows with
-- user_profiles/auth.users inside Supabase, so Postgres can't push
-- "ORDER BY created_at DESC LIMIT n" to Neon. It pulled the whole table
-- (~280k rows) from us-east-1 to ap-south-1, 100 rows per ~200 ms round trip.
--
-- These functions filter, sort and limit ON NEON first (one round trip),
-- then attach usernames/emails to just those rows.

-- 1. Ship rows in big batches instead of 100 per round trip.
do $$
declare
  opt text;
  k text;
  v text;
begin
  foreach opt in array array['fetch_size=10000', 'batch_size=1000'] loop
    k := split_part(opt, '=', 1);
    v := split_part(opt, '=', 2);
    if exists (select 1 from pg_foreign_server s, unnest(s.srvoptions) o
               where s.srvname = 'neon_server' and o like k || '=%') then
      execute format('alter server neon_server options (set %I %L)', k, v);
    else
      execute format('alter server neon_server options (add %I %L)', k, v);
    end if;
  end loop;
end $$;

-- 2. Row count and date range of a source (aggregates run on Neon).
create or replace function public.analytics_bounds(p_source text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  result jsonb;
begin
  if p_source = 'neon' then
    select jsonb_build_object('count', count(*), 'oldest', min(created_at), 'newest', max(created_at))
      into result from public.neon_analytics_events;
  elsif p_source = 'supabase' then
    select jsonb_build_object('count', count(*), 'oldest', min(created_at), 'newest', max(created_at))
      into result from public.user_analytics_events;
  else
    raise exception 'unknown source: %', p_source;
  end if;
  return result;
end;
$$;

-- 3. One page of events, newest first, within [p_from, p_to), continuing after
--    the (p_cursor_ts, p_cursor_id) of the previous page's last row.
--    Returns a JSON array so PostgREST's 1000-row cap doesn't truncate pages.
create or replace function public.analytics_events_page(
  p_source text,
  p_from timestamptz default '-infinity',
  p_to timestamptz default 'infinity',
  p_cursor_ts timestamptz default null,
  p_cursor_id uuid default null,
  p_limit integer default 2000
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  n integer := least(greatest(coalesce(p_limit, 2000), 1), 5000);
  tbl text;
  cursor_filter text := '';
  result jsonb;
begin
  if p_source = 'neon' then
    tbl := 'public.neon_analytics_events';
  elsif p_source = 'supabase' then
    tbl := 'public.user_analytics_events';
  else
    raise exception 'unknown source: %', p_source;
  end if;

  if p_cursor_ts is not null then
    cursor_filter := format(
      ' and (created_at < %L::timestamptz or (created_at = %L::timestamptz and id < %L::uuid))',
      p_cursor_ts, p_cursor_ts, p_cursor_id);
  end if;

  -- Literal values (not parameters) so the WHERE/ORDER BY/LIMIT in the inner
  -- query are sent to Neon as-is.
  execute format($q$
    select coalesce(jsonb_agg(jsonb_build_object(
             'id', e.id,
             'user_id', e.user_id::text,
             'username', p.username,
             'display_name', p.display_name,
             'email', u.email,
             'event_type', e.event_type,
             'event_name', e.event_name,
             'screen_name', e.screen_name,
             'metadata', e.metadata,
             'created_at', e.created_at,
             'source', %L,
             'platform', coalesce(e.platform::text, 'app')
           ) order by e.created_at desc, e.id desc), '[]'::jsonb)
    from (
      select id, user_id, event_type, event_name, screen_name, metadata, created_at, platform
      from %s
      where created_at >= %L::timestamptz and created_at < %L::timestamptz %s
      order by created_at desc, id desc
      limit %s
    ) e
    left join public.user_profiles p on p.id::text = e.user_id::text
    left join auth.users u on u.id::text = e.user_id::text
  $q$, p_source, tbl, coalesce(p_from, '-infinity'), coalesce(p_to, 'infinity'), cursor_filter, n)
  into result;

  return result;
end;
$$;

-- 4. Access: same as the existing views for now (the dashboard uses the anon key).
--    The admin-login step will revoke anon and add an admin check here.
revoke all on function public.analytics_bounds(text) from public;
revoke all on function public.analytics_events_page(text, timestamptz, timestamptz, timestamptz, uuid, integer) from public;
grant execute on function public.analytics_bounds(text) to anon, authenticated;
grant execute on function public.analytics_events_page(text, timestamptz, timestamptz, timestamptz, uuid, integer) to anon, authenticated;
