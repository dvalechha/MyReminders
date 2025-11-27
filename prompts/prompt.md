You are an expert Flutter/Dart developer. Your task is to implement a natural language processing (NLP) service to infer user intent from a single sentence.

The service needs to extract three key pieces of information:
1.  **Action:** The user's primary goal (e.g., to create something).
2.  **Category:** The type of item the user is referring to (e.g., an appointment).
3.  **Date & Time:** The specific date and time for the item.

**Instructions:**

1.  **Create a data class** named `ParsedIntent` to hold the extracted information. It should have the following properties:
    *   `String? action`
    *   `String? category`
    *   `DateTime? dateTime`
    *   `String originalText`

2.  **Create a service class** named `IntentParserService`. This class will contain the core parsing logic.

3.  **Implement the parsing method** within `IntentParserService`:
    *   Create a public method: `ParsedIntent parse(String text)`.
    *   **For Date & Time Extraction:** Find a suitable package on `pub.dev` that can parse natural language dates and times from a string (e.g., "Dec 15th at 6pm", "in a month's time on 15th at 6pm"). The `any_date` package is a good candidate. Integrate it to find and parse the date/time from the input text.
    *   **For Action & Category Extraction:** Implement a simple keyword-matching system.
        *   Define lists of keywords. For example:
            *   **Action 'create':** `['create', 'setup', 'add', 'make', 'need', 'set up']`
            *   **Category 'appointment':** `['appointment', 'appt', 'meeting']`
            *   **Category 'reminder':** `['reminder', 'remind me']`
        *   The method should iterate through the input text (ideally after removing the date/time phrase to avoid confusion) and identify which keywords are present to determine the `action` and `category`.

Please write clean, well-documented, and production-ready Dart code, ensuring to handle cases where parts of the intent (like the date or action) cannot be found.
