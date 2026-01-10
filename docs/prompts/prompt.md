# Role: Flutter UI Consistency Expert

**Context:**
The app uses a "Soft Depth" design language (Grey filled inputs, rounded corners, specific Brand Blue).
The "Pop-up" elements (Dialogs, Date Pickers, Bottom Sheets) currently look generic or inconsistent.

**Task:**
Refactor the Styles and Themes to match the main app design.

### 1. Refactor "Custom Reminder" Dialog
* **Target:** The `Dialog` widget where the user enters "Days before renewal".
* **Input Field:**
    * **Remove** the Blue Outline Border.
    * **Apply** the "Soft Fill" style: `filled: true`, `fillColor: Colors.grey[100]`, `border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: 12)`.
    * **Text:** Ensure the cursor and text color match the main form.
* **Save Button:**
    * Make it visually consistent with the main "Save Subscription" button (just smaller).
    * Use `ElevatedButton` with `style: ElevatedButton.styleFrom(backgroundColor: [BrandBlue], shape: RoundedRectangleBorder(borderRadius: 12))`.

### 2. Update App Theme (Global Fixes)
Update the `MaterialApp` theme data to enforce consistency on popups:

* **Date Picker Theme (`datePickerTheme`):**
    * `backgroundColor`: `Colors.white`
    * `headerBackgroundColor`: `Colors.white`
    * `headerForegroundColor`: `Colors.black` (Days/Years text)
    * `dayStyle`: Standard text style.
    * `todayBackgroundColor`: `WidgetStateProperty.all(Colors.transparent)`
    * `todayForegroundColor`: `WidgetStateProperty.all([BrandBlue])`
    * `dayBackgroundColor`: `WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? [BrandBlue] : null)`
    * `shape`: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))` (Softer corners).

* **Popup Menu / Dropdown Theme:**
    * `popupMenuTheme`: `PopupMenuThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), color: Colors.white)`
    * *Note:* This ensures all dropdown lists have nice rounded corners.

### 3. Bottom Sheet Polish ("Reminder Options")
* **Target:** The list showing "None", "1 day before", etc.
* **Shape:** Ensure the top corners are rounded: `shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)))`.
* **Selected Item:** Ensure the checkmark uses the exact `[BrandBlue]` color.

**Action:**
Provide the refactored code for the `CustomReminderDialog` widget and the updated `ThemeData` block.