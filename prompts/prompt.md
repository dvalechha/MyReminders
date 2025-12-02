You are an expert Flutter/Dart developer. Your task is to implement an "Adaptive Layout" on the main input screen to solve a common mobile UI problem: the on-screen keyboard hiding important content.

**Goal:**
The UI must dynamically adjust when the keyboard appears, ensuring the text input field and the animation/preview box are always visible.

**Starting Point:**
The main screen has a `TextField` at the top, a large animation box below it, and a list of "Try these..." suggestions. Currently, the keyboard covers the animation box and suggestions when active.

**Instructions:**

1.  **Make the Layout Scrollable and Keyboard-Aware:**
    *   Wrap the main screen's body (everything below the `TextField`) in a `SingleChildScrollView`. This will prevent rendering overflow errors when the keyboard resizes the view.
    *   In your `StatefulWidget`, determine if the keyboard is visible. A reliable way to do this is to check if `MediaQuery.of(context).viewInsets.bottom > 0`.

2.  **Implement the Adaptive Animation/Preview Box:**
    *   The animation box should now be an `AnimatedContainer`.
    *   Its `height` property should be dynamic. When the keyboard is hidden, it should have a large, default height (e.g., `200.0`). When the keyboard is visible, it should shrink to a smaller, compact height (e.g., `100.0`).
    *   Set a `duration` for the `AnimatedContainer` (e.g., `Duration(milliseconds: 250)`) to ensure the size change is smoothly animated.
    *   The text currently being typed in the `TextField` should be displayed in real-time inside this animation box. Listen to the `TextEditingController` to update the text.

3.  **Conditionally Hide Non-Essential Elements:**
    *   The "Try these..." suggestions list is only needed when the user hasn't started typing.
    *   Wrap the suggestions list in a widget that can show/hide it based on keyboard visibility. An `AnimatedOpacity` widget is perfect for this.
    *   When the keyboard is visible, the opacity should be `0.0` (hidden).
    *   When the keyboard is hidden, the opacity should be `1.0` (visible).
    *   To prevent the hidden widget from taking up space and blocking gestures, you can also wrap it in an `IgnorePointer` or `Visibility` widget that is also controlled by the keyboard's visibility state.

**Summary of the Desired User Experience:**
*   **Initial State (Keyboard Hidden):** The screen shows the input field, the large animation box, and the "Try these..." suggestions.
*   **User Taps `TextField` (Keyboard Appears):**
    *   The "Try these..." suggestions list smoothly fades out.
    *   The animation box smoothly animates to its smaller, compact height.
    *   The layout adjusts, and the user can clearly see the input field, the compact preview box (reflecting their text), and the keyboard.

Please write clean, well-documented, and production-ready Dart code that creates this polished, adaptive user interface.