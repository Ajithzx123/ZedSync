"""Data freshness rules.

A connector may say an account is CONNECTED, but if we have not received data
within the freshness threshold we downgrade it to DELAYED. The app must never
show a stale value as live.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

from app.models.domain import ConnectionStatus, TradingAccount

DEFAULT_FRESHNESS = timedelta(seconds=30)


def effective_status(account: TradingAccount, now: datetime | None = None,
                     threshold: timedelta = DEFAULT_FRESHNESS) -> ConnectionStatus:
    now = now or datetime.now(timezone.utc)
    if account.connection_status is ConnectionStatus.CONNECTED:
        if account.last_synced_at is None or now - account.last_synced_at > threshold:
            return ConnectionStatus.DELAYED
    return account.connection_status


def is_live(status: ConnectionStatus) -> bool:
    return status is ConnectionStatus.CONNECTED
