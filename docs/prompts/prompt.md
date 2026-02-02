# Custos Task List - Gesture Refactor.md

## Task List Screen: Swipe-to-Complete & Checkbox Removal
**Goal:** Replace checkboxes with a Left-to-Right swipe gesture for completion, mirroring the Subscription renewal logic.

> "Act as a Senior Flutter Developer. Refactor the `TaskListView` and `TaskListItem` widgets.
> 
> **Visual Changes:**
> - Remove the `Checkbox` widget from the Task items. The UI should be clean and 'Modern Soft' style.
> - Ensure the task title and priority indicator are clearly visible without the checkbox clutter.
> 
> **Gesture Implementation (The Subscription Model):**
> - Implement a **Left-to-Right swipe gesture** to mark a task as 'Completed'.
> - **Silent Safety/Undo Logic:** When swiped, the task should not disappear immediately. Show a 'Ghost Card' with an 'Undo' button and a 10-second timer (matching the Subscription renewal behavior).
> - Only after the timer expires should the `TaskProvider` update the database (`is_completed = true`).
> 
> **Preserve Existing Logic:**
> - **CRITICAL:** Do NOT break the 'Gmail-style' long-press. Long-pressing a task must still activate the `SelectionProvider` and the `SelectionAppBar` for bulk operations.
> - Tapping an item (not swiping or long-pressing) should still navigate to the Edit screen.
> 
> **Output:** Provide the updated code for `TaskListView` and the logic for the swipe-to-complete 'Ghost Card' state."