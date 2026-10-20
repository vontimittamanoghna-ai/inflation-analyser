# Integration verification evidence

Verified on October 20, 2026 on this workstation. This is separate from the
historical Oracle SQL*Plus test evidence in database/oracle/TEST_RESULTS.md.

- Installed backend dependencies in backend/.venv; pip check: no broken requirements.
- Backend pytest: **21 passed**, one upstream Starlette TestClient/httpx deprecation
  warning. Tests use dependency-injected/fake database connections, not Oracle.
- Frontend native Node tests: **3 passed** (encoding, safe failure, abort handling).
- Frontend ESLint: passed.
- Vite production build: passed. One advisory: main bundle exceeds 500 kB (Recharts
  and React included); no build failure.
- Started real Uvicorn on 127.0.0.1:8000 and Vite at localhost:5173.
- HTTP liveness: 200, {"status":"ok"}.
- HTTP DB readiness without credentials: 503 with sanitized database-unavailable
  detail; no credential, DSN, SQL or Oracle error exposed.
- Headless Microsoft Edge/Playwright with actual services: unavailable DB renders
  the visible error state; no uncaught page errors.
- Headless browser with explicitly intercepted test HTTP responses: loading,
  fetched price, missing baseline, city switch, category filter, empty results,
  search and stale-request cancellation passed; no uncaught page errors.
  These intercepted fixtures were used only for testing, never added as an app
  fallback and never presented as live Oracle results.

**Live Oracle connectivity through FastAPI was not verified.** No application
password was available to this session. No password was requested, stored or
reset. No Oracle objects, accounts or data were changed. No SQL setup/seed/test
scripts ran as part of this integration task. Configure backend/.env privately
and follow the manual live verification steps in README.md before claiming an
end-to-end Oracle demonstration.

Existing uncommitted Oracle finalization files were preserved. No commit or push
was made. The frontend has no standalone screen test framework; native client
tests and browser interaction QA cover the newly connected dashboard behavior.
