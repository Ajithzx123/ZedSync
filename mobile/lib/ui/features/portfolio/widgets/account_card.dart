import 'package:flutter/material.dart';

import '../../../../domain/models/trading_account.dart';
import '../../../core/format.dart';
import '../../../core/widgets.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.account,
    required this.positionCount,
    required this.hidden,
    this.onTap,
  });

  final TradingAccount account;
  final int positionCount;
  final bool hidden;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = account;
    final theme = Theme.of(context);
    final stale = !a.connectionStatus.isLive;
    final subtitle = [
      a.propFirm ?? a.broker,
      a.accountType.label,
      if (a.isDemo) 'Demo',
      a.currency,
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(a.accountName,
                    style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              StatusChip(a.connectionStatus),
            ]),
            const SizedBox(height: 2),
            Text(subtitle, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Equity', style: theme.textTheme.labelSmall),
                  Text(Fmt.money(a.equity, a.currency, hidden: hidden),
                      style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                PnlText(a.floatingPnl, a.currency, hidden: hidden),
                Text(
                  positionCount == 0 ? 'No positions' : '$positionCount position${positionCount == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall,
                ),
              ]),
            ]),
            if (stale) ...[
              const SizedBox(height: 10),
              WarningBanner(
                message: '${a.statusMessage ?? a.connectionStatus.label}. '
                    'Showing last known values from ${Fmt.ago(a.lastSyncedAt)}.',
              ),
            ] else ...[
              const SizedBox(height: 6),
              FreshnessLabel(a.lastSyncedAt),
            ],
          ]),
        ),
      ),
    );
  }
}
