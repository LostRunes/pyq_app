-- Run in the NEON SQL editor (database: neondb). In Neon the table is user_analytics_events;
-- Supabase sees it as the foreign table neon_analytics_events.
-- ALREADY APPLIED on 2026-10-29 by the CSV upload (platform column + index; id was already the primary key).

-- 1. Keep the mobile/desktop split for archived events.
alter table user_analytics_events
  add column if not exists platform text not null default 'app';

-- 2. Lets "newest N events" and date-range queries use an index.
create index if not exists user_analytics_events_created_at_idx
  on user_analytics_events (created_at desc);

-- 3. Check that id is unique (needed so re-archiving the same row is skipped, not duplicated).
select conname, contype
from pg_constraint
where conrelid = 'user_analytics_events'::regclass and contype in ('p', 'u');
-- If step 3 returns NO rows, run this too:
-- alter table user_analytics_events add primary key (id);
