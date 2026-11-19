import 'enums.dart';
import 'json_utils.dart';

class PendingOrder {
  const PendingOrder({
    required this.orderId,
    required this.accountId,
    required this.platformOrderId,
    required this.symbol,
    required this.originalSymbol,
    required this.orderType,
    required this.volume,
    required this.entryPrice,
    this.stopLoss,
    this.takeProfit,
    required this.createdAt,
    required this.status,
  });

  final String orderId;
  final String accountId;
  final String platformOrderId;
  final String symbol;
  final String originalSymbol;
  final OrderType orderType;
  final double volume;
  final double entryPrice;
  final double? stopLoss;
  final double? takeProfit;
  final DateTime createdAt;
  final String status;

  factory PendingOrder.fromJson(Map<String, dynamic> json) => PendingOrder(
        orderId: readString(json, 'orderId'),
        accountId: readString(json, 'accountId'),
        platformOrderId: readString(json, 'platformOrderId'),
        symbol: readString(json, 'symbol'),
        originalSymbol: readString(json, 'originalSymbol'),
        orderType: readEnum(json, 'orderType', OrderType.values),
        volume: readNum(json, 'volume'),
        entryPrice: readNum(json, 'entryPrice'),
        stopLoss: readNumOrNull(json, 'stopLoss'),
        takeProfit: readNumOrNull(json, 'takeProfit'),
        createdAt: readDate(json, 'createdAt'),
        status: readString(json, 'status'),
      );

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'accountId': accountId,
        'platformOrderId': platformOrderId,
        'symbol': symbol,
        'originalSymbol': originalSymbol,
        'orderType': enumToJson(orderType),
        'volume': volume,
        'entryPrice': entryPrice,
        'stopLoss': stopLoss,
        'takeProfit': takeProfit,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
      };
}
