# Prompt 3: Create Reusable SelectionAppBar

**Task**: Create a reusable `SelectionAppBar` widget for the "Modern Soft" design system.

**Requirements**:
- **Visuals**: White background, a "Close" icon (X) on the left, a text label in the center (e.g., "2 Selected"), and a Trash icon on the right.
- **Functionality**:
    - The "Close" icon should call `provider.clearSelection()`.
    - The "Trash" icon should call `provider.deleteSelected()`.
- **Style**: Use the Brand Blue (`#2D62ED`) for the selection count text and icons. Use a soft shadow to match the app's depth style.