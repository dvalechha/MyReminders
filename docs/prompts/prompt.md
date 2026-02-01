# Custos Implementation Revert - Date/Time UI

## 1. Add/Edit Subscription Screen (Split Row)
**Goal:** Restore the two-field layout where Date and Time are side-by-side.

> "Act as a Senior Flutter Developer. Refactor the `SubscriptionFormView` to restore the split date-time layout.
> 
> **Layout Requirements:**
> - Inside the 'Timing' card, create a `Row` with two `Expanded` children.
> - Left field: `ModernFormField` with label 'Renewal Date'.
> - Right field: `ModernFormField` with label 'Time'.
> - Style: Labels must be outside and above the `grey[100]` input containers.
> 
> **Interaction Logic:**
> - Tapping 'Renewal Date' must open a Bottom Sheet with a `CupertinoDatePicker` in `date` mode.
> - Tapping the 'Time' field must open a Bottom Sheet with a `CupertinoDatePicker` in `time` mode.
> - Both selections must update the single `renewal_date` DateTime object in the `SubscriptionProvider`.
> 
> **Output:** Complete code for the Subscription form view."

---

## 2. Add/Edit Appointment Screen (Split Row)
**Goal:** Restore the two-field side-by-side layout for appointments.

> "Act as a Senior Flutter Developer. Refactor the `AppointmentFormView` to use the split-field timing layout.
> 
> **Layout Requirements:**
> - Provide a `Row` containing two `Expanded` widgets.
> - Left widget: `ModernFormField` for 'Date' with a calendar icon.
> - Right widget: `ModernFormField` for 'Time' with a clock icon.
> - Container Style: White background, `BorderRadius.circular(12)`, no border stroke.
> 
> **Interaction Logic:**
> - Date field triggers a bottom sheet wheel in `date` mode.
> - Time field triggers a bottom sheet wheel in `time` mode.
> - Ensure both update the `start_time` in the `AppointmentProvider`.
> 
> **Output:** Updated screen code with independent Date and Time triggers."

---

## 3. Add/Edit Task Screen (Unified Field)
**Goal:** Restore the single, full-width field that handles both date and time selection at once.

> "Act as a Senior Flutter Developer. Refactor the `TaskFormView` to use a unified date-time picker.
> 
> **Layout Requirements:**
> - Create one full-width `ModernFormField` labeled 'Due Date & Time'.
> - Use the hint text 'Select date and time'.
> - Style: Use the 'Modern Soft' grey container with labels above.
> 
> **Interaction Logic:**
> - Tapping this field must open a Bottom Sheet containing a `CupertinoDatePicker` set to `dateAndTime` mode.
> - The picker must display the Date wheel and Time wheel side-by-side in one view.
> - Update the `due_date` field in `TaskProvider` upon clicking 'Done'.
> 
> **Output:** Production-ready code for the Task Form."