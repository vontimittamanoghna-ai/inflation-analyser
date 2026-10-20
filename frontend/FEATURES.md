# Dashboard screens

All screens retain the existing mobile layout and bottom navigation. Prices are
synthetic Oracle demonstration records, not real market data or official CPI.

- **Trends:** select a goods card, an Insights row, or the Trends tab to view a dated
  chart. Uses the latest nine observations included in the latest-price response.
- **Insights:** fetches up to 100 active series for the Home location independently
  of Home search/category filters. Ranks exact three-calendar-month changes returned
  by Oracle FN_PRICE_CHANGE. Null baselines are excluded and coverage is shown.
  Category means average displayed rounded percentages only when both endpoint
  dates match. They are unweighted local summaries, not stored full-period
  INFLATION_DATA rates or official CPI. Loading/error/empty/retry states are explicit.
- **Calculator:** manual cost, quantity, assumed annual rate, whole years. Optionally
  copies the selected/current displayed product price with its city, date and unit.
  Future cost = price * quantity * (1 + annual rate/100)^years. Default 6% is an
  editable assumption, not derived from historical three-month changes. Bounds:
  positive price <=1e9, positive quantity <=1e6, rate >-100 and <=100, years 1–30.
  Results include current/future total, difference and annual schedule; not a forecast.
- **Profile:** optional display name and preferred observed location persist only
  in localStorage on this browser/device. Saving changes the Home city and clears
  search/category selection. Clearing restores default display preferences.
  Storage failure falls back to session-only settings with an explicit message.
  No account, password collection, authentication or database records are added.

Tests: `npm test`, `npm run lint`, `npm run build`. Browser QA additionally checks
Oracle-backed Insights -> Trends navigation, calculator validation/math, profile
save/reload/clear, unavailable Insights error/retry, and narrow-screen overflow.
No Oracle schema or backend API changes are required for these screens.
