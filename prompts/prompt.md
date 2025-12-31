**Title:** Migrate Remaining Navigation Items to Settings View and Remove AppNavigationDrawer

**Context:**
Following the implementation of the `BottomNavigationBar` with "Home" (`WelcomeView`) and "More" (`SettingsView`) tabs, the `AppNavigationDrawer` currently retains "Help & Feedback" and "Logout" options. To consolidate navigation and simplify the UI, these remaining items should be moved to the `SettingsView`.

**Goal:**
Integrate the "Help & Feedback" and "Logout" functionalities into the `SettingsView`, making the `AppNavigationDrawer` redundant, and then remove the `AppNavigationDrawer` (and thus the hamburger menu) from the application.

**Current Architecture Overview:**
- `MainNavigationView` now hosts the primary `Scaffold` and `BottomNavigationBar`.
- `WelcomeView` and `SettingsView` are children of `MainNavigationView`, displayed based on the selected tab.
- `AppNavigationDrawer` (located at `lib/widgets/app_navigation_drawer.dart`) is still present and contains "Help & Feedback" (which navigates to `HelpSuggestionView`) and "Logout" functionality.

**Proposed Design Change:**
1.  **Enhance `SettingsView`:** Add new UI elements (e.g., `ListTile`s) within `SettingsView` to provide access to "Help & Feedback" and "Logout" functionality.
2.  **Migrate Functionality:** Replicate the navigation to `HelpSuggestionView` and the logout action (likely calling `logoutService.signOut()`) from `AppNavigationDrawer` into the new `SettingsView` elements.
3.  **Remove `AppNavigationDrawer` and Hamburger Menu:** Delete the `lib/widgets/app_navigation_drawer.dart` file and remove any remaining references to it (including the associated hamburger menu icon) in the codebase.

**Affected Files (Likely):**
*   `lib/views/settings_view.dart` (To add new menu items and their actions)
*   `lib/widgets/app_navigation_drawer.dart` (To be removed)
*   `lib/views/welcome_view.dart` (If it contains a reference to the `AppNavigationDrawer` in its `Scaffold`)
*   `lib/main.dart` or `lib/widgets/auth_gate.dart` (Potentially, for any top-level drawer configuration if not already handled by `MainNavigationView`).

**Instructions for the Flutter Expert:**

1.  **Understand `AppNavigationDrawer` Contents:**
    *   Read the file `lib/widgets/app_navigation_drawer.dart` to understand how "Help & Feedback" and "Logout" are implemented, specifically noting their navigation targets and associated actions.
    *   Read `lib/views/welcome_view.dart` to confirm if `AppNavigationDrawer` is referenced there (e.g., as a `drawer` in its `Scaffold`).

2.  **Implement in `SettingsView`:**
    *   Open `lib/views/settings_view.dart`.
    *   **Grouping for Help & Feedback and Logout:**
        *   Create a new section, e.g., using a `Column` with a `Text` title or a `Divider` and `Text`, for "Support". Place a `ListTile` for "Help & Feedback" inside this section, ensuring it navigates to `HelpSuggestionView` (which exists in `lib/widgets/help_suggestion_view.dart`).
        *   Place a `ListTile` or a prominent `ElevatedButton` for "Logout" towards the bottom of the `SettingsView`, typically after "Privacy & Data" and "About" sections. Ensure it triggers the logout process, typically by calling `Provider.of<AuthProvider>(context, listen: false).logoutService.signOut();` or a similar pattern used elsewhere in the app for logging out.
    *   Place these new items logically within the `SettingsView`, perhaps in a new section or alongside existing account management options.

3.  **Remove `AppNavigationDrawer` and Hamburger Menu:**
    *   Once the functionality is migrated, delete the file `lib/widgets/app_navigation_drawer.dart`.
    *   Search the entire project for any remaining references to `AppNavigationDrawer` (and its associated hamburger menu icon) and remove them. This might involve removing a `drawer` property from a `Scaffold` or an import statement.

4.  **Verify Navigation and Functionality:**
    *   Ensure that "Help & Feedback" from `SettingsView` correctly opens the `HelpSuggestionView`.
    *   Ensure that "Logout" from `SettingsView` correctly logs out the user and navigates to the login screen.
    *   Confirm that there are no build errors or runtime crashes related to the removal of `AppNavigationDrawer`.

**Desired Outcome:**
The "Help & Feedback" and "Logout" functionalities will be seamlessly integrated into the `SettingsView`, making them accessible from the "More" tab. The `AppNavigationDrawer` (and its associated hamburger menu) will be completely removed, simplifying the app's overall navigation structure.
---

**Title:** Bottom Navigation: "More" Tab Resets Incorrectly, Navigating to Previous Screen Instead of Root Settings View

**Context:**
The application features a persistent bottom navigation bar with two tabs: "Home" and "More". The "Home" tab navigates to `WelcomeView`, and the "More" tab navigates to `SettingsView`. Each tab uses a nested `Navigator` to maintain its own navigation stack. The `_NestedNavigator` component manages route changes and the visibility of the bottom navigation bar.

Currently, when a user navigates to a screen within the "More" tab's stack (e.g., a form like `SubscriptionFormView` or `TaskFormView`), and then taps the "More" tab again on the bottom navigation bar, the navigation behavior is incorrect. Instead of resetting the navigator to its root screen (`SettingsView`), it navigates back to the last *non-form* screen visited within that tab's stack (e.g., `SubscriptionsListView` or `TasksListView`).

**Bug Scenario:**
1.  Navigate to `SubscriptionsListView` (via "More" tab).
2.  Tap to add a new subscription, navigating to `SubscriptionFormView`.
3.  While on `SubscriptionFormView`, tap the "More" tab on the bottom navigation bar.
4.  **Actual Behavior:** The user is taken back to `SubscriptionsListView`.
5.  **Expected Behavior:** The user should be taken to the root `SettingsView`.

The same behavior is observed when navigating from `TasksListView` to `TaskFormView` and then tapping "More" again.

**Goal:**
Modify the navigation logic within `MainNavigationView` and its associated `_NestedNavigator` or `_BottomBarRouteObserver` to ensure that tapping the "More" tab always navigates to the `SettingsView` as its root. If the "More" tab is already selected and the user taps it again, the navigator for that tab should reset to its initial route (`SettingsView`).

**Affected Files:**
*   `lib/views/main_navigation_view.dart` (Specifically, `_MainNavigationViewState._onItemTapped` and the `_NestedNavigator` and `_BottomBarRouteObserver` classes).

**Proposed Solution Approach:**
The `_onItemTapped` method in `_MainNavigationViewState` currently handles resetting the navigator when the same tab is tapped twice by calling `popUntil((route) => route.isFirst)`. This seems to be the correct mechanism.

The issue might stem from how `_BottomBarRouteObserver` or `_NestedNavigator`'s `_handleRouteChange` logic interacts with the navigation stack when a tab is re-selected, or perhaps how routes are being named or managed. The `_handleRouteChange` function hides the bottom bar for form views. It's possible that when the "More" tab is tapped again, the navigator state is not being fully reset to `SettingsView`, and the `_handleRouteChange` function is subsequently called with a route that causes it to believe it should show the previous non-form view.

**Instructions for the Flutter Expert:**

1.  **Analyze `_onItemTapped`:** Review the `_onItemTapped` method in `_MainNavigationViewState` to confirm that the logic for resetting the navigator (`popUntil((route) => route.isFirst)`) is correctly applied for the "More" tab.
2.  **Examine `_NestedNavigator` and `_BottomBarRouteObserver`:**
    *   Inspect `_NestedNavigatorState._handleRouteChange` to understand how route changes and the bottom bar visibility are managed. Pay close attention to the conditions under which the bottom bar is hidden (`shouldHide`).
    *   Examine `_BottomBarRouteObserver` to see how route push, pop, replace, and remove events are handled and if they correctly signal state changes to `_handleRouteChange`.
3.  **Identify Navigation State Management:** Determine why tapping the "More" tab does not consistently lead to `SettingsView` when the user is on a sub-route within the "More" tab's navigator. The goal is to ensure that `MainNavigationKeys.settingsNavigatorKey.currentState?.popUntil((route) => route.isFirst);` reliably brings the user back to `SettingsView`.
4.  **Potential Fixes to Consider:**
    *   Ensure that the `onGenerateRoute` within `_NestedNavigator` correctly maps the initial route for the "More" tab to `SettingsView`.
    *   Verify that route names are consistent and that `_handleRouteChange` does not inadvertently interfere with the tab reset logic. For instance, ensure that form routes are handled correctly when the tab is re-selected.
    *   Consider if there's a need to explicitly push `SettingsView` if the current route within the `settingsNavigatorKey` is not `SettingsView` itself, after confirming the tab is selected.
5.  **Test Scenarios:**
    *   Verify that tapping "Home" always returns to `WelcomeView`.
    *   Verify that tapping "More" always returns to `SettingsView`.
    *   Verify that if already on `SettingsView`, tapping "More" again does not change the view.
    *   Verify that navigating to a form (e.g., `SubscriptionFormView`) and then tapping "More" correctly shows `SettingsView`.
    *   Ensure that the bottom bar visibility logic in `_handleRouteChange` still functions correctly for form views.

**Desired Outcome:**
Tapping the "More" tab on the bottom navigation bar will consistently navigate the user to the root `SettingsView`, regardless of their current position within the "More" tab's navigation stack. Re-tapping the "More" tab will reset the navigator to `SettingsView`.