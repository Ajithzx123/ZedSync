import 'package:flutter/material.dart';

import '../../../../domain/models/enums.dart';
import '../../../../domain/models/pending_order.dart';
import '../../../../domain/models/position.dart';
import '../../../../domain/models/trading_account.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';

class SideBadge extends StatelessWidget {
  const SideBadge(this.label, {super.key, required this.isBuy});
  final String label;
  final bool isBuy;

  @override
  Widget build(BuildContext context) {
    final c = isBuy ? AppColors.profit : AppColors.loss;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label.toUpperCase(), style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w700)),
    );
  }
}

class PositionTile extends StatelessWidget {
  const PositionTile({super.key, required this.position, this.account, required this.hidden, this.showAccount = true});

  final Position position;
  final TradingAccount? account;
  final bool hidden;
  final bool showAccount;

  @override
  Widget build(BuildContext context) {
    final p = position;
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: () => showPositionDetails(context, p, account, hidden),
      title: Row(children: [
        Flexible(child: Text(p.symbol, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        SideBadge(p.side.name, isBuy: p.side == Side.buy),
        const SizedBox(width: 6),
        Text(Fmt.volume(p.volume), style: theme.textTheme.bodySmall),
      ]),
      subtitle: Text(
        [
          if (showAccount) account?.accountName ?? p.accountId,
          '${Fmt.price(p.entryPrice)} → ${Fmt.price(p.currentPrice)}',
          Fmt.duration(p.age),
        ].join(' · '),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PnlText(p.floatingPnl, p.currency, hidden: hidden),
    );
  }
}

void showPositionDetails(BuildContext context, Position p, TradingAccount? account, bool hidden) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text(p.symbol, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 10),
            SideBadge(p.side.name, isBuy: p.side == Side.buy),
            const Spacer(),
            PnlText(p.floatingPnl, p.currency, hidden: hidden, style: Theme.of(context).textTheme.titleLarge),
          ]),
          const SizedBox(height: 12),
          KeyValueRow('Account', account?.accountName ?? p.accountId),
          KeyValueRow('Platform', account?.platform.label ?? '-'),
          KeyValueRow('Broker symbol', p.originalSymbol),
          KeyValueRow('Volume', Fmt.volume(p.volume)),
          KeyValueRow('Entry price', Fmt.price(p.entryPrice)),
          KeyValueRow('Current price', Fmt.price(p.currentPrice)),
          KeyValueRow('Stop loss', p.stopLoss == null ? 'None' : Fmt.price(p.stopLoss!)),
          KeyValueRow('Take profit', p.takeProfit == null ? 'None' : Fmt.price(p.takeProfit!)),
          KeyValueRow('Swap', Fmt.money(p.swap, p.currency, hidden: hidden)),
          KeyValueRow('Opened', Fmt.dateTime(p.openedAt)),
          KeyValueRow('Duration', Fmt.duration(p.age)),
          KeyValueRow('Platform position ID', p.platformPositionId),
          const SizedBox(height: 12),
          Text('Monitoring only. Manage this trade in your trading platform.',
              style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}

class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, this.account, this.showAccount = true});

  final PendingOrder order;
  final TradingAccount? account;
  final bool showAccount;

  @override
  Widget build(BuildContext context) {
    final o = order;
    final isBuy = o.orderType.name.startsWith('buy');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Row(children: [
        Flexible(child: Text(o.symbol, style: Theme.of(context).textTheme.titleSmall, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        SideBadge(o.orderType.label, isBuy: isBuy),
        const SizedBox(width: 6),
        Text(Fmt.volume(o.volume), style: Theme.of(context).textTheme.bodySmall),
      ]),
      subtitle: Text(
        [
          if (showAccount) account?.accountName ?? o.accountId,
          'SL ${o.stopLoss == null ? '-' : Fmt.price(o.stopLoss!)}',
          'TP ${o.takeProfit == null ? '-' : Fmt.price(o.takeProfit!)}',
          Fmt.ago(o.createdAt),
        ].join(' · '),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text('@ ${Fmt.price(o.entryPrice)}', style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
