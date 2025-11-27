Cursor Prompt – Welcome/Search Updates

  - Update storefront metadata (App Store Connect & Google Play) so the public display name is “Custos”; keep existing bundle/package identifiers untouched.
  - Leave the current login & sign-up flows exactly as they are.
  - Remove the legacy welcome screen that shows category icons; delete any related components/assets/routes.
  - After a successful login, route users to a new Welcome view.
  - Build this Welcome view with a top-aligned omnibox that supports both searching and creating items. Placeholder text: “Ask, schedule, or search…”. Show inline
    parsing chips inside the bar that preview the detected title/date/type; Enter confirms creation, click on chips to edit, and include a subtle mode toggle icon at
    the right (acts as a “+” in create mode). Support shortcuts: Enter=create, Tab=cycle fields, Cmd/Ctrl+K=focus, Esc=clear.
  - Below the bar, add a placeholder visualization (e.g., simple animation, pulsing gradient, or typing indicator) that reacts to input but doesn’t show real results yet; just set up the structure so it’s ready to be replaced later.
  - Ensure the area beneath the bar is ready to be populated based on user input in a future update; comment where the dynamic content will hook in.