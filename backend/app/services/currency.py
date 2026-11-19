"""Currency conversion with timestamped rates.

Phase 1 uses static rates. A live rate provider plugs in behind the same
interface later. Every conversion carries the rate and its timestamp so the
UI can show where a combined number came from.
"""

from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal

from app.models.domain import ApiModel, Money


class FxRate(ApiModel):
    base: str
    quote: str
    rate: Money  # 1 base = rate quote
    as_of: datetime
    source: str


class CurrencyService:
    # Rates against USD: 1 <ccy> = x USD
    _TO_USD = {"USD": Decimal("1"), "EUR": Decimal("1.0831"), "GBP": Decimal("1.2650"), "INR": Decimal("0.01185")}

    def __init__(self) -> None:
        self._as_of = datetime.now(timezone.utc)

    def supported(self) -> list[str]:
        return sorted(self._TO_USD)

    def rate(self, base: str, quote: str) -> FxRate:
        if base not in self._TO_USD or quote not in self._TO_USD:
            raise KeyError(f"No rate for {base}/{quote}")
        r = self._TO_USD[base] / self._TO_USD[quote]
        return FxRate(base=base, quote=quote, rate=r.quantize(Decimal("0.000001")),
                      as_of=self._as_of, source="static-phase1")

    def convert(self, amount: Decimal, base: str, quote: str) -> Decimal:
        if base == quote:
            return amount
        return (amount * self.rate(base, quote).rate).quantize(Decimal("0.01"))
