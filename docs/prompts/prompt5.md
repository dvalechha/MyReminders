# Prompt 5: Appointment Module UI Implementation

**Task**: Connect the selection and completion logic to `AppointmentsListView` and `AppointmentCard`.

**Requirements**:
- **AppointmentCard Updates**:
    - Same selection behavior as TaskCard: `onLongPress` to start selection, `onTap` to toggle.
    - **Visual State**: Use the same blue border and checkmark style for consistency.
    - **Completion**: Add a "Mark Finished" icon or button to the card that calls `provider.toggleCompletion()`.
- **View Update**: Integrate the `SelectionAppBar` into the `AppointmentsListView`.