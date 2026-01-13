**Context:**
I am working on the "Status Label" logic for my subscription tracker cards.
Currently, the system uses "Date-Level" comparison (checking only the Day/Month/Year). If the renewal date is today, it simply displays "Due Today," regardless of the specific time.

**The Bug:**
The UI fails to account for the *time* of the renewal.
* **Example:** If a subscription was due at **2:47 PM** today, and it is currently **2:51 PM** today, the card still says "Due Today."
* **Reality:** It is technically "Overdue."

**The Requirement:**
I need to update the status logic to use **Timestamp-Level** granularity.

**Please provide the JavaScript/TypeScript logic to implement the following rules:**

1.  **Overdue Check:**
    * Compare the full `renewal_date` timestamp against `new Date()` (Current Time).
    * If `renewal_date < now`, the status label must return **"Overdue"** (even if it is the same calendar day).

2.  **Due Today Check:**
    * If `renewal_date > now` AND the calendar day is the same as today, the status label should return **"Due Today"** (implying due later today).

3.  **Future/Upcoming:**
    * If the date is in the future (tomorrow onwards), keep existing logic (e.g., "Renews [Date]" or "Renews Tomorrow").

**Tech Stack:**
* Frontend: [Insert your frontend framework, e.g., React/Next.js]
* Date Library (Optional): [Mention if you use date-fns, moment, or native JS]