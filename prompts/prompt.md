**Title:** Implement Delete Functionality in Edit Views for Subscriptions, Tasks, and Appointments

**Context:**
You are an expert Flutter/Dart developer working on a personal assistant application. The application uses Supabase as a backend and the provider package for state management. The goal is to add a delete functionality to the existing "edit" screens for three different categories: Subscriptions, Tasks, and Appointments.

**Affected Files:**
*   **Views (UI):**
    *   `lib/views/subscription_form_view.dart`
    *   `lib/views/task_form_view.dart`
    *   `lib/views/appointment_form_view.dart`
*   **Providers (State Management & Business Logic):**
    *   `lib/providers/subscription_provider.dart`
    *   `lib/providers/task_provider.dart`
    *   `lib/providers/appointment_provider.dart`
*   **Repositories (Data Layer):**
    *   `lib/repositories/subscription_repository.dart`
    *   `lib/repositories/task_repository.dart`
    *   `lib/repositories/appointment_repository.dart`

**Instructions:**

Your task is to implement a consistent delete workflow across the three "edit" views mentioned above.

1.  **Add a Delete Icon to the AppBar:**
    *   In each of the three form/edit views (`..._form_view.dart`), add a delete `IconButton` to the `AppBar`'s `actions`.
    *   This icon should only be visible when editing an existing item (i.e., the view is initialized with an existing model instance), not when creating a new one.

2.  **Implement Confirmation Dialog:**
    *   When the user taps the delete icon, display a confirmation `AlertDialog`.
    *   The dialog should have a title like "Delete [Item Type]?" (e.g., "Delete Subscription?").
    *   It should contain a message asking for confirmation (e.g., "Are you sure you want to delete this subscription? This action cannot be undone.").
    *   It must have two `TextButton` actions: "Cancel" (which dismisses the dialog) and "Delete" (which proceeds with the deletion).

3.  **Create Delete Methods in Providers and Repositories:**
    *   For each module (Subscription, Task, Appointment), implement the full deletion stack:
    *   **Repository:** Create a `delete` method in the corresponding repository (e.g., `Future<void> delete(int id)` in `subscription_repository.dart`). This method should execute the `supabase.from(...).delete().match({'id': id})` command.
    *   **Provider:** Create a corresponding `delete` method in the provider (e.g., `Future<void> deleteSubscription(int id)` in `subscription_provider.dart`). This method will call the repository's `delete` method. It should also handle notifying listeners to update the UI.

4.  **Handle Deletion Logic in the View:**
    *   In the "Delete" button's `onPressed` callback within the `AlertDialog`:
        *   Call the appropriate provider's delete method (e.g., `Provider.of<SubscriptionProvider>(context, listen: false).deleteSubscription(subscription.id)`).
        *   Wrap this call in a `try-catch` block to handle potential errors from the backend.
        *   Show a loading indicator while the deletion is in progress if possible.

5.  **Implement Post-Deletion User Experience:**
    *   **On Success:**
        *   After the `try` block completes successfully, close the confirmation dialog.
        *   Navigate the user back to the previous screen (the list view) using `Navigator.of(context).pop()`.
        *   The corresponding list view (e.g., `SubscriptionsListView`) should automatically reflect the deleted item because the provider will have notified its listeners.
    *   **On Failure:**
        *   In the `catch` block, capture the error.
        *   Close the confirmation dialog.
        *   Display an error message to the user. You can use the existing `showErrorSnackbar` utility from `lib/utils/snackbar.dart`.
        *   The user should remain on the edit view.

**Summary of Desired User Experience:**
1.  User opens the edit screen for a task.
2.  User taps the delete icon in the AppBar.
3.  A confirmation dialog appears.
4.  User taps "Delete".
5.  The app communicates with Supabase to delete the record.
6.  **If successful:** The user is returned to the task list, and the deleted task is gone.
7.  **If it fails:** An error snackbar appears, and the user stays on the edit screen.

Please ensure the implementation is clean, robust, and consistently applied across all three modules (Subscriptions, Tasks, and Appointments).
