**Title:** Implement Structured Help & Feedback View for Custos

**Context:**
The current "Help & Feedback" implementation in `lib/views/settings_view.dart` is a placeholder that simply displays `HelpSuggestionView`. We need a comprehensive, professional, and user-friendly `HelpFeedbackView` that educates users on how to use our natural-language assistant and provides clear support channels.

**Goal:**
Create a new view `lib/views/help_feedback_view.dart` and integrate it into the `SettingsView`. This view should be structured into logical sections to improve user onboarding and support.

**Requirements:**

1.  **Section 1: "How to Talk to Custos" (Command Guide):**
    *   Present a "Cheat Sheet" of command patterns the app understands.
    *   Examples: 
        *   Tasks: "Remind me to [Task] on [Date]"
        *   Appointments: "[Event] with [Person] at [Time] at [Location]"
        *   Subscriptions: "New subscription for [Service] $[Amount]/month"
    *   Use a clean, readable layout (e.g., small cards or a bulleted list with icons).

2.  **Section 2: Interactive Examples:**
    *   Group the existing clickable examples from `HelpSuggestionView` into categories (e.g., Tasks, Appointments, Subscriptions).
    *   Ensure clicking an example still triggers the `onExampleTap` callback to navigate back and potentially populate the Omnibox.

3.  **Section 3: Support & Feedback:**
    *   **Report a Bug:** A ListTile that opens an email client via `url_launcher`. The subject should automatically include the app version and OS (use `PackageInfo` and `Platform`).
    *   **Suggest a Feature:** A similar channel for user suggestions.

4.  **Section 4: FAQ (Frequently Asked Questions):**
    *   Add a few expandable tiles (ExpansionTile) or a simple list covering:
        *   "Where is my data stored?" (Explain Supabase/Local encryption).
        *   "Can I use Custos offline?" (Explain local cache).
        *   "How do I sync with external calendars?" (Mention this as a Pro feature).

5.  **Section 5: Community & Growth:**
    *   **Rate Custos:** A button to open the App Store/Play Store page.
    *   **Share App:** A way to share a link to the app with others.

**Technical Instructions:**

1.  **Create `lib/views/help_feedback_view.dart`:**
    *   Implement as a `StatelessWidget` or `StatefulWidget` as needed.
    *   Use a `ListView` for smooth scrolling through sections.
    *   Match the existing app styling (Material 3, consistent padding, and color scheme).
2.  **Update `lib/views/settings_view.dart`:**
    *   Replace the inline `Scaffold` and `HelpSuggestionView` in the "Help & Feedback" `onTap` handler with a navigation to the new `HelpFeedbackView`.
3.  **Dependencies:**
    *   Use `url_launcher` for email and store links.
    *   Use `package_info_plus` for versioning information.
4.  **Exclusions:**
    *   Do **NOT** include legal, version, or license information in this view, as they are already handled in the "About" section.

**Desired Outcome:**
A polished, multi-section Help & Feedback screen that serves as a central hub for user education and support, integrated seamlessly into the existing settings navigation flow.