# Cursor AI Prompt: Unified "Smart Card" List UI Refactor (Cross-Platform)

**Context:**
I need to modernize the UI for three core list screens in my Flutter app: **Tasks**, **Appointments**, and **Subscriptions**. Currently, they are simple text lists. I want to move to a unified **"Soft Card" design system** that works consistently on both iOS and Android.

**Global Design Style:**
* **Background:** Light Grey (e.g., `Colors.grey[100]` or `CupertinoColors.systemGroupedBackground` for iOS) for the screen background.
* **Card Style:** Pure White (`Colors.white`) containers, `BorderRadius.circular(16)`, and a subtle shadow (low opacity, diffuse).
* **Typography:** Use a modern, rounded sans-serif font (e.g., Google Fonts `Poppins` or `Lato`) if available, otherwise standard Platform font. Titles should be **Bold**.

---

## 1. The Reusable "SmartCard" Component
Create a reusable Flutter widget (e.g., `SmartListTile`) that accepts a `child` (content) and a `Color` (status indicator).

**Visual Specs:**
* **Container:** White background, rounded corners (16dp).
* **Status Strip:** A vertical color strip on the absolute left edge of the card. Width: `6dp`.
    * *Border Radius:* Top-left and bottom-left corners should match the card's radius (16dp) so it fits widely.
* **Padding:** Internal padding of `16dp` for the content.
* **Elevation:** `2` or `4` (Subtle).

---

## 2. Screen-Specific Implementations

### A. Task List Screen
* **Data:** Title, Due Date, Priority (High, Medium, Low).
* **Layout inside Card:**
    * **Leading:** A circular Checkbox (Use `MSHCheckbox` or standard Flutter `Checkbox` shaped as circle).
    * **Center:**
        * Row 1: Task Title (Bold, size 16).
        * Row 2: Due Date (Grey, size 12). If date is Today/Overdue, text color should be Red/Orange.
    * **Trailing:** (Optional) Chevron right `Icons.adaptive.arrow_forward`.
* **Logic (Color Coding):**
    * **High Priority / Overdue:** Red Status Strip (`Colors.redAccent`).
    * **Medium Priority:** Orange/Yellow Status Strip (`Colors.orangeAccent`).
    * **Low Priority:** Blue/Green Status Strip (`Colors.blueAccent` or Transparent).

### B. Appointments Screen (Timeline Look)
* **Data:** Title, Date/Time, Location.
* **Layout inside Card:**
    * **Leading:** Instead of a checkbox, use a vertical column showing the **Time** (e.g., "3:00 \n PM") in bold.
    * **Center:**
        * Row 1: Appointment Title (e.g., "Dentist").
        * Row 2: Row with `Icons.location_on` (size 12, grey) + Location Text.
* **Logic (Color Coding):**
    * **Happening Today:** Orange Status Strip.
    * **Future:** Blue Status Strip.

### C. Subscriptions Screen
* **Data:** Name (e.g., Netflix), Cost, Renewal Date, Logo (Asset or Url).
* **Layout inside Card:**
    * **Leading:** A circular Avatar (Radius 24). If no image logo, use a colored CircleAvatar with the first letter of the App Name.
    * **Center:** Subscription Name (Bold) + "Renews in [x] days" (subtitle).
    * **Trailing:** Price (e.g., "$20.00") in **Bold**, aligned right.
    * **Bottom Accessory:** A thin `LinearProgressIndicator` at the very bottom of the card content (inside padding) showing how far through the billing cycle we are.
* **Logic (Color Coding):**
    * **Renews within 3 days:** Red Status Strip (Alert).
    * **Safe:** Green/Blue Status Strip.

---

## 3. Platform Specifics (Crucial)
* **Adaptivity:** Ensure the list scrolls naturally on both platforms (`BouncingScrollPhysics` for iOS, `ClampingScrollPhysics` for Android).
* **Icons:** Use `Icons.adaptive.share` (etc) where possible to show the correct icon for Cupertino vs Material.
* **Feedback:** When tapping a card:
    * **Android:** Use `InkWell` (Ripple effect).
    * **iOS:** Use a `GestureDetector` that lowers opacity slightly on tap (no ripple).

---

## 4. The Logic Strategy (Include in comments)
Please implement the following helper function for color determination to ensure psychological consistence:

```dart
// Traffic Light Mental Model Strategy:
// Red: "Stop/Critical" - Used for High Priority or Overdue items to grab immediate attention.
// Orange: "Caution/Active" - Used for Medium Priority or tasks due Today.
// Blue/Green: "Safe/Flow" - Used for Future items or Low priority.

Color getStatusColor({required Priority priority, required DateTime dueDate}) {
  if (priority == Priority.high || dueDate.isBefore(DateTime.now())) {
    return Colors.redAccent; // Urgent
  } else if (priority == Priority.medium || isSameDay(dueDate, DateTime.now())) {
    return Colors.orangeAccent; // Attention needed
  } else {
    return Colors.blueAccent; // Normal flow
  }
}

Instruction: Please generate the Flutter code for the SmartListTile widget and show an example usage for the Task List ListView.builder incorporating the Search Bar with the new Filter Icon (Icons.tune) on the right side of the search field.