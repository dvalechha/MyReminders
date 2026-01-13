I need to refactor the `SubscriptionCard` widget to implement specific visual polish and interaction logic.

**Context:**
This card displays subscription details. We are refining the "Overdue/Renew" experience.

Please implement the following changes:

### 1. Layout & Visual Polish
* **Remove Bottom Line:** Remove the red progress/divider line from the bottom of the card. The Left Vertical Bar is sufficient for status indication.
* **Safety Layout (Left Side):** Wrap the Left Column (Name, Cycle, Due Date) inside an `Expanded` widget. This is critical to prevent the text from pushing the Right Side Action Zone off-screen on small devices.
* **Alignment:** Ensure the "Due Today/Overdue" text (Left Side) aligns visually with the bottom of the "Renew" button (Right Side).
* **Right Side Stack:** Ensure the Price and Renew Button are in a `Column` aligned to `CrossAxisAlignment.end` (Price on top, Button below).

### 2. Status Logic (UTC Check)
Determine the status label based on **UTC Date** comparison (ignore time):
* **Logic:** Compare `renewalDate` (in UTC) vs `DateTime.now()` (in UTC). Strip the time components to compare dates only.
* **Labels:**
    * **"Overdue"**: If the renewal date is strictly *before* today (UTC).
    * **"Due today"**: If the renewal date is *equal* to today (UTC).

### 3. The "Renew" Button State Strategy
Implement a local state (e.g., `bool _isPaid`) to handle the "Renew" interaction.

**State A: Idle (Action Required)**
* **Condition:** `!_isPaid`
* **Background:** Light Red (`Colors.red.shade50`)
* **Text/Icon Color:** Dark Red (`Colors.red.shade900`)
* **Text:** "Renew"
* **Icon:** `Icons.check_circle_outline` (Hollow)
* **Action:** On tap, set `_isPaid = true` and trigger the success logic.

**State B: Success (Just Clicked)**
* **Condition:** `_isPaid`
* **Background:** Light Green (`Colors.green.shade50`)
* **Text/Icon Color:** Dark Green (`Colors.green.shade900`)
* **Text:** "Paid!"
* **Icon:** `Icons.check_circle` (Solid/Filled)
* **Action:** Disable tap. (Note: For now, just show this visual state; we will connect the DB logic later).

Please generate the full `build` method for the `SubscriptionCard` widget incorporating these requirements.