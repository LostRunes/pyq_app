# FocusFox — Full Project Audit

## 1. Navigation Bar Blob Lag (Root Cause)

**File:** [`main_navigation_screen.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/auth/presentation/screens/main_navigation_screen.dart#L684-L699)

The blob uses `AnimatedPositioned` driven by `_currentIndex` via `setState`. When the user **taps** a nav item, `setState` sets `_currentIndex` immediately, then calls `_pageController.animateToPage(...)`. During the 300ms page animation, `PageView.onPageChanged` fires multiple times for intermediate page positions, each calling `setState(() { _currentIndex = index; })` with the intermediate index — making the blob jump back and forth before settling.

**Fix:** Add an `_isAnimatingPage` guard flag to suppress `onPageChanged` during programmatic animations:

```dart
// In _buildNavBarItem onTap:
setState(() { _currentIndex = index; _isAnimatingPage = true; ... });
_pageController.animateToPage(...).then((_) {
  if (mounted) setState(() => _isAnimatingPage = false);
});

// In PageView onPageChanged:
onPageChanged: (index) {
  if (_isAnimatingPage) return; // suppress intermediate callbacks
  setState(() { _currentIndex = index; ... });
}
```

---

## 2. State Management — Critical Issues

### 2a. `signOutCompletely()` bypasses Riverpod — Stale State After Logout

**File:** [`providers.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/core/providers.dart#L40-L64)

`signOutCompletely()` calls `SharedPreferences.getInstance()` directly instead of using the injected `sharedPrefsProvider`. After logout, `selectedBranchIdProvider` and `selectedSemesterProvider` are **never invalidated** — they hold the previous user's data in memory. If another user logs in the same session, those providers serve stale data.

**Fix:** `signOutCompletely` should accept a `Ref` and call `ref.invalidate()` on all relevant providers after clearing prefs.

---

### 2b. `userProfileProvider` — Never Invalidated After Login/Logout

**File:** [`user_profile_provider.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/core/providers/user_profile_provider.dart)

Plain `FutureProvider` (not `autoDispose`) — fetches the profile once and caches it forever:
- Old profile shown in avatar if user switches accounts.
- Profile updates don't reflect without a full app restart.
- No dependency on auth state changes.

**Fix:** Use `FutureProvider.autoDispose`, or a `StreamProvider` watching `Supabase.instance.client.auth.onAuthStateChange`.

---

### 2c. `themeModeProvider` — Not Persisted Across App Launches

**File:** [`theme_provider.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/core/providers/theme_provider.dart)

The theme always starts as `ThemeMode.light` on cold start. `beeEnabledProvider` is correctly persisted to SharedPreferences using the exact same pattern — the theme notifier should do the same.

**Fix:** Read/write `'theme_mode'` from SharedPreferences in `ThemeModeNotifier`, mirroring `BeeEnabledNotifier`.

---

### 2d. Skulk Filter Providers — `isAutoDispose: true` Wipes User Filters

**File:** [`skulk_providers.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/skulk/presentation/providers/skulk_providers.dart#L33-L82)

`skulkFeedFilterProvider`, `skulkFeedSearchProvider`, `skulkFeedSubjectProvider`, and `skulkFeedTagProvider` are all `isAutoDispose: true`. When the user navigates into a doubt detail screen (popping the widget tree), all listeners on these providers are dropped, triggering disposal. On return, the filter resets to `'all'` — the user's selected filter is wiped.

**Fix:** Remove `isAutoDispose: true` from the filter/search providers. Keep it only on `skulkFeedProvider` itself, where reset-on-disposal is acceptable.

---

### 2e. `DoubtDetailNotifier` / `SolutionsNotifier` — Anti-Pattern: `Notifier<AsyncValue<T>>`

**File:** [`skulk_providers.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/skulk/presentation/providers/skulk_providers.dart#L390-L435)

Both notifiers call async `_load*()` methods from inside `build()` and return a sync empty/loading value. This creates:
- Inability to distinguish "not yet loaded" from "genuinely empty".
- Deeply nested `.state.hasValue` checks throughout the vote-toggle logic.
- This is exactly the use case `AsyncNotifier<T>` was designed for.

**Fix:** Convert `DoubtDetailNotifier` to `AsyncNotifier<Doubt?>` and `SolutionsNotifier` to `AsyncNotifier<List<Solution>>`.

---

### 2f. Duplicate State: `_currentBranchId` / `_currentSemester` vs Providers

**File:** [`main_navigation_screen.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/auth/presentation/screens/main_navigation_screen.dart#L38-L88)

Local fields `_currentSemester` and `_currentBranchId` mirror `selectedSemesterProvider` / `selectedBranchIdProvider` exactly, with manual sync in `build()`. This is a single-source-of-truth violation.

Additionally, `initState` uses `Future.microtask` to write to providers, which fires *after* the first `build()`. `SubjectsPage` then fetches on the stale prefs value, then fetches again when the microtask fires — a guaranteed double network request on every cold launch.

**Fix:** Remove local duplicates. Read providers directly in `_buildSkulkPage`. Write to providers synchronously in `initState` (not via microtask).

---

## 3. Architecture / Logic Issues

### 3a. `supabase1/2ClientProvider` Create New `SupabaseClient` Per ProviderScope

**File:** [`providers.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/core/providers.dart#L12-L24)

These create a brand-new `SupabaseClient` object each time, each with its own connection pool and realtime socket. This is a resource leak that will worsen under load. The singleton `Supabase.instance.client` should be used directly.

---

### 3b. Branch Lookup Fetches Full Table on Every Login

**File:** [`auth_repository.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/auth/data/repositories/auth_repository.dart#L92-L119)

`_getBranchIdFromSection()` fetches all branches on every KIIT login. Fine now, but a scalability bottleneck. Should be cached or resolved server-side.

---

### 3c. `_getSemesterFromBatch` — Undocumented Batch Format, Silent Wrong Mapping

**File:** [`auth_repository.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/auth/data/repositories/auth_repository.dart#L146-L159)

The `batch` string format is completely undocumented. If it's ever not a simple numeric offset, every KIIT user gets the wrong semester with no error logged.

---

### 3d. Deep Link Args Type Mismatch — Latent Crash

**File:** [`router.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/app/router.dart#L36-L44)

The `/skulk/doubt/:id` deep link passes `doubtId` as a raw `String` in `settings.arguments`. But `DoubtDetailScreen` at `/skulk_detail` expects `Map<String, dynamic>` with `'doubtId'`, `'branchId'`, `'semester'` keys. Any user arriving via a deep link hits a type cast error and crashes.

---

### 3e. `ToDoDashboardScreen` — `firstWhere` Without `orElse` — Crash Risk

**File:** [`todo_dashboard_screen.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/utilities/presentation/screens/todo_dashboard_screen.dart#L117)

```dart
final sub = subjects.firstWhere((s) => s.id == _selectedSubjectId);
final top = topics.firstWhere((t) => t.id == _selectedTopicId);
```

No `orElse`. If the provider reloads and the selected ID is no longer in the list, this throws `StateError: No element` and crashes the app.

---

### 3f. "My Subjects" Skulk Filter Applied Client-Side Only

**File:** [`skulk_feed_screen.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/skulk/presentation/screens/skulk_feed_screen.dart#L152-L158)

The `'subjects'` filter fetches a full page of 20 "all" doubts, then filters them in-memory. If none of the 20 match the user's subjects, the list appears empty — even if relevant doubts exist on later pages. Pagination doesn't account for this client-side reduction, so the "seen it all" / empty state fires incorrectly.

---

### 3g. Search Notifiers Expose Raw `set state` — Anti-Pattern

**Files:** [`subjects_providers.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/subjects/presentation/providers/subjects_providers.dart#L34-L44), [`prep_zone_providers.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/prep_zone/presentation/providers/prep_zone_providers.dart), [`utilities_providers.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/utilities/presentation/providers/utilities_providers.dart)

All three search notifiers override `set state` to be public, bypassing encapsulation. Riverpod discourages direct `state` mutation from outside the notifier. These should expose a named method like `updateSearch(String query)`.

---

### 3h. `SkulkDbService` — No Dependency Injection

**File:** [`skulk_providers.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/skulk/presentation/providers/skulk_providers.dart#L10-L12)

`SkulkDbService()` is constructed with no injected `SupabaseClient`, breaking the DI pattern every other repository in the project follows. Untestable in isolation.

---

### 3i. Unread Notification Badge Count Never Updates at Runtime

**File:** [`skulk_feed_screen.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/skulk/presentation/screens/skulk_feed_screen.dart#L534-L537)

`unreadCountProvider` is a `FutureProvider.autoDispose` that fetches once on build. The badge count will never change while the app is open. Users receiving new notifications won't see the indicator update.

**Fix:** Subscribe to a Supabase realtime channel on the notifications table, or use a periodic timer with `ref.invalidateSelf()`.

---

## 4. Splash Screen Issues

### 4a. Animation Ends Before Auth Resolves — Frozen Screen

**File:** [`splash_screen.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/auth/presentation/screens/splash_screen.dart#L50-L134)

The animation is 1800ms, the delay is 2000ms — leaving 200ms of frozen screen after animation ends. The actual DB fetch then runs inside `addPostFrameCallback`, adding another frame delay. On slow connections, the splash can freeze indefinitely with no loading state shown.

---

### 4b. Network Errors Silently Redirect to `/selection`

**File:** [`splash_screen.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/auth/presentation/screens/splash_screen.dart#L126-L133)

The `catch` block swallows all errors with only a `debugPrint` and falls through to `/selection`. A transient network error is indistinguishable from "user not set up", causing a logged-in user to be sent to the branch selection screen.

---

## 5. Missing / Incomplete Features

### 5a. Avatar URL Always Loaded as `AssetImage` — Will Crash on Remote URLs

**File:** [`main_navigation_screen.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/auth/presentation/screens/main_navigation_screen.dart#L235-L243)

```dart
backgroundImage: AssetImage(avatarUrl),  // avatarUrl could be https://...
```

`AssetImage` cannot load remote URLs. If `avatar_url` in the DB contains an `https://` URL (e.g., from Google OAuth profile picture), this silently fails or throws an unhandled exception.

**Fix:**
```dart
backgroundImage: avatarUrl.startsWith('http')
    ? NetworkImage(avatarUrl) as ImageProvider
    : AssetImage(avatarUrl),
```

---

### 5b. Logout Snackbar After Route Removal — Potentially on Dismounted Context

**File:** [`main_navigation_screen.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/auth/presentation/screens/main_navigation_screen.dart#L769-L789)

`messenger` is captured before await (correct), but `pushNamedAndRemoveUntil('/login', ...)` removes all routes including the one the `ScaffoldMessenger` was attached to. Showing a snackbar on a removed route's messenger silently fails.

---

### 5c. Search Provider State Not Cleared When Switching Tabs

**File:** [`main_navigation_screen.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/auth/presentation/screens/main_navigation_screen.dart#L689-L693)

The nav bar tap handler clears `skulkFeedSearchProvider` only when `index != 3`. If a user typed a search query in Subjects (index 0), then tapped Skulk, `subjectsSearchProvider` is NOT cleared — only the text controller `_skulkSearchController` is. The visual search box is empty but the filter is still active.

Similarly, `onPageChanged` clears **all four** search providers on every swipe, even if only one was active — meaning a Subjects search is wiped when the user accidentally swipes to Prep Zone.

---

### 5d. `FlyingBeeOverlay` — `Future.delayed` Leaks on Dispose

**File:** [`subjects_page.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/subjects/presentation/screens/subjects_page.dart#L517-L521)

```dart
Future.delayed(const Duration(seconds: 10), () {
  if (!mounted || !widget.beeEnabled) return;
  _spawnBee();
});
```

These `Future.delayed` calls cannot be cancelled. After a hot reload or widget disposal, the Future still fires after 10 seconds, calling `_spawnBee()` on a potentially invalid state reference. The `!mounted` check prevents a crash, but the underlying timer still runs in the background.

**Fix:** Replace with `Timer` instances that can be cancelled in `dispose()`.

---

## 6. Performance Issues

### 6a. `BackdropFilter` on Every Subject Card — GPU Expensive

**File:** [`subjects_page.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/subjects/presentation/screens/subjects_page.dart#L336-L355)

`BackdropFilter.blur(sigmaX: 16, sigmaY: 16)` inside each `ListView.builder` item creates 8–15 separate GPU blur render passes during scroll. This causes jank on mid-range Android devices.

**Fix:** Apply a single blur to the background layer once instead of per-card.

---

### 6b. Wobble `AnimationController` Runs Continuously — Even When Nav Bar Is Off-Screen

**File:** [`main_navigation_screen.dart`](file:///c:/flutter_projects/pyq_mvp/pyq_mvp/lib/features/auth/presentation/screens/main_navigation_screen.dart#L61-L64)

`_wobbleController..repeat(reverse: true)` starts in `initState` and never pauses. When the user is in a detail screen (SubjectDashboard, DoubtDetail, etc.), the bottom nav bar is hidden but the controller still ticks every 900ms, triggering `AnimatedBuilder` rebuilds.

**Fix:** Pause the controller on route push and resume on pop using a `RouteObserver`.

---

## 7. UI/UX Inconsistencies

| Issue | File | Description |
|---|---|---|
| **Mixed route transitions** | `router.dart` | `/todo_dashboard` and `/skulk_whiteboard` use `MaterialPageRoute` (slide-up), all others use `ParallaxPageRoute`. Jarring inconsistency. |
| **"Back" button uses `pushReplacementNamed`** | `subjects_page.dart:76` | Navigates to `/selection` with `pushReplacementNamed`, destroying all tab state. Should use `pushNamedAndRemoveUntil` with intentional stack clearing. |
| **All searches clear on any swipe** | `main_navigation_screen.dart:530-535` | `onPageChanged` clears all 4 search providers simultaneously. A search in Subjects is lost when the user accidentally swipes one page. |
| **`_isSearching` dismisses on swipe** | `main_navigation_screen.dart:530` | Swiping pages sets `_isSearching = false`, collapsing the search bar and dismissing the keyboard mid-interaction. |

---

## Priority Summary

| Priority | Issue |
|---|---|
| 🔴 Critical | Nav blob lag (#1) |
| 🔴 Critical | Avatar `AssetImage` crash on remote URLs (#5a) |
| 🔴 Critical | `firstWhere` without `orElse` crash in ToDo (#3e) |
| 🔴 Critical | Deep link args type mismatch crash (#3d) |
| 🟠 High | `themeModeProvider` not persisted (#2c) |
| 🟠 High | `userProfileProvider` never invalidated (#2b) |
| 🟠 High | Stale Riverpod state after logout (#2a) |
| 🟠 High | `isAutoDispose` on Skulk filter providers resets state (#2d) |
| 🟡 Medium | Double-fetch on startup from microtask (#2f) |
| 🟡 Medium | "My Subjects" filter client-side only (#3f) |
| 🟡 Medium | Unread badge never updates (#3i) |
| 🟡 Medium | Search state inconsistencies (#5c, #7) |
| 🟢 Low | `BackdropFilter` per card perf (#6a) |
| 🟢 Low | Wobble runs off-screen (#6b) |
| 🟢 Low | Bee `Future.delayed` leaks (#5d) |
| 🟢 Low | `SkulkDbService` not injected (#3h) |
| 🟢 Low | Search notifiers expose raw `set state` (#3g) |
