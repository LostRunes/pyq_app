# Pre-Release Checklist

Things that are done in code but **not live yet**, plus what to verify before publishing the next app version.

---

## 1. LiveKit participant-count reconcile (`livekit-cleanup`)

### The problem
`study_rooms.participant_count` is only changed by the app calling
`update_room_participant_count` with `+1` on join and `-1` on leave
(`lib/features/skulk/study_together/data/services/study_together_service.dart`).
If the app crashes, is swiped away, the phone dies, or the network never comes back,
the `-1` is never sent. Result:

- Rooms show people "in the room" when nobody is there.
- `livekit-cleanup` only closes voice rooms with `participant_count = 0`, so a leaked
  custom room is never closed or deleted. Permanent lounges drift upward over time.

### The fix (already written, not deployed)
`supabase/functions/livekit-cleanup/index.ts` now runs a **step 0** before the existing
cleanup steps:

1. Loads active voice rooms created more than 2 minutes ago (grace period so a room
   isn't zeroed while its creator is still connecting).
2. Asks LiveKit for real occupancy with `RoomServiceClient.listRooms(roomIds)`. LiveKit room
   names are the `study_rooms.id` (see the `room: room_id` grant in `livekit-token`).
   A room LiveKit doesn't return has nobody in it, so its count is 0.
3. Writes the real count wherever it differs from `participant_count`.

Other changes that go with it:
- The "close empty rooms" step now uses `participant_count <= 0` instead of `= 0`. If a
  client's `-1` lands just after a reconcile, the count can dip to `-1`; the next run
  corrects it.
- The app's `StudyRoom.fromJson` clamps the count to `>= 0`, so a brief `-1` is never
  shown (`lib/features/skulk/study_together/data/models/study_room.dart`).
- The response JSON includes a `reconciled` field listing the rooms that were corrected.

It is safe for the current app. The app's +1/-1 logic is unchanged, and if LiveKit
can't be reached (or config is missing) the reconcile is skipped and the counts are left as they are.

### To deploy
```
npx supabase functions deploy livekit-cleanup
```
- No new secrets needed: it uses `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET` and
  `LIVEKIT_URL`, which `livekit-token` already uses. Supabase secrets are per project.
- `LIVEKIT_URL` is `wss://...`; the function converts it to `https://...` for the server API.

### Verify after deploying
- [ ] Check that `study_rooms` has a `created_at` column (the grace-period filter uses it).
- [ ] Invoke the function once and check the response has `reconciled.updated`, not
      `reconciled.skipped`. If it says `skipped`, check the function logs.
- [ ] Join a voice room from a phone, force-kill the app, wait for the next cleanup run,
      and confirm the room's count drops back.
- [ ] Confirm the permanent lounges still show correct counts and are never closed.

---

## 2. Other edge functions changed in the bug-fix pass (not deployed)

These were security-hardened in source only. Deploy them to the secondary project
(`bjmrsrypznobolwumjhe`) so the fixes take effect:

```
npx supabase functions deploy livekit-token
npx supabase functions deploy send-push-notification
npx supabase functions deploy share-post
npx supabase functions deploy solve-question
```

- [ ] `livekit-token`: join a voice room while logged in. It should work as before.
      Signed-out callers now get `401`.
- [ ] `send-push-notification`: trigger a real notification (comment or answer) and confirm
      the push arrives. It now reloads the notification row by `record.id` instead of
      trusting the request body.
- [ ] `share-post`: open a shared post link and check the preview page renders.

---

## 3. App-side changes that ship with the next build

- [ ] **Cold-start notification tap:** with the app fully closed, tap a push notification.
      It should open the post or room after the home screen loads (previously it
      stayed on the home screen).
