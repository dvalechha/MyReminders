You are updating my Flutter + Supabase app to support a user display name that is shown in the UI instead of the email.

GOAL:
1) On email/password signup, ask the user for a Display Name.
2) On Google signup, use the Google profile name as the Display Name.
3) Store display_name in a user_profile table in Supabase.
4) In the app UI, replace the top-right email text with display_name (fallback to email if needed).
5) Display name is READ-ONLY (no edit profile flow for now).

=========================================
PART 1 — USER_PROFILE TABLE IN SUPABASE
=========================================

Assume Supabase auth.users table remains unchanged, including the email column. We will add a separate user_profile table under the same schema we already use for app data (for example: public or reminders — follow current convention).

Create a SQL definition (and keep it in the existing schema file if we already have one) for a user_profile table:

Columns:
- id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
- email TEXT NOT NULL
- display_name TEXT NOT NULL
- created_at TIMESTAMPTZ NOT NULL DEFAULT now()
- updated_at TIMESTAMPTZ NOT NULL DEFAULT now()

Also:
- Add an index on email.
- Add Row Level Security so users can only see/update their own profile (id = auth.uid()).

We will tolerate email duplication between auth.users.email and user_profile.email. Do NOT try to remove or modify auth.users.email.

=========================================
PART 2 — FLUTTER MODEL AND REPOSITORY
=========================================

Create:
- lib/models/user_profile.dart
- lib/repositories/user_profile_repository.dart

user_profile.dart:
- Dart class UserProfile with:
  - id (String)
  - email (String)
  - displayName (String)
  - createdAt (DateTime)
  - updatedAt (DateTime)
- fromMap(Map<String, dynamic>) and toMap()

user_profile_repository.dart:
- Use Supabase.instance.client.from("user_profile")
- Implement:

  Future<UserProfile?> getById(String id)
  Future<UserProfile?> getByUserId(String userId)  // same as getById for our design
  Future<UserProfile> createProfile({
    required String userId,
    required String email,
    required String displayName,
  })
  Future<UserProfile> upsertProfileForCurrentUser({
    required String email,
    required String displayName,
  })
  Future<UserProfile> getOrCreateForCurrentUser({
    required String email,
    required String displayName,
  })

Use auth.currentUser!.id as userId. Persist and read display_name/email from user_profile.

=========================================
PART 3 — SIGNUP SCREEN: ADD DISPLAY NAME FIELD
=========================================

On the email/password SignupScreen:
- Add a text field: "Display Name"
- Fields now:
  - Display Name
  - Email
  - Password
  - Confirm Password

Validation:
- Display Name cannot be empty.
- Email/password rules remain as before.
- Password and Confirm Password must match.

Signup flow for email/password:
1) Call Supabase auth.signUp(email: email, password: password, emailRedirectTo: ...).
2) On successful signUp, retrieve:
   - user.id
   - user.email
3) Call user_profile_repository.getOrCreateForCurrentUser(
     email: user.email!,
     displayName: <value from Display Name field>
   )

Still show: “Check your email to verify” message. No extra UI needed for profile creation.

=========================================
PART 4 — GOOGLE SIGNUP: AUTO DISPLAY NAME
=========================================

For "Continue with Google" in SignupScreen and LoginScreen:

1) Call:
   auth.signInWithOAuth(Provider.google, redirectTo: "yourapp://login-callback")

2) After successful OAuth, retrieve:
   - final user = Supabase.instance.client.auth.currentUser
   - Read:
     - email = user.email
     - displayName candidate from user.userMetadata:
       - user.userMetadata["full_name"] OR
       - user.userMetadata["name"] OR
       - fallback: user.email without domain part

3) Call user_profile_repository.getOrCreateForCurrentUser(
     email: email!,
     displayName: derivedDisplayName,
   )

No extra screen is shown for Google users to edit display name. It is auto-derived and stored.

=========================================
PART 5 — USING DISPLAY NAME IN THE UI
=========================================

In the main app UI (where currently the email is shown in the top-right):

1) Replace the direct use of auth.currentUser.email with data from user_profile:
   - Load UserProfile (e.g. using a provider or FutureBuilder/StreamBuilder).
   - Show userProfile.displayName in the top-right UI.
   - If user_profile is missing or display_name is null/empty, fallback to showing:
     - user.email (from auth.users) as a last resort.

2) Make sure that once the user logs in:
   - We always call getOrCreateForCurrentUser() at least once so user_profile exists.
   - The top-right display updates automatically when profile is loaded.

=========================================
PART 6 — READ-ONLY DISPLAY NAME
=========================================

For now, treat display_name as read-only:
- Do NOT add any “Edit Profile” or “Change Display Name” UI.
- The only time display_name is set:
  - Email/password signup: input from Display Name field.
  - Google signup/login: derived from Google profile name.

We will extend this later if needed.