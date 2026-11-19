-- Custom (personal) study rooms: the host can remove members, and anyone can
-- report a user.
--
-- Run in the MAIN Supabase project only (bjmrsrypznobolwumjhe), SQL editor.
-- Safe to run more than once.

-- 1. Members removed from a room by its host. A removed user cannot send
--    messages or get a voice token for that room. Only the host of a
--    personal room can add or remove rows (done through the room-kick
--    function, which also drops the user from the live voice call).
create table if not exists public.room_bans (
  room_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  banned_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

alter table public.room_bans enable row level security;

-- The removed user sees their own rows (so the app can close the room for
-- them); the host sees everyone removed from their rooms.
drop policy if exists "room_bans: read" on public.room_bans;
create policy "room_bans: read" on public.room_bans
  for select to authenticated using (
    user_id = auth.uid()
    or exists (
      select 1 from public.study_rooms r
      where r.id::text = room_bans.room_id
        and r.created_by::text = auth.uid()::text
    )
  );

-- The host can let someone back in.
drop policy if exists "room_bans: host unbans" on public.room_bans;
create policy "room_bans: host unbans" on public.room_bans
  for delete to authenticated using (
    exists (
      select 1 from public.study_rooms r
      where r.id::text = room_bans.room_id
        and r.created_by::text = auth.uid()::text
    )
  );

grant select, delete on public.room_bans to authenticated;

-- Live updates so a removed user's app leaves the room immediately.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'room_bans'
  ) then
    alter publication supabase_realtime add table public.room_bans;
  end if;
end $$;

-- 2. Removed users cannot post in that room. RESTRICTIVE, so it is applied on
--    top of the existing insert policy instead of replacing it.
drop policy if exists "room_messages: not banned" on public.room_messages;
create policy "room_messages: not banned" on public.room_messages
  as restrictive
  for insert to authenticated
  with check (
    not exists (
      select 1 from public.room_bans b
      where b.room_id = room_messages.room_id::text
        and b.user_id = auth.uid()
    )
  );

-- 3. Reports against a user (from a study room). One report per reporter,
--    user and room.
create table if not exists public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reported_user_id uuid not null,
  room_id text,
  reason text not null,
  details text,
  created_at timestamptz not null default now(),
  constraint user_reports_not_self check (reporter_id <> reported_user_id)
);

create unique index if not exists user_reports_once
  on public.user_reports (reporter_id, reported_user_id, coalesce(room_id, ''));

alter table public.user_reports enable row level security;

drop policy if exists "user_reports: report as self" on public.user_reports;
create policy "user_reports: report as self" on public.user_reports
  for insert to authenticated with check (reporter_id = auth.uid());

grant insert on public.user_reports to authenticated;

-- For moderators: user reports from the last 7 days.
-- select r.created_at, r.reason, r.details, r.room_id,
--        p.username as reported, q.username as reporter
-- from public.user_reports r
-- left join public.user_profiles p on p.id::text = r.reported_user_id::text
-- left join public.user_profiles q on q.id::text = r.reporter_id::text
-- where r.created_at > now() - interval '7 days'
-- order by r.created_at desc;
