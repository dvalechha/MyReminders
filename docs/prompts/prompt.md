Now that `ModernFormField` and the card styling are established, I need to bring the "Add Task" and "Add Appointment" forms up to the same "Modern Soft" standard.

Please refactor both views to use `ModernFormField` and the Card-based layout.

### 1. Refactor `lib/views/appointment_form_view.dart`
- **Background:** `Colors.grey[50]`
- **Layout:** `SingleChildScrollView` with `padding: 20`.
- **Card 1: Event Details** (White, Rounded 16, Shadow)
  - `Title` (ModernFormField)
  - `Location` (ModernFormField, optional `prefixIcon: Icons.location_on_outlined`)
- **Card 2: Timing** (White, Rounded 16, Shadow)
  - Row with two expanded fields:
    - `Date` (ModernFormField, readOnly, triggers DatePicker)
    - `Time` (ModernFormField, readOnly, triggers TimePicker)
- **Card 3: Notes & Reminders** (White, Rounded 16, Shadow)
  - `Reminders` (Dropdown with modern styling)
  - `Notes` (ModernFormField, maxLines: 3)

### 2. Refactor `lib/views/task_form_view.dart`
- **Background:** `Colors.grey[50]`
- **Layout:** `SingleChildScrollView` with `padding: 20`.
- **Card 1: Task Core**
  - `Title` (ModernFormField)
  - `Priority` (Dropdown - Ensure it matches the visual height of the text fields).
- **Card 2: Execution**
  - `Due Date` (ModernFormField, triggers Picker).
  - `Reminder` (Dropdown).
- **Card 3: Context**
  - `Notes` (ModernFormField, maxLines: 3).

**Constraints:**
- **Consistency:** Use the exact same `ModernFormField` widget created in the previous step.
- **Buttons:** Update the "Save" buttons to match the "Brand Blue" styling (Height 50, Radius 12).
- **Logic:** Preserve all existing controllers and `onTap` logic; strictly update the UI structure.