# Prompt 4: Task Module UI Implementation

**Task**: Connect the selection and completion logic to the `TasksListView` and `TaskCard`.

**Requirements**:
- **TaskCard Updates**:
    - Wrap the card in a `GestureDetector`.
    - `onLongPress`: Trigger `provider.toggleSelection(id)`.
    - `onTap`: If `isSelectionMode` is active, toggle selection. If not, open task details.
    - **Visual State**: If `isSelected`, show a 2px blue border (`#2D62ED`) and a checkmark overlay.
    - **Completion**: Add a checkbox that calls `provider.toggleCompletion()`. When checked, the task text should have a `TextDecoration.lineThrough`.
- **View Update**: Use `SelectionAppBar` at the top of `TasksListView` whenever `isSelectionMode` is true.