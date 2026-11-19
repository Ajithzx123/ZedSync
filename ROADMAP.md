# ZedSync Trading Hub: Roadmap

Goal: one mobile app showing every MT5, TradeLocker and cTrader account together, read-only, with funded-account risk monitoring.

**First milestone (from the spec):** two real MT5 accounts, with balance, equity, open positions and floating P&L staying in sync on the phone, even when the app is closed.

## 1. Where we are

| Area | Status |
|---|---|
| Backend | FastAPI, GET-only. Mock connector with 6 fictional accounts. Portfolio summary, exposure, accounts, positions, orders, deals. 16 tests. |
| Mobile | Flutter + GetX. Home, Accounts, Positions, Analytics (exposure only), More (history, settings). 10 tests. |
| Rules already enforced | Read-only. Platform values are authoritative. Disconnected accounts stay visible. Stale data shown as stale. No raw cross-currency sums. Source IDs kept. |
| **Not built** | Real broker connections, database, user login, credential storage, push notifications, WebSockets, funded-rule engine, real analytics, live FX rates, hosting. |

Known gaps in what exists: no persistence (state is in memory), no authentication on the API, polling instead of streaming, static FX rates, no widget tests, settings reset on restart.

## 2. Decisions needed from you

These block later phases. Defaults are my recommendation; say "use defaults" and I will proceed.

| # | Decision | Default |
|---|---|---|
| D1 | Who is the first user? | You only, multi-user-ready data model |
| D2 | App sign-in method | Email + password first, Google/Apple later |
| D3 | Where does the backend run? | One Windows VPS for MT5 worker + API together at first; split later |
| D4 | Database hosting | PostgreSQL on the same VPS (managed later) |
| D5 | Push notifications | Firebase project (you create it, I wire it) |
| D6 | Base currency default | USD |
| D7 | Which prop firms/brokers first? | Whatever your real MT5 accounts use (tell me which) |
| D8 | App name / branding | Keep "ZedSync Trading Hub" for now |

## 3. Risks to test before building on them (Phase 2 spike)

These come first because the whole product depends on them. Each is a short experiment, not a feature.

1. **Does your prop firm's MT5 server accept the investor (read-only) password through the Python API?** Some firms restrict this. Test with one real account.
2. **Can several MT5 terminals run side by side on one Windows machine** (one portable install per account), staying logged in for days?
3. **Do the firms' terms allow third-party read-only monitoring?** Check each firm's rules before connecting its accounts.
4. **TradeLocker:** can you get developer API access, and does your prop firm's TradeLocker brand allow it?
5. **cTrader:** can you register an Open API app and complete the OAuth flow with a real account?

If 1 or 2 fails, the MT5 design changes (for example, an Expert Advisor that reports data instead). Better to know in week one.

## 4. Phases

Each phase ends with a milestone you can see working.

### Phase 2: MT5 live (core MVP)
Needs: D1, D3, D4, D7, a Windows machine, one real MT5 account to start.

1. Run the spike above with one real account (investor password only).
2. Add PostgreSQL and migrations. Tables for users, accounts, positions, orders, deals, snapshots, sync status.
3. Credential vault: encrypt investor passwords, never log them, never send them to the app. (Run `/security-review` on this step.)
4. MT5 worker: one isolated terminal per account, read-only, polling every 2 to 5 seconds. Normalizes into the existing models.
5. Connection states and reconnects. After reconnecting, take a fresh snapshot and reconcile open positions. No duplicate open/close events.
6. App sign-in and per-user data. Add-account flow in the app (replace the "Coming in Phase 2" message).
7. Second MT5 account, then test one going offline while the other stays live.

**Done when:** two real MT5 accounts show correct balance, equity, positions and P&L on the phone, and one dropping offline is flagged without affecting the other.

### Phase 3: Alerts and live updates
1. WebSocket stream from backend to app, replacing polling.
2. Push notifications (Firebase): new position, position closed, connection lost, reconnected, stale data.
3. Alert settings in the app: which accounts, quiet hours, thresholds.
4. Closed-trade history from real deals, including partial closes and commissions.

**Done when:** you get a phone notification for a trade opened in MT5 while the app is closed.

### Phase 4: Funded-account rules
1. Per-account rule setup: daily loss limit, max drawdown, profit target, reset time zone, drawdown type (balance, equity, trailing, end-of-day).
2. Rule engine showing inputs, method and last update for each figure. Never a green "safe" indicator on stale data.
3. Safety screen: funded accounts ranked by remaining loss allowance.
4. Warnings at configurable usage (for example 70% of daily loss).

**Done when:** a funded account's daily and overall drawdown match what the prop firm's own dashboard shows, checked on real data.

### Phase 5: TradeLocker
Needs: developer API access (risk 4).
1. Connector for account, positions, orders, history. Stream subscriptions with resubscribe on reconnect.
2. Snapshot and incremental update reconciliation.

**Done when:** MT5 and TradeLocker accounts appear together in one portfolio.

### Phase 6: cTrader
Needs: registered Open API app (risk 5).
1. OAuth with view-only scope, account discovery.
2. Token refresh (about every 30 days) and re-authorization flow.
3. Connector for balances, positions, orders, history.

**Done when:** all three platforms appear in one portfolio.

### Phase 7: Analytics and reports
1. Real FX rates with timestamps, replacing static rates.
2. Win rate, profit factor, average win/loss, drawdown history, equity curve. Calculated from underlying deals, never by averaging per-account figures.
3. Performance by account, instrument, buy vs sell.
4. Daily/weekly/monthly summaries, CSV export. PDF later.

### Phase 8: Production readiness
1. Hosting, TLS, backups, worker health checks and auto-restart.
2. Error tracking (Sentry) and structured logs. Never log credentials or tokens.
3. Security testing, brute-force protection, session and device management, biometric app lock.
4. Stress test with 20 accounts. Check the app stays responsive.
5. Android and iOS release preparation (iOS needs a Mac and an Apple developer account).
6. Acceptance tests from section 11 of the spec, including one that proves the system cannot send trade orders.

## 5. Always-on rules (every phase)

- Read-only. No code path may open, close, modify or cancel trades. Keep the existing tests that enforce this.
- Platform-reported balance and equity are authoritative. Don't recompute them.
- Never hide a disconnected account or show stale data as live.
- Keep original broker IDs and symbols on every record.
- Credentials stay on the server, encrypted. Nothing secret goes in the Flutter app.
- No trade copier and no AI summaries until the underlying numbers are proven correct.

## 6. Who does what

| You | Me |
|---|---|
| Windows VPS or always-on PC | Backend, database, connectors, worker code |
| Real broker/prop-firm accounts for testing | Flutter app and tests |
| Enter investor passwords yourself in the app or secure config | Never handle or store your passwords myself |
| Firebase project, Apple/Google developer accounts | Wire notifications and release builds |
| TradeLocker developer access, cTrader app registration | Connector code once access exists |
| Check each firm's terms on third-party monitoring | Flag where the spec depends on it |

## 7. Next steps, in order

1. You answer D1 to D8 (or say "use defaults").
2. Commit what exists as the initial project.
3. Run `/plan-eng-review` on Phase 2 (architecture, data flow, edge cases) before writing MT5 code.
4. You run the MT5 spike on your Windows machine with one real account. I provide the script.
5. Build Phase 2 in the order listed. Run `/security-review` after the credential vault.

Optional gstack skills along the way: `/office-hours` (is the scope right), `/review` before each merge, `/ship` to open PRs. `/cso` needs Visual Studio Build Tools first.
