# Refactor Task: Subscription Form Validation Logic

I have updated the requirements for the **Add/Edit Subscription** form based on the reminder settings.

**Context:**
The app allows users to select a **Renewal Date + Time** and a **Reminder Offset** (e.g., None, 1 day before, 3 days before).

**New Validation Logic:**
Please write a validation function called `isNotificationValid` that runs whenever the Date, Time, or Reminder fields change.

**The Rule:**
1. **Calculate Effective Notification Time:**
   * Take the selected `Renewal Date & Time`.
   * Subtract the selected `Reminder Offset` (e.g., -1 day, -3 days).
   * *Note: If "Reminder" is "None", the Effective Time is just the Renewal Date itself.*

2. **Compare vs. Now:**
   * If the `Effective Notification Time` is in the **past** (relative to `new Date()`), return **FALSE**.
   * Otherwise, return **TRUE**.

**Error Handling:**
* If the validation fails, block the "Save" button.
* Display a dynamic error message based on the failure:
   * If Reminder is None: *"Renewal date cannot be in the past."*
   * If Reminder is active: *"The reminder time for this date has already passed. Please choose a later date."*

**Example Scenarios to Handle:**
* Now is Jan 12, 5:00 PM.
* User selects Jan 13, 9:00 AM with "1 Day Before".
* Calculation: Jan 12, 9:00 AM.
* **Result:** Error (Time is in the past).