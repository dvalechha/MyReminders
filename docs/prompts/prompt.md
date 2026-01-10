# Role: Flutter UI Polish

**Context:**
The "Today's Snapshot" widget on the main screen has a layout issue (truncated text) and needs a color tweak to match the new Agenda screen.

**Task:**
Refine the Main Screen Summary Card.

### 1. Fix Header Truncation
* **Target:** The text button `View Full Agenda`.
* **Change:** Rename it to **"View All"** or **"Agenda"**.
* **Style:** Ensure it is aligned to the right and has enough space so it never truncates (never shows "...").

### 2. Consistency Tweaks
* **Target:** The "Renewing Soon" row.
* **Change:** If the item is due "Today" or "Tomorrow", highlight that specific text part in **Colors.orange** (or your urgency color).
    * *Example:* "NF1 • **Today**" (where "Today" is Orange and Bold).

**Action:**
Update the `TodaySnapshotWidget` code to implement these two visual fixes.