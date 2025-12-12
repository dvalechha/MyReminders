**Title:** Implement Account & Profile, Change Password, and Delete Account Views

**Context:**
You are GitHub Copilot, an expert Flutter/Dart developer. Your task is to implement the "Account & Profile" section within the Settings menu, including the "Change Password" and "Delete Account" functionalities. These implementations should be minimal, functional, and adhere to the specified logic for direct vs. external sign-ups.

**Affected Files (Likely):**
*   `lib/views/settings_view.dart` (to add navigation to AccountProfileView)
*   `lib/views/account_profile_view.dart` (new file)
*   `lib/views/change_password_view.dart` (new file)
*   `lib/views/delete_account_view.dart` (new file)
*   `lib/providers/auth_provider.dart` (to add password update and account deletion methods)
*   `lib/services/logout_service.dart` (if not already present, ensure it handles full logout/state reset)
*   `lib/utils/snackbar.dart` (for user feedback)

**Goal:**
Implement the three specified views with their core UI and a placeholder for their logic, respecting authentication methods for password changes and ensuring robust account deletion.

**Instructions:**

1.  **Update `lib/views/settings_view.dart`:**
    *   Locate the "Account & Profile" `ListTile`.
    *   Modify its `onTap` property to navigate to the new `AccountProfileView` (you'll create this next).
        ```dart
        // Example for onTap
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => AccountProfileView()));
        },
        ```

2.  **Create `lib/views/account_profile_view.dart`:**
    *   Implement a new `StatelessWidget` named `AccountProfileView`.
    *   **UI:**
        *   `Scaffold` with an `AppBar` titled "Account & Profile".
        *   Use a `Consumer` or `Selector` with `AuthProvider` to display the current user's email. If `AuthProvider` doesn't expose `currentUser.email`, ensure it does.
        *   `ListTile` for displaying the user's email:
            ```dart
            ListTile(
              leading: Icon(Icons.email),
              title: Text('Email'),
              subtitle: Text(userEmail ?? 'Not available'), // Replace userEmail with actual data
            ),
            ```
        *   `ListTile` for "Change Password":
            *   Title: "Change Password"
            *   Icon: `Icons.lock`
            *   `onTap` should navigate to `ChangePasswordView`.
        *   `ListTile` for "Delete Account":
            *   Title: "Delete Account"
            *   Icon: `Icons.delete_forever`
            *   `onTap` should navigate to `DeleteAccountView`.

3.  **Create `lib/views/change_password_view.dart`:**
    *   Implement a new `StatefulWidget` named `ChangePasswordView`.
    *   **UI:**
        *   `Scaffold` with an `AppBar` titled "Change Password".
        *   Use `Consumer` or `Selector` with `AuthProvider` to determine if the user is a direct sign-up.
        *   **Conditional Display:**
            *   If user is a direct sign-up:
                *   Two `TextFormField` widgets for "New Password" and "Confirm New Password".
                *   A "Save" `ElevatedButton`.
            *   If not a direct sign-up:
                *   A `Text` widget displaying: "Password changes are managed by your external provider."
    *   **Placeholder Logic:**
        *   For the "Save" button `onPressed`:
            *   Add basic validation (passwords match, not empty).
            *   Call a placeholder method in `AuthProvider` (e.g., `_authProvider.updatePassword(newPassword)`).
            *   Show `Snackbar.showSuccess()` or `Snackbar.showError()`.
            *   Navigate back on success.

4.  **Create `lib/views/delete_account_view.dart`:**
    *   Implement a new `StatefulWidget` named `DeleteAccountView`.
    *   **UI:**
        *   `Scaffold` with an `AppBar` titled "Delete Account".
        *   A `Text` widget with a prominent warning message about irreversible data deletion.
        *   A `CheckboxListTile` for "I understand this action is permanent and cannot be undone."
        *   An `ElevatedButton` for "Confirm Deletion" (initially disabled, enabled when checkbox is ticked).
        *   **Conditional (Optional but recommended):** If it's a direct sign-up, you *could* include a `TextFormField` to re-enter the current password for confirmation (though we decided to simplify and rely on the active session for external, it's a good security measure for direct). For this prompt, let's omit the password re-entry for simplicity, making the checkbox the primary gate.
    *   **Placeholder Logic:**
        *   Manage the checkbox state to enable/disable the "Confirm Deletion" button.
        *   For the "Confirm Deletion" button `onPressed`:
            *   Call a placeholder method in `AuthProvider` (e.g., `_authProvider.deleteAccount()`).
            *   On success:
                *   Call `LogoutService.logout()`.
                *   Show `Snackbar.showSuccess()`.
                *   Navigate to `LoginScreen` or `WelcomeView` (ensure `logout_service` handles this redirection).
            *   On error:
                *   Show `Snackbar.showError()`.

5.  **Update `lib/providers/auth_provider.dart`:**
    *   Add a property or method to expose if the user is a direct sign-up (e.g., `bool get isDirectSignIn => currentUser?.appMetadata?['provider'] == 'email';`).
    *   Add a method `Future<void> updatePassword(String newPassword)` that uses Supabase's `auth.updateUser(password: newPassword)`.
    *   Add a method `Future<void> deleteAccount()` that uses Supabase's `auth.deleteUser()` and handles any client-side data cleanup/state reset via `LogoutService`.

6.  **Ensure `lib/services/logout_service.dart` handles full logout and navigation.**

7.  **Integrate `lib/utils/snackbar.dart` for user feedback.**

**Important Considerations:**
*   Use `Provider` for state management (`AuthProvider`).
*   Handle loading states and errors gracefully (e.g., disable buttons, show progress indicators).
*   Focus on creating the structure and wiring for now; robust error handling, detailed validation messages, and deep integration with Supabase (especially RLS for deletion) can be refined later but the method calls should be present.
*   For navigation, use `Navigator.of(context).push()` for new screens and `Navigator.of(context).pop()` to go back. After account deletion, the navigation should effectively clear the stack and go to the login/welcome screen.
