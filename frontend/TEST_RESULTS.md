# Dashboard feature verification

Verified locally on October 20, 2026 against the running React/FastAPI services.
No Oracle objects, users or data were changed by this feature work.

- Frontend Node tests: 7 passed (API encoding/errors/abort; calculator quantity,
  annual compounding, zero/negative rates, invalid and out-of-range input).
- ESLint: passed.
- Production build: passed; advisory remains for a JavaScript chunk over 500 kB.
- Headless Edge at 375x812 using actual Oracle-backed API responses: six comparable
  Insights products, category summaries, Insights Rice -> dated Trends graph,
  calculator 100 x 2 x 1.1^2 = 242, invalid years alert, negative-rate result 180.50,
  profile save/reload and preferred Chennai location, and clear preferences passed.
- Controlled HTTP 503 interception: Insights displays error and Retry successfully
  recovers against the real API after interception is removed.
- Insights/Calculator/Profile had no horizontal overflow at the tested width.
- No uncaught browser page errors.

Profile uses browser-local preferences only, not authentication or Oracle accounts.
Calculator is an assumed-rate scenario, not a forecast. Insights uses synthetic
observations and unweighted, matching-date means, not official weighted CPI.
