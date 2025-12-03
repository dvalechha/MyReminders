# Brainstorm: Personal Assistant App

## Purpose
This document captures ongoing ideas and decisions about the Personal Assistant app so we can pick up the discussion in future sessions.

## MVP Features
1. Central natural-language command input (text/voice) for tasks, reminders, and calendar queries.
2. Unified agenda view combining calendar events, tasks, reminders, and deadlines with quick add/edit.
3. Time-based and location-based reminders with cross-device notifications.
4. Task management basics: priorities, categories/tags, snooze/reschedule options.
5. Integration with at least one mainstream calendar/email provider for data sync.
6. Context-aware suggestions (e.g., prep tasks for upcoming meetings).
7. Persistent conversation history for referencing past instructions.
8. Privacy controls and onboarding that explains data usage.

### MVP Feature 1 Details
1. Single command/search bar acts as the default interaction surface; users never choose categories manually.
2. Deterministic intent parsing (rules/NLU) plus natural date parsers extract title, timing, recurrence, and type (reminder/task/event/query).
3. Assistant shows a filled confirmation card so users only tweak errors instead of completing blank forms.
4. Confirmed entries sync to the internal store and external calendars (Google/Microsoft first; iCloud via CalDAV when feasible).
5. Voice commands: platform speech-to-text (Android SpeechRecognizer, iOS SFSpeechRecognizer) feeds the same parser, with fallbacks when transcription confidence is low.
6. LLM integration is optional; start with deterministic logic and add a model later for edge cases.

### MVP Feature 2 Details
1. **Dynamic Welcome Screen:** The main view will serve as a dynamic dashboard, replacing the static welcome/input screen.
2. **Two States:** The screen will have two context-aware states:
    - **Default State (No Input):** Displays a "Today's Snapshot" widget summarizing critical daily items.
    - **Active State (User Typing):** The snapshot widget fades out and is replaced by the animation/preview box that reflects the user's input in real-time.
3. **"Today's Snapshot" Widget:**
    - This card provides a glanceable summary of the most relevant information for the user's day.
    - It will surface items like "Up Next" (soonest appointment), "Due Today" (critical tasks), and "Renewing Soon" (upcoming subscriptions).
4. **Entry to Full Agenda:** The snapshot widget will be tappable, navigating the user to a full, chronologically sorted "Unified Agenda View" that lists all upcoming items from every category.

## Post-MVP Ideas
1. Multi-step automation workflows and routines.
2. Intelligent recommendations based on user habits (meeting times, focus blocks).
3. Advanced integrations (Slack, project management tools, smart home, finance).
4. Proactive alerts such as travel time estimates or deadline warnings.
5. Voice assistant compatibility with handoff between devices.
6. Shared assistant spaces for households or teams.
7. Insights dashboard with productivity analytics and configurable goals.
8. Plugin/extension ecosystem for third-party capabilities.
