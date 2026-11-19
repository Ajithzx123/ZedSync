import 'json_utils.dart';

class FxRate {
  const FxRate({required this.base, required this.quote, required this.rate, required this.asOf, required this.source});

  final String base;
  final String quote;
  final double rate;
  final DateTime asOf;
  final String source;

  factory FxRate.fromJson(Map<String, dynamic> json) => FxRate(
        base: readString(json, 'base'),
        quote: readString(json, 'quote'),
        rate: readNum(json, 'rate'),
        asOf: readDate(json, 'asOf'),
        source: readString(json, 'source'),
      );

  Map<String, dynamic> toJson() =>
      {'base': base, 'quote': quote, 'rate': rate, 'asOf': asOf.toIso8601String(), 'source': source};
}

/// Combined portfolio figures, already converted into [baseCurrency].
class PortfolioSummary {
  const PortfolioSummary({
    required this.baseCurrency,
    required this.totalBalance,
    required this.totalEquity,
    required this.floatingPnl,
    required this.realizedPnlToday,
    required this.totalPnlToday,
    required this.openPositions,
    required this.pendingOrders,
    required this.accountsTotal,
    required this.accountsLive,
    required this.staleAccountIds,
    required this.isComplete,
    required this.fxRates,
    required this.asOf,
  });

  final String baseCurrency;
  final double totalBalance;
  final double totalEquity;
  final double floatingPnl;
  final double realizedPnlToday;
  final double totalPnlToday;
  final int openPositions;
  final int pendingOrders;
  final int accountsTotal;
  final int accountsLive;
  final List<String> staleAccountIds;

  /// False when any account is not live: totals include last-known values.
  final bool isComplete;
  final List<FxRate> fxRates;
  final DateTime asOf;

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) => PortfolioSummary(
        baseCurrency: readString(json, 'baseCurrency'),
        totalBalance: readNum(json, 'totalBalance'),
        totalEquity: readNum(json, 'totalEquity'),
        floatingPnl: readNum(json, 'floatingPnl'),
        realizedPnlToday: readNum(json, 'realizedPnlToday'),
        totalPnlToday: readNum(json, 'totalPnlToday'),
        openPositions: readInt(json, 'openPositions'),
        pendingOrders: readInt(json, 'pendingOrders'),
        accountsTotal: readInt(json, 'accountsTotal'),
        accountsLive: readInt(json, 'accountsLive'),
        staleAccountIds: readStringList(json, 'staleAccountIds'),
        isComplete: json['isComplete'] as bool,
        fxRates: (json['fxRates'] as List<dynamic>)
            .map((e) => FxRate.fromJson(e as Map<String, dynamic>))
            .toList(),
        asOf: readDate(json, 'asOf'),
      );

  Map<String, dynamic> toJson() => {
        'baseCurrency': baseCurrency,
        'totalBalance': totalBalance,
        'totalEquity': totalEquity,
        'floatingPnl': floatingPnl,
        'realizedPnlToday': realizedPnlToday,
        'totalPnlToday': totalPnlToday,
        'openPositions': openPositions,
        'pendingOrders': pendingOrders,
        'accountsTotal': accountsTotal,
        'accountsLive': accountsLive,
        'staleAccountIds': staleAccountIds,
        'isComplete': isComplete,
        'fxRates': fxRates.map((r) => r.toJson()).toList(),
        'asOf': asOf.toIso8601String(),
      };
}

class SymbolExposure {
  const SymbolExposure({
    required this.symbol,
    required this.accounts,
    required this.buyVolume,
    required this.sellVolume,
    required this.netVolume,
    required this.floatingPnl,
    required this.positions,
    required this.sameDirectionMultiAccount,
    required this.note,
  });

  final String symbol;
  final int accounts;
  final double buyVolume;
  final double sellVolume;
  final double netVolume;
  final double floatingPnl;
  final int positions;
  final bool sameDirectionMultiAccount;
  final String note;

  factory SymbolExposure.fromJson(Map<String, dynamic> json) => SymbolExposure(
        symbol: readString(json, 'symbol'),
        accounts: readInt(json, 'accounts'),
        buyVolume: readNum(json, 'buyVolume'),
        sellVolume: readNum(json, 'sellVolume'),
        netVolume: readNum(json, 'netVolume'),
        floatingPnl: readNum(json, 'floatingPnl'),
        positions: readInt(json, 'positions'),
        sameDirectionMultiAccount: json['sameDirectionMultiAccount'] as bool,
        note: readString(json, 'note'),
      );

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'accounts': accounts,
        'buyVolume': buyVolume,
        'sellVolume': sellVolume,
        'netVolume': netVolume,
        'floatingPnl': floatingPnl,
        'positions': positions,
        'sameDirectionMultiAccount': sameDirectionMultiAccount,
        'note': note,
      };
}
