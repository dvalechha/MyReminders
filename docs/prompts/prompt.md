I need to refactor the Subscription Card. I want to keep the UI strictly decoupled from the backend logic (Supabase) to ensure future flexibility.

Please implement the following:

### 1. Visuals: "Traffic Light" Indicators
Update the **vertical left-hand bar** color based on due date:
* **Overdue:** Red/Terracotta.
* **Due Today:** Amber/Orange.
* **Safe/Future:** Teal/Green.

### 2. Logic: Provider-Agnostic "Renew" Feature
Implement the "Renew" action using a Service/Repository pattern:

* **2.1 Create a Service Method:**
  * Create (or update) a file named `subscriptionService.js` (or `.ts`).
  * Add a function `renewSubscription(id)` inside it.
  * *Only inside this function* should you put the specific Supabase code: `supabase.from('subscriptions')....`.
  * This function should return a standardized response (e.g., `{ success: true }` or `{ error: ... }`) so the UI doesn't know it's Supabase data.

* **2.2 UI Implementation:**
  * In the Component, import `renewSubscription` from the service file.
  * When the button is clicked, call this service function.
  * **Optimistic UI:** Immediately set `isRenewed = true` and turn the pill **Green**.
  * **Rollback:** If the service returns an error, revert the pill color and flag.