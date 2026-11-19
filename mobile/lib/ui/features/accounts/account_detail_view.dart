import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format.dart';
import '../../core/settings_controller.dart';
import '../../core/widgets.dart';
import '../portfolio/portfolio_controller.dart';
import '../positions/widgets/position_tiles.dart';

class AccountDetailView extends StatelessWidget {
  const AccountDetailView({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PortfolioController>();
    final settings = Get.find<SettingsController>();

    return Obx(() {
      final a = c.accountById(accountId);
      final hidden = settings.privacyMode.value;
      if (a == null) {
        return Scaffold(appBar: AppBar(), body: const EmptyState('Account not found.'));
      }
      final positions = c.positionsFor(accountId);
      final orders = c.ordersFor(accountId);
      final ccy = a.currency;
      String m(double v) => Fmt.money(v, ccy, hidden: hidden);

      return Scaffold(
        appBar: AppBar(title: Text(a.accountName)),
        body: RefreshIndicator(
          onRefresh: c.refreshNow,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
            Row(children: [
              StatusChip(a.connectionStatus),
              const SizedBox(width: 10),
              Expanded(child: FreshnessLabel(a.lastSyncedAt, prefix: 'Last sync')),
            ]),
            if (!a.connectionStatus.isLive) ...[
              const SizedBox(height: 10),
              WarningBanner(
                message: '${a.statusMessage ?? a.connectionStatus.label}. The values below are the last '
                    'ones received and are not live.',
              ),
            ],
            const SectionTitle('Account'),
            _Section(children: [
              KeyValueRow('Balance', m(a.balance)),
              KeyValueRow('Equity', m(a.equity)),
              KeyValueRow('Floating P&L', '', valueWidget: PnlText(a.floatingPnl, ccy, hidden: hidden)),
              if (a.credit != 0) KeyValueRow('Credit', m(a.credit)),
              KeyValueRow('Used margin', m(a.margin)),
              KeyValueRow('Free margin', m(a.freeMargin)),
              KeyValueRow('Margin level', a.marginLevel == null ? '-' : '${a.marginLevel!.toStringAsFixed(1)}%'),
              KeyValueRow('Leverage', a.leverage == null ? '-' : '1:${a.leverage}'),
              KeyValueRow('Currency', ccy),
            ]),
            SectionTitle('Open positions (${positions.length})'),
            _Section(padding: EdgeInsets.zero, children: [
              if (positions.isEmpty) const EmptyState('No open positions.'),
              for (final p in positions) PositionTile(position: p, account: a, hidden: hidden, showAccount: false),
            ]),
            SectionTitle('Pending orders (${orders.length})'),
            _Section(padding: EdgeInsets.zero, children: [
              if (orders.isEmpty) const EmptyState('No pending orders.'),
              for (final o in orders) OrderTile(order: o, account: a, showAccount: false),
            ]),
            const SectionTitle('Risk'),
            const _Section(children: [
              WarningBanner(
                icon: Icons.rule,
                message: 'Funded account rules (daily loss, max drawdown, profit target) can be configured '
                    'per account in a later release.',
              ),
            ]),
            const SectionTitle('Connection'),
            _Section(children: [
              KeyValueRow('Platform', a.platform.label),
              KeyValueRow('Broker', a.broker),
              if (a.propFirm != null) KeyValueRow('Prop firm', a.propFirm!),
              KeyValueRow('Server', a.server ?? '-'),
              KeyValueRow('Account number', Fmt.accountNumber(a.platformAccountId, hidden: hidden)),
              KeyValueRow('Type', '${a.accountType.label} · ${a.isDemo ? 'Demo' : 'Live'}'),
              KeyValueRow('Access', 'Read-only'),
            ]),
          ]),
        ),
      );
    });
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children, this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8)});
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
      );
}
