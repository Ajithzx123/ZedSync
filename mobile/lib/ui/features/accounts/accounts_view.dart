import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/models/enums.dart';
import '../../../domain/models/trading_account.dart';
import '../../core/settings_controller.dart';
import '../../core/widgets.dart';
import '../portfolio/portfolio_controller.dart';
import '../portfolio/widgets/account_card.dart';
import '../portfolio/widgets/filter_bar.dart';
import 'account_detail_view.dart';

class AccountsView extends StatefulWidget {
  const AccountsView({super.key});

  @override
  State<AccountsView> createState() => _AccountsViewState();
}

class _AccountsViewState extends State<AccountsView> {
  String _query = '';

  static const _groupOrder = [
    AccountType.funded,
    AccountType.instantFunded,
    AccountType.evaluation,
    AccountType.personal,
    AccountType.other,
  ];

  String _groupName(AccountType t) => switch (t) {
        AccountType.funded => 'Funded accounts',
        AccountType.instantFunded => 'Instant funded',
        AccountType.evaluation => 'Evaluation challenges',
        AccountType.personal => 'Personal accounts',
        AccountType.other => 'Other',
      };

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PortfolioController>();
    final settings = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            tooltip: 'Add account',
            icon: const Icon(Icons.add),
            onPressed: () => Get.snackbar('Coming in Phase 2',
                'Connecting MT5, TradeLocker and cTrader accounts arrives with the platform connectors.',
                snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12)),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search name, broker, number or tag',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        const FilterBar(),
        Expanded(
          child: Obx(() {
            final hidden = settings.privacyMode.value;
            final accounts = c.accounts.where(_matches).toList();
            if (c.snapshot.value == null) return const Center(child: CircularProgressIndicator());
            if (accounts.isEmpty) return const EmptyState('No accounts found.');
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                for (final type in _groupOrder)
                  if (accounts.any((a) => a.accountType == type)) ...[
                    SectionTitle(
                        '${_groupName(type)} (${accounts.where((a) => a.accountType == type).length})'),
                    for (final a in accounts.where((a) => a.accountType == type)) ...[
                      AccountCard(
                        account: a,
                        positionCount: c.positionsFor(a.accountId).length,
                        hidden: hidden,
                        onTap: () => Get.to(() => AccountDetailView(accountId: a.accountId)),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
              ],
            );
          }),
        ),
      ]),
    );
  }

  bool _matches(TradingAccount a) {
    if (_query.isEmpty) return true;
    final hay = [a.accountName, a.broker, a.propFirm ?? '', a.platformAccountId, a.platform.label, ...a.tags]
        .join(' ')
        .toLowerCase();
    return hay.contains(_query);
  }
}
