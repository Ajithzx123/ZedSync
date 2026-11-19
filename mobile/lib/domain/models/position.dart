import 'enums.dart';
import 'json_utils.dart';

class Position {
  const Position({
    required this.positionId,
    required this.accountId,
    required this.platformPositionId,
    required this.symbol,
    required this.originalSymbol,
    required this.side,
    required this.volume,
    required this.entryPrice,
    required this.currentPrice,
    this.stopLoss,
    this.takeProfit,
    required this.floatingPnl,
    this.swap = 0,
    required this.currency,
    required this.openedAt,
  });

  final String positionId;
  final String accountId;
  final String platformPositionId;

  /// Normalized symbol (e.g. XAUUSD), used for cross-account grouping.
  final String symbol;

  /// Symbol exactly as the broker reports it (e.g. XAUUSD.pro).
  final String originalSymbol;
  final Side side;
  final double volume;
  final double entryPrice;
  final double currentPrice;
  final double? stopLoss;
  final double? takeProfit;
  final double floatingPnl;
  final double swap;
  final String currency;
  final DateTime openedAt;

  Duration get age => DateTime.now().toUtc().difference(openedAt);

  factory Position.fromJson(Map<String, dynamic> json) => Position(
        positionId: readString(json, 'positionId'),
        accountId: readString(json, 'accountId'),
        platformPositionId: readString(json, 'platformPositionId'),
        symbol: readString(json, 'symbol'),
        originalSymbol: readString(json, 'originalSymbol'),
        side: readEnum(json, 'side', Side.values),
        volume: readNum(json, 'volume'),
        entryPrice: readNum(json, 'entryPrice'),
        currentPrice: readNum(json, 'currentPrice'),
        stopLoss: readNumOrNull(json, 'stopLoss'),
        takeProfit: readNumOrNull(json, 'takeProfit'),
        floatingPnl: readNum(json, 'floatingPnl'),
        swap: readNumOrNull(json, 'swap') ?? 0,
        currency: readString(json, 'currency'),
        openedAt: readDate(json, 'openedAt'),
      );

  Map<String, dynamic> toJson() => {
        'positionId': positionId,
        'accountId': accountId,
        'platformPositionId': platformPositionId,
        'symbol': symbol,
        'originalSymbol': originalSymbol,
        'side': enumToJson(side),
        'volume': volume,
        'entryPrice': entryPrice,
        'currentPrice': currentPrice,
        'stopLoss': stopLoss,
        'takeProfit': takeProfit,
        'floatingPnl': floatingPnl,
        'swap': swap,
        'currency': currency,
        'openedAt': openedAt.toIso8601String(),
      };
}
