import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format.dart';
import '../../core/settings_controller.dart';
import '../../core/widgets.dart';
import '../portfolio/portfolio_controller.dart';

/// Phase 1: cross-account exposure. Performance analytics arrive in Phase 5.
class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PortfolioController>();
    final settings = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Obx(() {
        final snap = c.snapshot.value;
        if (snap == null) return const Center(child: CircularProgressIndicator());
        final hidden = settings.privacyMode.value;
        final ccy = snap.summary.baseCurrency;
        final warnings = snap.exposure.where((e) => e.sameDirectionMultiAccount).toList();
        final theme = Theme.of(context);

        return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          for (final e in warnings) ...[
            WarningBanner(
              icon: Icons.hub_outlined,
              message: 'You have ${e.positions} ${e.symbol} ${e.netVolume >= 0 ? 'buy' : 'sell'} positions across '
                  '${e.accounts} accounts, combined floating '
                  '${Fmt.money(e.floatingPnl, ccy, hidden: hidden, signed: true)}. '
                  'This is information, not a trade recommendation.',
            ),
            const SizedBox(height: 8),
          ],
          const SectionTitle('Exposure by instrument'),
          if (snap.exposure.isEmpty) const EmptyState('No open exposure.'),
          for (final e in snap.exposure) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(e.symbol, style: theme.textTheme.titleSmall)),
                    PnlText(e.floatingPnl, ccy, hidden: hidden),
                  ]),
                  const SizedBox(height: 6),
                  KeyValueRow('Buy volume', Fmt.volume(e.buyVolume)),
                  KeyValueRow('Sell volume', Fmt.volume(e.sellVolume)),
                  KeyValueRow('Net volume', Fmt.volume(e.netVolume)),
                  KeyValueRow('Accounts · positions', '${e.accounts} · ${e.positions}'),
                  Text(e.note, style: theme.textTheme.bodySmall),
                ]),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SectionTitle('Performance'),
          const WarningBanner(
            icon: Icons.insights,
            message: 'Win rate, profit factor, equity curve and account comparison arrive in a later release, '
                'calculated from your closed deals.',
          ),
        ]);
      }),
    );
  }
}
