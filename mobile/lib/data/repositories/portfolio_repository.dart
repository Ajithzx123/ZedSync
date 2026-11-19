import '../../domain/models/deal.dart';
import '../../domain/models/pending_order.dart';
import '../../domain/models/portfolio.dart';
import '../../domain/models/position.dart';
import '../../domain/models/trading_account.dart';
import '../services/api_client.dart';

/// Everything the main screens need, fetched together so the screens show
/// one consistent moment in time.
class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.summary,
    required this.accounts,
    required this.positions,
    required this.orders,
    required this.exposure,
    required this.fetchedAt,
  });

  final PortfolioSummary summary;
  final List<TradingAccount> accounts;
  final List<Position> positions;
  final List<PendingOrder> orders;
  final List<SymbolExposure> exposure;
  final DateTime fetchedAt;
}

class PortfolioRepository {
  PortfolioRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;
  PortfolioSnapshot? _last;

  /// Last successful snapshot, kept so the UI can show stale values
  /// (clearly marked) when the backend is unreachable.
  PortfolioSnapshot? get last => _last;

  /// [accountIds] limits the summary totals to those accounts (null = all).
  /// Lists are always returned in full; the UI filters them.
  Future<PortfolioSnapshot> fetchSnapshot({required String baseCurrency, Set<String>? accountIds}) async {
    final q = {'base': baseCurrency};
    final results = await Future.wait([
      _api.getObject('/portfolio/summary', {...q, if (accountIds != null) 'account_ids': accountIds.join(',')}),
      _api.getList('/accounts'),
      _api.getList('/positions'),
      _api.getList('/orders'),
      _api.getList('/portfolio/exposure', q),
    ]);
    final snapshot = PortfolioSnapshot(
      summary: PortfolioSummary.fromJson(results[0] as Map<String, dynamic>),
      accounts: (results[1] as List<Map<String, dynamic>>).map(TradingAccount.fromJson).toList(),
      positions: (results[2] as List<Map<String, dynamic>>).map(Position.fromJson).toList(),
      orders: (results[3] as List<Map<String, dynamic>>).map(PendingOrder.fromJson).toList(),
      exposure: (results[4] as List<Map<String, dynamic>>).map(SymbolExposure.fromJson).toList(),
      fetchedAt: DateTime.now().toUtc(),
    );
    _last = snapshot;
    return snapshot;
  }

  Future<List<Deal>> fetchDeals({int days = 7, String? accountId}) async {
    final rows = await _api.getList('/history/deals', {
      'days': '$days',
      'account_id': ?accountId,
    });
    return rows.map(Deal.fromJson).toList();
  }
}
