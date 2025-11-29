You are an expert Flutter/Dart developer. Your task is to expand the app's natural language capabilities to support viewing existing data and to enhance the initial user experience with actionable examples.

**Starting Point:**
You have an `IntentParserService` that can identify a "create" action and various categories (Appointment, Task, etc.). The main screen can parse input and show a confirmation or a help view. List screens (`AppointmentsListScreen`, `SubscriptionsListScreen`, `TasksListScreen`) already exist but are not yet connected to the main screen's NLP input.

**Instructions:**

1.  **Enhance the `IntentParserService`:**
    *   Introduce a new "show" action. The parser must now be able to differentiate between creating a new item and viewing existing ones.
    *   Update your keyword matching logic to recognize phrases for this new action. For example:
        *   **Action 'show':** `['show me', 'show', 'view', 'do i have', 'what are my', 'list my']`
    *   The service should now be able to parse "Show me my subscriptions" and correctly identify the action as "show" and the category as "subscription".

2.  **Implement Routing Logic on the Main Screen:**
    *   After the user submits text from the `TextField`, the app should analyze the `ParsedIntent` result.
    *   Create a central handler method that takes the `ParsedIntent` and decides what to do next.
    *   Use a `switch` statement or `if/else` logic based on the parsed action and category:
        *   If the action is **"create"**: Keep the current behavior (e.g., show a confirmation card or navigate to a screen to add the new item).
        *   If the action is **"show"**: Use the `Navigator` to push the corresponding list screen.
            *   If category is "appointment", navigate to `AppointmentsListScreen()`.
            *   If category is "subscription", navigate to `SubscriptionsListScreen()`.
            *   If category is "task", navigate to `TasksListScreen()`.
        *   If the intent is not successful (`isSuccess` is false), show the contextual help/suggestion view as before.

3.  **Update the Default Welcome View:**
    *   The default view, which is shown when the app starts and the input field is empty, should be updated to proactively guide the user.
    *   Instead of just an icon, this view should now display a short list of clickable example commands.
    *   These examples should showcase the full range of capabilities, including both "create" and "show" actions.
    *   Just like in the help/suggestion view, when a user taps an example, it must populate the main `TextField` and bring it into focus, preparing it for submission.

**Example Commands for the Welcome View:**
*   "Show me my subscriptions"
*   "Do I have any appointments today?"
*   "Create an appointment for tomorrow at 5pm with Dr. Smith"

Please write clean, well-documented, and production-ready Dart code that seamlessly integrates the existing list screens with the natural language input.