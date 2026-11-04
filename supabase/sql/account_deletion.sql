-- In-app account deletion (App Store guideline 5.1.1(v)).
--
-- Run this whole file in BOTH Supabase projects (SQL editor):
--   1. main project    (bjmrsrypznobolwumjhe) - profiles, Skulk, rooms, progress, analytics
--   2. content project (hoihnpzdlivaoywrshmk) - its own login for the same user
-- It is safe to run more than once.
--
-- The app calls  rpc('delete_my_account')  as the signed-in user. The function
-- deletes every row that belongs to that user, then the login itself.
-- Instead of hard-coding one DELETE per table, it reads the foreign keys from
-- the catalog and deletes dependent rows first, so it keeps working when
-- tables are added (e.g. other people's answers on the user's doubt, votes on
-- the user's answers, replies to the user's comments).

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- Deletes the rows of p_table matching p_where, after first deleting every row
-- (in any public table) that references them through a foreign key.
create or replace function private.cascade_delete(
  p_table regclass,
  p_where text,
  p_depth integer default 0
)
returns void
language plpgsql
set search_path = public, pg_temp
as $$
declare
  fk record;
begin
  if p_depth > 8 then
    raise exception 'delete_my_account: foreign keys nest too deeply at %', p_table;
  end if;

  -- Self-references (e.g. comments.parent_comment_id): widen the set to the
  -- whole reply tree so one DELETE removes parents and children together.
  for fk in
    select ca.attname as child_col, pa.attname as parent_col
    from pg_constraint c
    join pg_attribute ca on ca.attrelid = c.conrelid and ca.attnum = c.conkey[1]
    join pg_attribute pa on pa.attrelid = c.confrelid and pa.attnum = c.confkey[1]
    where c.contype = 'f'
      and c.conrelid = p_table
      and c.confrelid = p_table
      and cardinality(c.conkey) = 1
  loop
    p_where := format(
      '%1$I in (with recursive tree as (
                  select %1$I as k from %2$s where %3$s
                  union
                  select c.%1$I from %2$s c join tree on c.%4$I = tree.k)
                select k from tree)',
      fk.parent_col, p_table, p_where, fk.child_col);
  end loop;

  -- Children in other tables first (skip SET NULL / SET DEFAULT keys).
  for fk in
    select c.conrelid::regclass as child_table,
           ca.attname as child_col,
           pa.attname as parent_col
    from pg_constraint c
    join pg_attribute ca on ca.attrelid = c.conrelid and ca.attnum = c.conkey[1]
    join pg_attribute pa on pa.attrelid = c.confrelid and pa.attnum = c.confkey[1]
    join pg_class cl on cl.oid = c.conrelid
    join pg_namespace n on n.oid = cl.relnamespace
    where c.contype = 'f'
      and c.confrelid = p_table
      and c.conrelid <> p_table
      and cardinality(c.conkey) = 1
      and c.confdeltype not in ('n', 'd')
      and n.nspname = 'public'
  loop
    perform private.cascade_delete(
      fk.child_table,
      format('%I in (select %I from %s where %s)', fk.child_col, fk.parent_col, p_table, p_where),
      p_depth + 1);
  end loop;

  execute format('delete from %s where %s', p_table, p_where);
end;
$$;

-- Analytics rows already archived to Neon are removed by the nightly job
-- (a cross-region delete inside the request could hit the statement timeout).
create table if not exists private.analytics_deletion_queue (
  user_id text primary key,
  requested_at timestamptz not null default now()
);

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  t record;
begin
  if uid is null then
    raise exception 'Not signed in' using errcode = '28000';
  end if;

  -- 1. Rows owned through a plain user column (some have no foreign key,
  --    e.g. user_analytics_events.user_id).
  for t in
    select c.table_name, c.column_name
    from information_schema.columns c
    join information_schema.tables tb
      on tb.table_schema = c.table_schema and tb.table_name = c.table_name
    where c.table_schema = 'public'
      and tb.table_type = 'BASE TABLE'
      and c.column_name in ('user_id', 'reporter_id', 'created_by', 'author_id', 'owner_id',
                            'uploaded_by', 'sender_id', 'blocker_id', 'blocked_id',
                            'reported_user_id')
  loop
    perform private.cascade_delete(
      format('public.%I', t.table_name)::regclass,
      format('%I::text = %L', t.column_name, uid::text));
  end loop;

  -- 2. The profile row and everything that points at it.
  if to_regclass('public.user_profiles') is not null then
    perform private.cascade_delete('public.user_profiles'::regclass, format('id::text = %L', uid::text));
  end if;

  -- 3. Any other public table that references the login directly.
  for t in
    select c.conrelid::regclass as child_table, ca.attname as child_col
    from pg_constraint c
    join pg_attribute ca on ca.attrelid = c.conrelid and ca.attnum = c.conkey[1]
    join pg_class cl on cl.oid = c.conrelid
    join pg_namespace n on n.oid = cl.relnamespace
    where c.contype = 'f'
      and c.confrelid = 'auth.users'::regclass
      and cardinality(c.conkey) = 1
      and n.nspname = 'public'
  loop
    perform private.cascade_delete(t.child_table, format('%I::text = %L', t.child_col, uid::text));
  end loop;

  -- 4. Archived analytics in Neon (main project only): queue for the nightly job.
  if to_regclass('public.neon_analytics_events') is not null then
    insert into private.analytics_deletion_queue (user_id)
    values (uid::text)
    on conflict (user_id) do nothing;
  end if;

  -- 5. The login itself (sessions and identities cascade inside auth).
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- Main project only: purge queued users from the Neon archive every night,
-- as part of the existing archive job.
create or replace function private.purge_deleted_users_analytics()
returns integer
language plpgsql
set search_path = public, pg_temp
as $$
declare
  removed integer := 0;
begin
  if to_regclass('public.neon_analytics_events') is null then
    return 0;
  end if;
  delete from public.neon_analytics_events
  where user_id in (select user_id from private.analytics_deletion_queue);
  get diagnostics removed = row_count;
  delete from private.analytics_deletion_queue;
  return removed;
end;
$$;

do $$
begin
  if to_regclass('public.neon_analytics_events') is not null
     and to_regclass('cron.job') is not null then
    perform cron.schedule(
      'archive-analytics-to-neon',
      '30 18 * * *',
      $job$set statement_timeout = '20min'; select public.archive_analytics_to_neon(50000); select private.purge_deleted_users_analytics(); analyze public.neon_analytics_events;$job$
    );
  end if;
end $$;
