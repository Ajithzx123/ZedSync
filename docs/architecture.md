# Architecture (as implemented)

Describes what exists in code today (Phase 0 + 1). Planned work is in `ROADMAP.md`, not here. Update this file when structure changes.

## Overview

```
Flutter app (mobile/)  --HTTP GET, polling every 5s-->  FastAPI (backend/)  -->  MockConnector (in-memory, 6 fictional accounts)
```

No database, no authentication, no real broker connections, no WebSockets, no push notifications. State lives in memory and resets on restart.

## Backend (`backend/`)

Python, FastAPI, pydantic v2. Routes are mounted under `/api/v1` (the app calls `/api/v1/...`; `/docs` serves OpenAPI).

| Layer | Path | Role |
|---|---|---|
| App | `app/main.py` | Creates FastAPI app, CORS (GET only, any origin), includes the router. |
| API | `app/api/routes.py` | GET-only routes: `/health`, `/portfolio/summary`, `/portfolio/exposure`, `/accounts`, `/accounts/{id}`, `/positions`, `/orders`, `/history/deals`. |
| Services | `app/services/` | `portfolio.py` (summary, exposure aggregation), `currency.py` (static FX rates, `source="static-phase1"`, timestamped), `freshness.py` (`CONNECTED` older than 30s becomes `DELAYED`). |
| Connectors | `app/connectors/base.py` | `ReadOnlyConnector` ABC: `fetch_accounts`, `fetch_positions`, `fetch_pending_orders`, `fetch_deals(since, until)`. No write methods. |
| | `app/connectors/mock/connector.py` | The only implementation. Fictional data across platforms. |
| Models | `app/models/domain.py` | Normalized models: `TradingAccount`, `Position`, `PendingOrder`, `Deal`, enums (platform, status, side, order type, deal entry/kind). Aliased camelCase JSON. Source IDs (`platform*Id`) and `original_symbol` retained. |
| Wiring | `app/core/deps.py` | `get_connector()` returns `MockConnector`; `get_fx()` returns `CurrencyService`. This is the seam where a real connector would be swapped in. |

Tests: `backend/tests/test_api.py` (pytest). They assert the API has only GET routes, write methods are rejected, the connector contract has no trading methods, disconnected accounts stay in the summary flagged incomplete, FX rates used are reported, realized P&L excludes deposits and withdrawals, partial closes stay separate deals, stale data becomes `DELAYED`, and unknown accounts return 404.

## Mobile (`mobile/`)

Flutter (Android/iOS/web scaffolds present), GetX for state and DI, `http`, `intl`.

| Layer | Path | Role |
|---|---|---|
| Entry / DI | `lib/main.dart`, `lib/app_bindings.dart` | Services -> repositories -> controllers via `Get.put` / `Get.lazyPut`. |
| Data | `lib/data/services/api_client.dart` | HTTP client. Base URL from `--dart-define=API_BASE_URL`, with a platform default (Android emulator uses `10.0.2.2:8000`). |
| | `lib/data/repositories/portfolio_repository.dart` | Wraps the client, returns domain models. |
| Domain | `lib/domain/models/` | Dart models mirroring backend JSON with strict parsing (`json_utils.dart` throws `FormatException` naming the key). |
| UI | `lib/ui/shell.dart` | Bottom-nav shell: Home, Accounts, Positions, Analytics, More. |
| | `lib/ui/features/` | `home`, `accounts` (+ detail), `positions`, `analytics` (exposure only), `more` (history, settings), `portfolio` (shared controller, account card, filter bar). |
| | `lib/ui/core/` | Theme, formatting, shared widgets, `SettingsController` (base currency etc.; not persisted). |

`PortfolioController` holds the shared snapshot, polls every 5s with an in-flight guard, and refetches when the base currency or filter changes.

Tests: `mobile/test/models_test.dart` parses `mobile/test/fixtures/api_snapshot.json` (captured from the backend) and checks enum mapping, bad-payload errors, the incomplete flag and account filters. There are no widget tests.

## Not implemented

Real MT5/TradeLocker/cTrader connectors, database and migrations, user login, credential vault, push notifications, WebSocket streaming, funded-account rule engine, live FX rates, real analytics, settings persistence, hosting. See `ROADMAP.md`.
