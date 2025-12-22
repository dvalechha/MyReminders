**Title:** Implement Secure Token Storage for "Remember Me" Feature

**Context:**
You are an expert Flutter/Dart developer specializing in authentication and secure storage. Your task is to implement the logic for the "Remember Me" checkbox on the login screen. When a user successfully logs in and has checked "Remember Me", their authentication tokens should be securely stored for automatic re-login.

**Goal:**
Modify the login handling logic to save authentication tokens to secure storage (iOS Keychain) when the "Remember Me" checkbox is selected.

**Affected File:**
*   `lib/views/login_screen.dart` (Specifically, the methods that handle user login)

**Assumptions:**
*   The `flutter_secure_storage` package is available and imported.
*   The `AuthProvider` can provide access to the current user's session details, including `accessToken` and `refreshToken`, after a successful login.
*   A mechanism exists (or will be implemented separately) to use these stored tokens for auto-login on app startup (e.g., within `AuthGate`).

**Instructions:**

1.  **Locate Login Handler Methods:**
    *   Find the `_handleEmailPasswordLogin()` and `_handleGoogleLogin()` methods in `lib/views/login_screen.dart`.

2.  **Integrate "Remember Me" Logic:**
    *   Inside both `_handleEmailPasswordLogin()` and `_handleGoogleLogin()`, **after** the line where the `AuthProvider` successfully completes the sign-in (e.g., `await authProvider.signInWithPassword(...)` or `await authProvider.signInWithGoogle()`), add a check for the `_rememberMe` state variable.

3.  **Securely Store Tokens (if `_rememberMe` is true):**
    *   If `_rememberMe` is `true`:
        *   Retrieve the current Supabase session details. This may involve accessing `authProvider.currentSession` or a similar property that holds the active session information.
        *   From the session details, extract the `accessToken`, `refreshToken`, and the user's email.
        *   Call a secure storage function to save these details. For example, you might call a hypothetical `SecureStorageService.saveSessionTokens(email, accessToken, refreshToken)`. (Assume `SecureStorageService` is available or can be conceptually called).

4.  **Handle "Remember Me" is false:**
    *   If `_rememberMe` is `false`, no action should be taken regarding token storage.

5.  **Critical Exclusions:**
    *   **Do NOT implement:** Logic for clearing tokens upon password change.
    *   **Do NOT implement:** Logic for clearing tokens upon account deletion.
    *   **Do NOT implement:** Any UI elements related to token expiration or refresh.
    *   **Do NOT implement:** The auto-login mechanism itself on app startup. Focus *only* on the saving part within the login handlers.

**Desired Outcome:**
When a user logs in, checks "Remember Me", and successfully authenticates, their session tokens will be securely stored. This state will be managed solely within the login completion flow, without affecting other parts of the application's authentication lifecycle in this step.