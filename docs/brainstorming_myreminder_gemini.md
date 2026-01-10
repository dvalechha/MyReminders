# Project: MyReminder App - Brainstorming & Progress Log

**Goal:** Build a production-grade Flutter application for managing subscriptions with a modern, "Soft Depth" design language.

---

## 1. Design System ("Modern Soft")
We moved away from standard Material Design to a custom, premium aesthetic.

* **Color Palette:**
    * **Background:** `Colors.grey[50]` (Light, airy foundation).
    * **Surface (Cards):** `Colors.white` with `BorderRadius.circular(16-20)`.
    * **Primary Brand:** **Blue** (approx `#2D62ED`). Used for totals, active states, and primary buttons.
    * **Urgency:** **Orange** for "Renewing Soon" or "Today".
    * **Safe:** **Green** for items with ample time remaining.
    * **Text:** Dark Grey (`Colors.grey[900]`) for headings, lighter grey for labels.
* **Shadows & Depth:**
    * We use soft, diffused shadows (`BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: Offset(0, 4))`) to make cards "float" rather than using harsh outlines.
* **Input Style:**
    * **Fields:** Filled `Colors.grey[100]` containers with no visible border strokes.
    * **Labels:** Located **outside and above** the field (bold, small text) for better scannability.
    * **Radius:** `BorderRadius.circular(12)` for inputs.

---

## 2. Core Screens Built

### A. Dashboard (Main Screen)
* **Header:** "Total Monthly Spend" with a large, hero-sized number.
* **Bar Chart Visualization:**
    * **Logic:** Dynamic Y-Axis scaling.
        * If Total < $100, use intervals of 10 or 20.
        * If Total > $100, use intervals of 50 or 100.
    * **Visuals:** Clean grid lines, no overlapping labels, and a visual "Max Height" cap to prevent the bar from looking small.
* **Subscription List:**
    * **Squircle Icons:** Initials on a soft colored background.
    * **Progress Track:** A subtle grey line behind the colored urgency bar (Orange/Green) to indicate time passed vs. time remaining.
    * **Summary Widget:** A compact "Today's Snapshot" card showing tasks due today (with "Today" highlighted in Orange).

### B. Add Subscription Flow
* **Form Layout:** Grouped into white "Cards" (Details, Renewal, Additional Info) rather than a long, flat list.
* **UX Polish:**
    * **Keyboard:** "Next" action jumps to the next text field (skipping dropdowns) to maintain flow.
    * **Capitalization:** Auto-capitalizes sentences for names.
    * **Payment Masking:** Uses `prefixText: 'XXXX-XXXX-XXXX-  '` so users only type the last 4 digits securely.
    * **Popups:** Custom `ThemeData` applied to Date Pickers and Dropdowns to match the Brand Blue and rounded corners, removing default Material styling.

### C. Upcoming Agenda
* **Purpose:** A read-only timeline of upcoming payments.
* **Design:**
    * List of expansive cards showing detailed cost, cycle, and renewal date.
    * **Date formatting:** `MMM d` (e.g., "Jan 10") with "Today" highlighted in Orange.
    * **Consistency:** The "View All" button on the Dashboard links here.

---

## 3. Technical Implementation Details
* **State Management:** (Implied local state/setState for UI iteration, moving toward provider/bloc as needed).
* **Data Models:**
    * `Subscription` object likely contains: `name`, `amount`, `currency`, `renewalDate`, `cycle` (Monthly/Yearly), `reminderSetting`, `notes`, `cardLast4`.
* **Theming:**
    * Global `ThemeData` overrides for `datePickerTheme` and `popupMenuTheme` to ensure consistency across all modals.

---

## 4. Current Status
* **Completed:** Visual Polish, Input UX, Chart Scaling, Navigation Flow (Home <-> Agenda).
* **Pending / Next Up:**
    * **"List Subscription" Feature:** (User is currently brainstorming this).
    * **Edit Flow:** (Planned to reuse Add Subscription UI).
    * **Empty States:** Need designs for 0 data.