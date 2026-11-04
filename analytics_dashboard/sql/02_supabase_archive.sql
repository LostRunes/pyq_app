-- Run in the SUPABASE SQL editor, AFTER 01_neon.sql.

-- 1. Make the new Neon column visible through the foreign table.
alter foreign table public.neon_analytics_events
  add column if not exists platform text;

-- 2. (Batch sizes for the Neon connection are set in 03_supabase_dashboard_api.sql.)

-- 3. Archive in bounded batches. Copies a batch to Neon, then deletes exactly
--    that batch locally. If the copy fails, nothing is deleted.
create or replace function public.archive_analytics_to_neon(batch_limit integer default 20000)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  moved integer;
begin
  -- Don't let a manual run and the cron run overlap.
  if not pg_try_advisory_xact_lock(hashtext('archive_analytics_to_neon')) then
    raise notice 'Archive already running, skipping';
    return 0;
  end if;

  drop table if exists pg_temp.archive_batch;
  create temp table archive_batch on commit drop as
    select id
    from public.user_analytics_events
    where created_at < now() - interval '24 hours'
    order by created_at
    limit batch_limit;

  insert into public.neon_analytics_events
    (id, user_id, event_type, event_name, screen_name, metadata, created_at, platform)
  select e.id, e.user_id::text, e.event_type, e.event_name, e.screen_name,
         e.metadata, e.created_at, coalesce(e.platform::text, 'app')
  from public.user_analytics_events e
  join archive_batch b on b.id = e.id
  on conflict do nothing;  -- already in Neon from an earlier run: skip

  delete from public.user_analytics_events e
  using archive_batch b
  where e.id = b.id;

  get diagnostics moved = row_count;
  return moved;
end;
$$;

revoke all on function public.archive_analytics_to_neon(integer) from public, anon, authenticated;

-- 4. Replace the nightly job (same name and time: 18:30 UTC = 00:00 IST).
--    50k per night is ~18x the normal daily volume, so it can never snowball again.
--    The ANALYZE refreshes the planner's row estimate for the Neon table; without it
--    Postgres thinks the table is tiny and won't send ORDER BY/LIMIT to Neon.
select cron.schedule(
  'archive-analytics-to-neon',
  '30 18 * * *',
  $job$set statement_timeout = '20min'; select public.archive_analytics_to_neon(50000); analyze public.neon_analytics_events;$job$
);

-- 5. Archived events now keep their real platform.
create or replace view public.v_neon_analytics as
select ne.id, ne.user_id, p.username, p.display_name, u.email,
       ne.event_type, ne.event_name, ne.screen_name, ne.metadata, ne.created_at,
       'neon'::text as source,
       coalesce(ne.platform, 'app')::text as platform
from public.neon_analytics_events ne
left join public.user_profiles p on ne.user_id = p.id::text
left join auth.users u on ne.user_id = u.id::text;
