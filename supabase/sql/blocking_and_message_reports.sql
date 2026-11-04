-- Blocking users + reporting study-room chat messages (App Store guideline 1.2).
--
-- Run in the MAIN Supabase project only (bjmrsrypznobolwumjhe), SQL editor.
-- Safe to run more than once.

-- 1. Who each user has blocked. Users only ever see their own rows.
create table if not exists public.user_blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint user_blocks_not_self check (blocker_id <> blocked_id)
);

alter table public.user_blocks enable row level security;

drop policy if exists "user_blocks: read own" on public.user_blocks;
create policy "user_blocks: read own" on public.user_blocks
  for select to authenticated using (blocker_id = auth.uid());

drop policy if exists "user_blocks: block others" on public.user_blocks;
create policy "user_blocks: block others" on public.user_blocks
  for insert to authenticated with check (blocker_id = auth.uid());

drop policy if exists "user_blocks: unblock" on public.user_blocks;
create policy "user_blocks: unblock" on public.user_blocks
  for delete to authenticated using (blocker_id = auth.uid());

grant select, insert, delete on public.user_blocks to authenticated;

-- 2. Reports on study-room chat messages. The message text is copied in so a
--    moderator can still read it if the sender unsends it.
create table if not exists public.message_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  message_id text not null,
  room_id text,
  reported_user_id uuid,
  message_text text,
  reason text not null default 'inappropriate',
  created_at timestamptz not null default now(),
  constraint message_reports_once unique (reporter_id, message_id)
);

alter table public.message_reports enable row level security;

drop policy if exists "message_reports: report as self" on public.message_reports;
create policy "message_reports: report as self" on public.message_reports
  for insert to authenticated with check (reporter_id = auth.uid());

grant insert on public.message_reports to authenticated;

-- 3. Display names for the "Blocked users" list in Settings.
--    (Only id/username/display_name/avatar of users the caller has blocked.)
create or replace function public.my_blocked_users()
returns table (id uuid, username text, display_name text, avatar_url text, blocked_at timestamptz)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select b.blocked_id, p.username::text, p.display_name::text, p.avatar_url::text, b.created_at
  from public.user_blocks b
  left join public.user_profiles p on p.id::text = b.blocked_id::text
  where b.blocker_id = auth.uid()
  order by b.created_at desc;
$$;

revoke all on function public.my_blocked_users() from public, anon;
grant execute on function public.my_blocked_users() to authenticated;

-- 4. For moderators: everything reported in the last 7 days, newest first.
--    Run this in the SQL editor regularly (Apple expects reports to be acted on
--    within 24 hours).
-- select 'post' as kind, r.created_at, r.reason, r.post_id::text as target from public.reports r
-- where r.created_at > now() - interval '7 days'
-- union all
-- select 'chat', m.created_at, m.reason, m.message_text from public.message_reports m
-- where m.created_at > now() - interval '7 days'
-- order by created_at desc;
