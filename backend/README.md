# Local Oracle API and React integration

Architecture: Vite React -> HTTP GET -> FastAPI -> bounded python-oracledb Thin pool
-> existing Oracle XE 21c XEPDB1 application schema. No Oracle setup or writes are
performed by the API. Existing five entities, views and stored routines are reused.

## Setup (PowerShell)

From the repository root:

```powershell
python -m venv backend/.venv
backend/.venv/Scripts/python.exe -m pip install -r backend/requirements-dev.txt
Copy-Item backend/.env.example backend/.env
```

Edit backend/.env **privately**, replacing DB_PASSWORD. Do not paste the password
into commands/chat/logs. Alternatively supply environment variables privately.
The example DSN is localhost:1521/XEPDB1 and username IIA_EVAL_20261020. No account
is created/reset by this integration. Run from backend so .env loads correctly:

```powershell
cd backend
.venv/Scripts/python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

In a second terminal, from frontend:

```powershell
npm ci
npm run dev -- --host localhost --port 5173 --strictPort
```

Default browser origin is exactly http://localhost:5173. CORS allows only that
origin, GET, and Accept. If using a different local origin, set FRONTEND_ORIGIN
privately in the backend environment. frontend/.env.example documents the optional
VITE_API_BASE_URL (default http://localhost:8000/api). No DB secrets belong there.

## API contract and examples

Interactive schemas, parameter descriptions and examples via Try it out:
http://localhost:8000/docs (OpenAPI JSON: /openapi.json).

| GET endpoint | Meaning / example |
|---|---|
| /api/health | Liveness, {"status":"ok"}; no DB connection required |
| /api/health/db | Readiness SELECT 1; {"status":"ready"} or safe 503 |
| /api/categories | category_id, category_name, nullable description |
| /api/locations | Observed locations only; [{"location":"Bengaluru"}] |
| /api/prices/latest?location=Bengaluru&search=Rice | Product/category/unit/brand/active metadata, latest date/price/source, exact three-month comparison_date/change_pct and up to nine dated history points |
| /api/prices/history?product_id=1&location=Bengaluru&date_from=2026-01-01&date_to=2026-09-01 | Inclusive calendar window, ascending dated price/source observations; most recent 100 by default, max 500 |

Get the actual product_id from latest prices: generated identities need not start
at 1. Latest accepts category_id/product_id (positive), search (max 100), limit
(default 50/max 100), offset (max 10000). Category/location lists cap at 100.
Example observation: {"observed_date":"2026-09-01","price":54.0,"source":"SYNTHETIC ..."}.
Missing baseline returns null change_pct, never zero. Invalid filters/date ranges
return 422; unavailable DB returns safe 503; unexpected errors return safe 500.
Search uses bound INSTR, so SQL metacharacters are literal search text.

Only endpoints used by the existing dashboard are added. Separate product,
analytics, stored report endpoints and placeholder screens are not implemented.
The latest endpoint includes metadata and the existing PL/SQL price-change
function, so separate endpoints would duplicate this UI's requests.

## Frontend behavior

App.jsx no longer contains price/product fixtures. It fetches categories, observed
locations, latest active products and mini-chart histories. City/search/category
changes reload data; category filtering is bound in SQL before pagination and also checked locally.
Search is debounced 200ms; AbortController plus request keys prevent stale display.
Only 50 latest series are shown by this small demo dashboard (6 in each demo city).
Loading, error with Retry, empty and missing-baseline states are explicit. There
are no fake success fallbacks. Icons are presentation-only mappings. Hover a
mini-chart to see its observation date. Trends displays the selected series. Insights ranks three-month changes and groups unweighted category means by matching dates. Calculator provides an explicitly assumed annual compound-cost scenario. Profile stores optional display name and preferred location in this browser only; no authentication or Oracle writes are added.

Data is synthetic demonstration data; not market prices or official weighted CPI.
Dates and units come from Oracle; percentage compares exact calendar endpoints
via FN_PRICE_CHANGE. A nine-observation chart need not represent nine months.

## Tests and verification

```powershell
cd backend
.venv/Scripts/python.exe -m pytest -q
```

From frontend:

```powershell
node --test api.test.js
npm run lint
npm run build
```

Tests inject a fake query layer without Oracle credentials. They cover routes,
validation, SQL bind handling, CORS, missing credentials and safe errors. The
frontend API client tests encoding, error propagation and cancellation.

Manual live check after configuring credentials privately: readiness must return
200; load localhost:5173, switch Bengaluru/Chennai, select Food, search Rice, then
search a nonexistent product. Check dated charts and Network requests. Request
history with reversed dates (422). Stop the backend to check error/Retry, restart
it, and retry. Inspect browser console and server logs privately. Confirm current
DB counts remain 4/6/108/4/1 via existing SQL*Plus verification; never run run_all.sql.

## Security and limitations

API uses only SELECTs, binds, max four connections, timed pool waits, connect/call
timeouts, and a read-only transaction per acquired connection. Cursors/connections
are returned on success/failure; pool closes on shutdown. No procedures that write
data are exposed. Stored function calls only read existing data.

No SELECT-only account was available to configure without new credentials. The
existing owner has write privileges: use only on loopback for this academic demo.
Local CORS and read-only application queries do not make this a secure public
service. Public deployment needs authentication, authorization, a restricted
runtime account, TLS, rate limits and operational configuration separately.
Credentials are never returned by health endpoints. No Thick client is required.

The pool opens lazily, so missing credentials leave liveness/docs operational and
DB routes return 503. If readiness fails, privately check credential configuration,
PDB service availability and object permissions. Do not reset accounts or change
Oracle configuration to bypass failures. Backend execution requires the correct
working directory for .env. A single dashboard response performs bounded history
queries per displayed product; this is suitable for the small demo, not bulk feeds.
