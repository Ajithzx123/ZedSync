"""Phase 2A spike: can the MT5 Python API log in with an INVESTOR password?

Throwaway. Not imported by the app. Windows only (MetaTrader5 package).
Read-only: calls initialize/account_info/positions_get/orders_get/history_deals_get only.

Run on the Windows machine that has the (portable) MT5 terminal:

    pip install MetaTrader5          # in a throwaway venv, NOT added to requirements
    python spikes/mt5_probe.py

Inputs come from env vars (MT5_PATH, MT5_SERVER, MT5_LOGIN) or prompts. The investor
password is ALWAYS read with a hidden prompt and never printed, logged or stored.
Output: counts and field names only, no balances or credentials.
"""
from __future__ import annotations

import getpass
import os
import sys
from datetime import datetime, timedelta


def ask(env: str, prompt: str) -> str:
    return os.environ.get(env) or input(f"{prompt}: ").strip()


def main() -> int:
    try:
        import MetaTrader5 as mt5
    except ImportError:
        print("MetaTrader5 package missing or not on Windows. pip install MetaTrader5")
        return 2

    path = ask("MT5_PATH", "Path to terminal64.exe (portable install)")
    server = ask("MT5_SERVER", "Server name (as shown in the terminal)")
    login = int(ask("MT5_LOGIN", "Account login number"))
    password = getpass.getpass("Investor password (hidden): ")

    ok = mt5.initialize(path=path, login=login, password=password, server=server)
    password = ""  # drop our copy immediately
    if not ok:
        print("initialize FAILED, last_error =", mt5.last_error())
        return 1

    try:
        info = mt5.account_info()
        print("login accepted:", info is not None)
        if info is not None:
            print("account_info fields:", sorted(info._asdict().keys()))
            print("trade_allowed (expect False for investor):", info.trade_allowed)
        positions = mt5.positions_get()
        print("positions_get count:", None if positions is None else len(positions))
        if positions:
            print("position fields:", sorted(positions[0]._asdict().keys()))
        orders = mt5.orders_get()
        print("orders_get count:", None if orders is None else len(orders))
        now = datetime.now()
        deals = mt5.history_deals_get(now - timedelta(days=30), now)
        print("history_deals_get (30d) count:", None if deals is None else len(deals))
        if deals:
            print("deal fields:", sorted(deals[0]._asdict().keys()))
        print("last_error:", mt5.last_error())
    finally:
        mt5.shutdown()
    return 0


if __name__ == "__main__":
    sys.exit(main())
