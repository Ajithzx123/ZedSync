import 'dart:async';

import 'package:get/get.dart';

import '../../../data/repositories/portfolio_repository.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/pending_order.dart';
import '../../../domain/models/position.dart';
import '../../../domain/models/trading_account.dart';
import '../../core/settings_controller.dart';

enum AccountFilter {
  all('All'),
  live('Live'),
  demo('Demo'),
  funded('Funded'),
  evaluation('Evaluation'),
  personal('Personal'),
  mt5('MT5'),
  tradelocker('TradeLocker'),
  ctrader('cTrader');

  const AccountFilter(this.label);
  final String label;

  bool matches(TradingAccount a) => switch (this) {
        AccountFilter.all => true,
        AccountFilter.live => a.environment == Environment.live,
        AccountFilter.demo => a.environment == Environment.demo,
        AccountFilter.funded =>
          a.accountType == AccountType.funded || a.accountType == AccountType.instantFunded,
        AccountFilter.evaluation => a.accountType == AccountType.evaluation,
        AccountFilter.personal => a.accountType == AccountType.personal,
        AccountFilter.mt5 => a.platform == Platform.mt5,
        AccountFilter.tradelocker => a.platform == Platform.tradelocker,
        AccountFilter.ctrader => a.platform == Platform.ctrader,
      };
}

/// Shared portfolio state for Home, Accounts and Positions.
///
/// Polls the backend for now; this becomes a WebSocket subscription later
/// without the screens changing.
class PortfolioController extends GetxController {
  PortfolioController({required PortfolioRepository repository, this.pollInterval = const Duration(seconds: 5)})
      : _repo = repository;

  final PortfolioRepository _repo;
  final Duration pollInterval;
  final SettingsController _settings = Get.find();

  final snapshot = Rxn<PortfolioSnapshot>();
  final isLoading = false.obs;
  final error = RxnString();
  final filter = AccountFilter.all.obs;

  Timer? _timer;
  bool _inFlight = false;

  @override
  void onInit() {
    super.onInit();
    refreshNow();
    _timer = Timer.periodic(pollInterval, (_) => refreshNow(silent: true));
    ever(_settings.baseCurrency, (_) => refreshNow());
    ever(filter, (_) => refreshNow());
  }

  void setFilter(AccountFilter f) => filter.value = f;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> refreshNow({bool silent = false}) async {
    if (_inFlight) return;
    _inFlight = true;
    if (!silent) isLoading.value = true;
    try {
      final f = filter.value;
      snapshot.value = await _repo.fetchSnapshot(
        baseCurrency: _settings.baseCurrency.value,
        accountIds: f == AccountFilter.all ? null : allAccounts.where(f.matches).map((a) => a.accountId).toSet(),
      );
      error.value = null;
    } catch (e) {
      // Keep the last snapshot on screen; the UI marks it as stale.
      error.value = e.toString();
    } finally {
      _inFlight = false;
      isLoading.value = false;
    }
  }

  /// True when the app itself could not reach the backend on the last attempt.
  bool get backendUnreachable => error.value != null;

  List<TradingAccount> get allAccounts => snapshot.value?.accounts ?? const [];

  List<TradingAccount> get accounts => allAccounts.where(filter.value.matches).toList();

  Set<String> get _visibleIds => accounts.map((a) => a.accountId).toSet();

  List<Position> get positions =>
      (snapshot.value?.positions ?? const []).where((p) => _visibleIds.contains(p.accountId)).toList();

  List<PendingOrder> get orders =>
      (snapshot.value?.orders ?? const []).where((o) => _visibleIds.contains(o.accountId)).toList();

  TradingAccount? accountById(String id) => allAccounts.firstWhereOrNull((a) => a.accountId == id);

  List<Position> positionsFor(String accountId) =>
      (snapshot.value?.positions ?? const []).where((p) => p.accountId == accountId).toList();

  List<PendingOrder> ordersFor(String accountId) =>
      (snapshot.value?.orders ?? const []).where((o) => o.accountId == accountId).toList();

  List<TradingAccount> get staleAccounts =>
      allAccounts.where((a) => !a.connectionStatus.isLive).toList();
}
