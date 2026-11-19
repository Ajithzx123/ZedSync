import 'enums.dart';
import 'json_utils.dart';

/// One execution or balance operation, kept close to the source record.
class Deal {
  const Deal({
    required this.dealId,
    required this.accountId,
    required this.platformDealId,
    this.platformPositionId,
    required this.kind,
    this.entry,
    this.symbol,
    this.side,
    this.volume,
    this.price,
    required this.profit,
    this.commission = 0,
    this.swap = 0,
    required this.currency,
    required this.executedAt,
  });

  final String dealId;
  final String accountId;
  final String platformDealId;
  final String? platformPositionId;
  final DealKind kind;
  final DealEntry? entry;
  final String? symbol;
  final Side? side;
  final double? volume;
  final double? price;
  final double profit;
  final double commission;
  final double swap;
  final String currency;
  final DateTime executedAt;

  double get net => profit + commission + swap;

  bool get isClosingTrade =>
      kind == DealKind.trade && (entry == DealEntry.out || entry == DealEntry.inout);

  static DealEntry? _entryFromJson(Object? raw) => switch (raw) {
        null => null,
        'IN' => DealEntry.inEntry,
        'OUT' => DealEntry.out,
        'INOUT' => DealEntry.inout,
        _ => throw FormatException('Unknown value for "entry"', raw),
      };

  static String? _entryToJson(DealEntry? e) => switch (e) {
        null => null,
        DealEntry.inEntry => 'IN',
        DealEntry.out => 'OUT',
        DealEntry.inout => 'INOUT',
      };

  factory Deal.fromJson(Map<String, dynamic> json) => Deal(
        dealId: readString(json, 'dealId'),
        accountId: readString(json, 'accountId'),
        platformDealId: readString(json, 'platformDealId'),
        platformPositionId: readStringOrNull(json, 'platformPositionId'),
        kind: readEnum(json, 'kind', DealKind.values),
        entry: _entryFromJson(json['entry']),
        symbol: readStringOrNull(json, 'symbol'),
        side: readEnumOrNull(json, 'side', Side.values),
        volume: readNumOrNull(json, 'volume'),
        price: readNumOrNull(json, 'price'),
        profit: readNum(json, 'profit'),
        commission: readNumOrNull(json, 'commission') ?? 0,
        swap: readNumOrNull(json, 'swap') ?? 0,
        currency: readString(json, 'currency'),
        executedAt: readDate(json, 'executedAt'),
      );

  Map<String, dynamic> toJson() => {
        'dealId': dealId,
        'accountId': accountId,
        'platformDealId': platformDealId,
        'platformPositionId': platformPositionId,
        'kind': enumToJson(kind),
        'entry': _entryToJson(entry),
        'symbol': symbol,
        'side': side == null ? null : enumToJson(side!),
        'volume': volume,
        'price': price,
        'profit': profit,
        'commission': commission,
        'swap': swap,
        'currency': currency,
        'executedAt': executedAt.toIso8601String(),
      };
}
