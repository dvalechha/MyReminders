You are updating the Flutter UI to use a consistent 12px corner radius across ALL interactive components
on BOTH iOS and Android.

Apply the following changes across the entire project (or the relevant screen if scoped):

1. Update all InputDecorations, TextFields, DropdownButtons, GestureDetector containers,
   Date pickers, Buttons, Outlined containers, Card-like surfaces, and any custom input widgets
   to use:
      borderRadius: BorderRadius.circular(12)

2. Specifically update:
   - OutlineInputBorder
   - InputDecorationTheme
   - DropdownButtonFormField / DropdownButton
   - Container / DecoratedBox used as form fields
   - ElevatedButtonTheme / OutlinedButtonTheme / TextButtonTheme
   - CupertinoTextField / CupertinoButton (on iOS pathways)
   - Any reusable custom widgets that define their own BoxDecoration

3. Ensure consistency across platforms:
   - Material (Android) widgets → 12px radius
   - Cupertino (iOS) widgets → explicitly override default styles to match 12px
   - Remove or update any leftover 6px or 8px radius references.

4. If the project uses theme-level overrides such as:
      theme.inputDecorationTheme
      theme.cardTheme
      theme.dropdownMenuTheme
   then update those once, and ensure local overrides do NOT conflict.

5. Perform a code-wide search for:
   - BorderRadius.circular(8)
   - BorderRadius.all(Radius.circular(8))
   Replace with:
      BorderRadius.circular(12)

6. After updates, ensure visual consistency:
   - Spacing, padding, and shadows should remain untouched.
   - Do NOT alter colors, typography, layout structure, or padding.

7. Finally, regenerate the screen widgets to confirm the updated 12px radius is applied uniformly.

Now, make all required changes.
