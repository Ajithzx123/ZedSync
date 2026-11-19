import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/models/portfolio.dart';
import '../../core/format.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../accounts/account_detail_view.dart';
import '../portfolio/portfolio_controller.dart';
import '../portfolio/widgets/account_card.dart';
import '../portfolio/widgets/filter_bar.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.onOpenPositions});

  /// Switches the shell to the Positions tab.
  final VoidCallback onOpenPositions;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PortfolioController>();
    final settings = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trading Hub'),
        actions: [
          Obx(() => IconButton(
                tooltip: settings.privacyMode.value ? 'Show values' : 'Hide values',
                icon: Icon(settings.privacyMode.value ? Icons.visibility_off : Icons.visibility),
                onPressed: settings.togglePrivacy,
              )),
          Obx(() => IconButton(
                tooltip: 'Refresh',
                onPressed: c.isLoading.value ? null : c.refreshNow,
                icon: c.isLoading.value
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
              )),
        ],
      ),
      body: Obx(() {
        final snap = c.snapshot.value;
        final hidden = settings.privacyMode.value;
        if (snap == null) {
          return Center(
            child: c.error.value != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: WarningBanner(
                      message: 'Cannot reach the ZedSync server.\n${c.error.value}',
                      icon: Icons.cloud_off,
                      color: AppColors.loss,
                    ),
                  )
                : const CircularProgressIndicator(),
          );
        }
        final accounts = c.accounts;
        return RefreshIndicator(
          onRefresh: c.refreshNow,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SizedBox(height: 4),
              const FilterBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (c.backendUnreachable) ...[
                    WarningBanner(
                      icon: Icons.cloud_off,
                      color: AppColors.loss,
                      message: 'Server unreachable. Everything below is from ${Fmt.ago(snap.fetchedAt)} '
                          'and may be out of date.',
                    ),
                    const SizedBox(height: 10),
                  ],
                  _PortfolioHeader(
                    summary: snap.summary,
                    hidden: hidden,
                    onTapPositions: onOpenPositions,
                    stale: c.backendUnreachable,
                  ),
                  if (!snap.summary.isComplete) ...[
                    const SizedBox(height: 10),
                    WarningBanner(
                      message: '${snap.summary.staleAccountIds.length} of ${snap.summary.accountsTotal} '
                          'accounts are not live. Totals include their last known values, so they may be '
                          'incomplete.',
                    ),
                  ],
                  SectionTitle('Accounts (${accounts.length})'),
                  if (accounts.isEmpty) const EmptyState('No accounts match this filter.'),
                  for (final a in accounts) ...[
                    AccountCard(
                      account: a,
                      positionCount: c.positionsFor(a.accountId).length,
                      hidden: hidden,
                      onTap: () => Get.to(() => AccountDetailView(accountId: a.accountId)),
                    ),
                    const SizedBox(height: 10),
                  ],
                ]),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _PortfolioHeader extends StatelessWidget {
  const _PortfolioHeader({
    required this.summary,
    required this.hidden,
    required this.onTapPositions,
    required this.stale,
  });

  final PortfolioSummary summary;
  final bool hidden;
  final bool stale;
  final VoidCallback onTapPositions;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final ccy = s.baseCurrency;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: scheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Combined floating P&L', style: theme.textTheme.labelLarge)),
            if (!stale) const _LiveDot(),
          ]),
          const SizedBox(height: 4),
          InkWell(
            onTap: onTapPositions,
            child: PnlText(s.floatingPnl, ccy, hidden: hidden, style: theme.textTheme.headlineMedium),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _Stat('Portfolio equity', Text(Fmt.money(s.totalEquity, ccy, hidden: hidden),
                style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis))),
            Expanded(child: _Stat("Today's realized", PnlText(s.realizedPnlToday, ccy, hidden: hidden,
                style: theme.textTheme.titleMedium))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Stat('Connected', Text('${s.accountsLive} / ${s.accountsTotal}',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: s.isComplete ? null : AppColors.warning)))),
            Expanded(
              child: InkWell(
                onTap: onTapPositions,
                child: _Stat('Open · pending', Text('${s.openPositions} · ${s.pendingOrders}',
                    style: theme.textTheme.titleMedium)),
              ),
            ),
          ]),
          const Divider(height: 24),
          Wrap(spacing: 12, runSpacing: 4, children: [
            FreshnessLabel(s.asOf),
            Text('All values in $ccy', style: theme.textTheme.bodySmall),
            for (final r in s.fxRates)
              Text('1 ${r.base} = ${r.rate.toStringAsFixed(4)} ${r.quote}', style: theme.textTheme.bodySmall),
          ]),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        value,
      ]);
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();
  @override
  Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: AppColors.profit),
        SizedBox(width: 4),
        Text('Live', style: TextStyle(fontSize: 12, color: AppColors.profit, fontWeight: FontWeight.w600)),
      ]);
}
