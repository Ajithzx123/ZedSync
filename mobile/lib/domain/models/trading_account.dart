import 'enums.dart';
import 'json_utils.dart';

/// A trading account plus its latest platform-reported snapshot.
///
/// Balance, equity and floating P&L are the platform's own figures; the app
/// never derives equity itself.
class TradingAccount {
  const TradingAccount({
    required this.accountId,
    required this.platform,
    required this.platformAccountId,
    required this.accountName,
    required this.broker,
    this.propFirm,
    this.server,
    required this.accountType,
    required this.environment,
    required this.currency,
    this.tags = const [],
    this.groupId,
    required this.balance,
    required this.equity,
    required this.floatingPnl,
    this.credit = 0,
    required this.margin,
    required this.freeMargin,
    this.marginLevel,
    this.leverage,
    required this.connectionStatus,
    this.statusMessage,
    this.lastSyncedAt,
  });

  final String accountId;
  final Platform platform;
  final String platformAccountId;
  final String accountName;
  final String broker;
  final String? propFirm;
  final String? server;
  final AccountType accountType;
  final Environment environment;
  final String currency;
  final List<String> tags;
  final String? groupId;
  final double balance;
  final double equity;
  final double floatingPnl;
  final double credit;
  final double margin;
  final double freeMargin;
  final double? marginLevel;
  final int? leverage;
  final ConnectionStatus connectionStatus;
  final String? statusMessage;
  final DateTime? lastSyncedAt;

  bool get isDemo => environment == Environment.demo;

  factory TradingAccount.fromJson(Map<String, dynamic> json) => TradingAccount(
        accountId: readString(json, 'accountId'),
        platform: readEnum(json, 'platform', Platform.values),
        platformAccountId: readString(json, 'platformAccountId'),
        accountName: readString(json, 'accountName'),
        broker: readString(json, 'broker'),
        propFirm: readStringOrNull(json, 'propFirm'),
        server: readStringOrNull(json, 'server'),
        accountType: readEnum(json, 'accountType', AccountType.values),
        environment: readEnum(json, 'environment', Environment.values),
        currency: readString(json, 'currency'),
        tags: readStringList(json, 'tags'),
        groupId: readStringOrNull(json, 'groupId'),
        balance: readNum(json, 'balance'),
        equity: readNum(json, 'equity'),
        floatingPnl: readNum(json, 'floatingPnl'),
        credit: readNumOrNull(json, 'credit') ?? 0,
        margin: readNum(json, 'margin'),
        freeMargin: readNum(json, 'freeMargin'),
        marginLevel: readNumOrNull(json, 'marginLevel'),
        leverage: json['leverage'] == null ? null : readInt(json, 'leverage'),
        connectionStatus: readEnum(json, 'connectionStatus', ConnectionStatus.values),
        statusMessage: readStringOrNull(json, 'statusMessage'),
        lastSyncedAt: readDateOrNull(json, 'lastSyncedAt'),
      );

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'platform': enumToJson(platform),
        'platformAccountId': platformAccountId,
        'accountName': accountName,
        'broker': broker,
        'propFirm': propFirm,
        'server': server,
        'accountType': enumToJson(accountType),
        'environment': enumToJson(environment),
        'currency': currency,
        'tags': tags,
        'groupId': groupId,
        'balance': balance,
        'equity': equity,
        'floatingPnl': floatingPnl,
        'credit': credit,
        'margin': margin,
        'freeMargin': freeMargin,
        'marginLevel': marginLevel,
        'leverage': leverage,
        'connectionStatus': enumToJson(connectionStatus),
        'statusMessage': statusMessage,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      };
}
