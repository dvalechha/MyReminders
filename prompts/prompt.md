**Title:** Implement Bottom Navigation Bar with Home and Settings (More) Tabs

**Context:**
The `MyReminder` Flutter application currently uses an `AppNavigationDrawer` for primary navigation. We want to introduce a `BottomNavigationBar` to provide more direct and persistent access to key sections of the app: the main `WelcomeView` and the `SettingsView`.

**Goal:**
Implement a `BottomNavigationBar` at the root level of the authenticated user experience that contains two primary tabs: "Home" and "More". The "Home" tab should display the `WelcomeView`, and the "More" tab should display the `SettingsView`.

**Current Architecture Overview:**
- `main.dart` initializes the app and sets `AuthGate` as the home widget.
- `AuthGate` manages authentication state and navigates to `LoginScreen`, `EmailVerificationView`, `ResetPasswordScreen`, or `WelcomeView` based on the user's status.
- `WelcomeView` is currently the direct entry point for authenticated and verified users.
- `AppNavigationDrawer` is located at `lib/widgets/app_navigation_drawer.dart` and accessed via a hamburger icon, leading to various app sections including Settings.

**Proposed Design Change:**
1.  **Introduce `MainNavigationView`:** A new `StatefulWidget` that will act as the container for the `BottomNavigationBar` and its associated views.
2.  **"Home" Tab:** When selected, this tab will display the `WelcomeView`.
3.  **"More" Tab:** When selected, this tab will display the `SettingsView`. This tab will be the primary entry point for `SettingsView`.
4.  **Persistent Bottom Bar:** The `BottomNavigationBar` will be visible across these main navigation views.

**Affected Files (Likely):**
*   `lib/main.dart` (Potentially, depending on how `AuthGate` is updated)
*   `lib/widgets/auth_gate.dart` (To return the new `MainNavigationView`)
*   A new file: `lib/views/main_navigation_view.dart` (To house the `BottomNavigationBar` and manage view switching)
*   `lib/views/welcome_view.dart` (Will become a child of `MainNavigationView`)
*   `lib/views/settings_view.dart` (Will become a child of `MainNavigationView`)
*   `lib/widgets/app_navigation_drawer.dart` (Will need review and potential adjustments to avoid redundancy with Settings, or to remove Settings if it's now solely in the bottom bar).

**Instructions for the Flutter Expert:**

1.  **Create `MainNavigationView`:**
    *   Create a new `StatefulWidget` named `MainNavigationView` in `lib/views/main_navigation_view.dart`.
    *   This widget should contain a `Scaffold` with a `BottomNavigationBar`.
    *   The `BottomNavigationBar` should have two `BottomNavigationBarItem`s:
        *   One with `Icons.home` and the label "Home" (to show `WelcomeView`).
        *   One with `Icons.more_horiz` (or a suitable alternative like `Icons.menu`) and the label "More" (to show `SettingsView`).
    *   Implement logic within `MainNavigationView` to manage the `_selectedIndex` and switch between `WelcomeView` and `SettingsView` (e.g., using an `IndexedStack` to preserve state).

2.  **Update `AuthGate`:**
    *   Modify `lib/widgets/auth_gate.dart` so that when a user is authenticated and verified, it returns `const MainNavigationView()` instead of `const WelcomeView()`.

3.  **Adjust `AppNavigationDrawer` (Review and potentially modify):**
    *   Review `lib/widgets/app_navigation_drawer.dart`.
    *   Consider removing the "Settings" entry from the `AppNavigationDrawer` if the "More" tab in the `BottomNavigationBar` is now the primary access point for settings. Ensure the `AppNavigationDrawer` continues to function correctly for any remaining navigation items.

4.  **Ensure Proper Navigation:**
    *   Verify that tapping the "Home" tab correctly navigates to `WelcomeView`.
    *   Verify that tapping the "More" tab correctly navigates to `SettingsView`.
    *   Ensure that the native back button functionality behaves as expected within this new navigation structure.

**Desired Outcome:**
The `MyReminder` app will have a functional `BottomNavigationBar` providing direct access to the `WelcomeView` and `SettingsView`. The app's overall navigation flow will be updated to reflect this new primary navigation pattern.