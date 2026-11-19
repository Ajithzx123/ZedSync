# ZedSync Trading Hub

Read-only, multi-account trading monitor: one mobile app showing every MT5, TradeLocker and cTrader account together.

Current state: **Phase 0 + Phase 1**. A FastAPI backend serves a fictional portfolio through a mock connector, and the Flutter app reads it from there. No real broker connections exist yet.

```
backend/   FastAPI · normalized domain models · read-only connector contract · mock connector
mobile/    Flutter (Android/iOS/web) · GetX · Home / Accounts / Positions / Analytics / More
```

## Run

Backend (port 8000):

```powershell
cd backend
python -m venv .venv
.venv\Scripts\pip install -r requirements-dev.txt
.venv\Scripts\python -m uvicorn app.main:app --reload --port 8000
```

API docs: http://localhost:8000/docs

Mobile:

```powershell
cd mobile
flutter run                     # Android emulator reaches the backend on 10.0.2.2:8000
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000   # physical device
```

## Test

```powershell
cd backend; .venv\Scripts\python -m pytest
cd mobile; flutter test
```

`mobile/test/fixtures/api_snapshot.json` is captured from the backend. Regenerate it when the API shape changes.

## Design rules already enforced

- **Read-only.** The API only has GET routes, and the connector contract only has `fetch_*` methods. Tests fail if either changes.
- **Platform values are authoritative.** Balance, equity and floating P&L come from the platform; equity is never derived.
- **No silent gaps.** Disconnected accounts stay visible. Their last-known values are included, and the summary is flagged `isComplete: false`.
- **Freshness.** A `CONNECTED` account with no data for 30s is reported as `DELAYED`.
- **Currency.** Totals are converted to a chosen base currency and report the FX rates used, with timestamps. Mixed-currency groups are never summed raw.
- **Source IDs retained.** Every record keeps its `platform*Id` and the broker's `originalSymbol`.
- **Deals, not invented trades.** Partial closes stay as separate deals, and realized P&L excludes deposits and withdrawals.

## Next: Phase 2 (MT5)

Implement `ReadOnlyConnector` for MT5 on a Windows worker (one terminal instance per account, investor password), then swap it in at `backend/app/core/deps.py`.
