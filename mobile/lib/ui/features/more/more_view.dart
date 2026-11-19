import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/models/deal.dart';
import '../../../domain/models/enums.dart';
import '../../core/format.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../portfolio/portfolio_controller.dart';
import 'history_controller.dart';

class MoreView extends StatelessWidget {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(children: [
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Trading history'),
          subtitle: const Text('Closed deals, deposits and withdrawals'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Get.to(() => const HistoryView()),
        ),
        const ListTile(
          leading: Icon(Icons.notifications_outlined),
          title: Text('Alerts'),
          subtitle: Text('Push notifications arrive in a later release'),
          enabled: false,
        ),
        const Divider(),
        const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 0), child: Text('Settings')),
        Obx(() => ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: const Text('Portfolio currency'),
              trailing: DropdownButton<String>(
                value: settings.baseCurrency.value,
                underline: const SizedBox.shrink(),
                items: [
                  for (final c in SettingsController.currencies) DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => v == null ? null : settings.setBaseCurrency(v),
              ),
            )),
        Obx(() => SwitchListTile(
              secondary: const Icon(Icons.visibility_off_outlined),
              title: const Text('Privacy mode'),
              subtitle: const Text('Hide balances, P&L and account numbers'),
              value: settings.privacyMode.value,
              onChanged: (_) => settings.togglePrivacy(),
            )),
        Obx(() => ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Theme'),
              trailing: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {settings.themeMode.value},
                onSelectionChanged: (s) => settings.setThemeMode(s.first),
              ),
            )),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.lock_outline),
          title: Text('Read-only monitoring'),
          subtitle: Text('ZedSync never opens, closes or modifies trades.'),
        ),
      ]),
    );
  }
}

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final h = Get.find<HistoryController>();
    final portfolio = Get.find<PortfolioController>();
    final settings = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Trading history')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Obx(() => SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('Today')),
                  ButtonSegment(value: 7, label: Text('7 days')),
                  ButtonSegment(value: 30, label: Text('30 days')),
                ],
                selected: {h.days.value},
                onSelectionChanged: (s) => h.setDays(s.first),
              )),
        ),
        Expanded(
          child: Obx(() {
            if (h.isLoading.value && h.deals.isEmpty) return const Center(child: CircularProgressIndicator());
            if (h.error.value != null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: WarningBanner(message: h.error.value!, color: AppColors.loss),
              );
            }
            if (h.deals.isEmpty) return const EmptyState('No activity in this period.');
            final hidden = settings.privacyMode.value;
            return RefreshIndicator(
              onRefresh: h.load,
              child: ListView.separated(
                itemCount: h.deals.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) => _DealTile(
                  deal: h.deals[i],
                  accountName: portfolio.accountById(h.deals[i].accountId)?.accountName ?? h.deals[i].accountId,
                  hidden: hidden,
                ),
              ),
            );
          }),
        ),
      ]),
    );
  }
}

class _DealTile extends StatelessWidget {
  const _DealTile({required this.deal, required this.accountName, required this.hidden});
  final Deal deal;
  final String accountName;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final d = deal;
    final (IconData icon, String title) = switch (d.kind) {
      DealKind.deposit => (Icons.south_west, 'Deposit'),
      DealKind.withdrawal => (Icons.north_east, 'Withdrawal'),
      DealKind.adjustment => (Icons.tune, 'Adjustment'),
      DealKind.trade => (
          d.entry == DealEntry.inEntry ? Icons.login : Icons.logout,
          '${d.symbol} ${d.entry == DealEntry.inEntry ? 'opened' : 'closed'} '
              '${d.volume == null ? '' : Fmt.volume(d.volume!)}'
        ),
    };
    final costs = d.commission + d.swap;
    return ListTile(
      leading: Icon(icon),
      title: Text(title, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          accountName,
          Fmt.dateTime(d.executedAt),
          if (costs != 0) 'costs ${Fmt.money(costs, d.currency, hidden: hidden)}',
        ].join(' · '),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: d.kind == DealKind.trade
          ? PnlText(d.net, d.currency, hidden: hidden)
          : Text(Fmt.money(d.profit, d.currency, hidden: hidden, signed: true),
              style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
