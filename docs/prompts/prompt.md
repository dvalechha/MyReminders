# Context
I am working on the "MyReminder" Flutter app with a Supabase backend. I need to implement the **Renewal Logic** for subscriptions using a specific "Sticky End-of-Month" heuristic.

**Architecture:**
- **Service:** `lib/services/subscription_service.dart` (Business Logic)
- **Provider:** `lib/providers/subscription_provider.dart` (State Management & DB Calls)
- **Model:** `lib/models/subscription.dart`
- **Database:** Supabase table `subscriptions`

# Task
Implement the `renewSubscription` functionality across the Model, Service, and Provider layers.

## 1. Update Data Model (`lib/models/subscription.dart`)
- Add a nullable boolean field: `final bool isRenewed;`
- Update the constructor to include it (default to `false` if not provided).
- Update `fromJson`: Map the `is_renewed` column from Supabase (handle nulls by defaulting to `false`).
- Update `toJson`: Include `is_renewed` so we can write back to the database.
- Update `copyWith`: Add support for this new field.

## 2. Implement "Sticky End-of-Month" Logic (`lib/services/subscription_service.dart`)
Create a method `calculateNextRenewalDate(DateTime current, Cycle cycle)` that enforces the following rules to prevent date drift:

1.  **Check if "Last Day":** Determine if the `current` date is the **last day** of its specific month (e.g., Jan 31st, Feb 28th).
2.  **If YES (It is the last day):**
    - The *new* date must be the **last valid day** of the *next* month.
    - *Example:* Jan 31 -> Feb 28.
    - *Example:* Feb 28 -> Mar 31.
3.  **If NO (It is not the last day):**
    - Perform a standard date addition (e.g., +1 Month).
    - Ensure you handle standard overflows (e.g., Jan 30 + 1 Month should clamp to Feb 28, not Skip to Mar 2).

## 3. Implement Renewal Action (`lib/providers/subscription_provider.dart`)
Create a `renewSubscription(String id, Subscription currentSubscription)` method:

1.  **Calculate:** Call the service method above to get the `newRenewalDate`.
2.  **Supabase Update:** Update the `subscriptions` table for this `id`:
    - `renewal_date`: Set to `newRenewalDate.toUtc().toIso8601String()` (Strict UTC).
    - `is_renewed`: Set to `true`.
3.  **State Refresh:**
    - Update the local state immediately (Optimistic UI) OR trigger a data fetch to ensure the UI reflects the new Date and the "Renewed" status.

## Deliverables
Please provide the complete updated code for:
1.  `lib/models/subscription.dart`
2.  `lib/services/subscription_service.dart`
3.  `lib/providers/subscription_provider.dart`