You are implementing the complete logout system for my Flutter + Supabase app.

GOAL:
When the user taps “Logout”:
1. Clear ALL local cached data
2. Clear all in-memory providers/state
3. Stop any listeners or streams
4. Call Supabase signOut() to destroy the session
5. Briefly show a custom Splash screen
6. Navigate user to LoginScreen via AuthGate

===========================
PART A — LOCAL CACHE CLEAR
===========================

Implement a LocalCacheService that clears:

1. SharedPreferences (if used)
   - remove all keys related to the logged-in user
   - remove cached IDs, last viewed state, filters, etc.

2. Hive boxes or local DBs (if present)
   - subscriptions cache
   - appointments cache
   - tasks cache
   - custom reminders
   - category cache
   - any other local storage
   CLEAR or DELETE these boxes.

3. In-memory app state:
   - Reset all Providers/BLoCs/Riverpod states to initial state
   - Clear models, lists, selected IDs, etc.
   - Export a function clearInMemoryState() to wipe all app-level state

Make all clearing operations asynchronous and await them.

===========================
PART B — SERVER LOGOUT
===========================

After local clearing is complete, call:

await Supabase.instance.client.auth.signOut();

NOTES:
- Do NOT attempt “logout everywhere”
- This must only clear the session on the current device

===========================
PART C — ORDER OF OPERATIONS
===========================

Your logout() function MUST follow this order:

1. stopLiveListeners()
2. await clearInMemoryState()
3. await LocalCacheService.clearAll()
4. await Supabase.instance.client.auth.signOut()
5. Navigate to SplashScreen (for 1 second)
6. Then let AuthGate redirect user to Login

===========================
PART D — HOOK INTO AUTHGATE
===========================

AuthGate should automatically redirect user when:
Supabase.instance.client.auth.onAuthStateChange detects session == null

Do NOT manually push LoginScreen directly in logout().
The routing must pass through AuthGate.

===========================
PART E — PLACEHOLDER SERVICES
===========================

Create these helper files if missing:
- lib/services/local_cache_service.dart
- lib/services/state_reset_service.dart
- lib/services/logout_service.dart

Each service should expose clear() methods that can be awaited.

===========================
PART F — TEST CASES
===========================

Ensure Cursor adds test code for:

1. After logout, no cached reminders exist
2. AuthGate detects null session and redirects
3. Google + email logins both work after logout
4. No residual state from previous user persists