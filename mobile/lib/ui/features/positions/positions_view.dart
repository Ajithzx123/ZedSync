import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/models/enums.dart';
import '../../../domain/models/position.dart';
import '../../core/settings_controller.dart';
import '../../core/widgets.dart';
import '../portfolio/portfolio_controller.dart';
import '../portfolio/widgets/filter_bar.dart';
import 'widgets/position_tiles.dart';

enum PositionSort {
  highestProfit('Highest profit'),
  highestLoss('Highest loss'),
  newest('Newest'),
  oldest('Oldest'),
  largestVolume('Largest volume');

  const PositionSort(this.label);
  final String label;

  int compare(Position a, Position b) => switch (this) {
        PositionSort.highestProfit => b.floatingPnl.compareTo(a.floatingPnl),
        PositionSort.highestLoss => a.floatingPnl.compareTo(b.floatingPnl),
        PositionSort.newest => b.openedAt.compareTo(a.openedAt),
        PositionSort.oldest => a.openedAt.compareTo(b.openedAt),
        PositionSort.largestVolume => b.volume.compareTo(a.volume),
      };
}

class PositionsView extends StatefulWidget {
  const PositionsView({super.key});

  @override
  State<PositionsView> createState() => _PositionsViewState();
}

class _PositionsViewState extends State<PositionsView> {
  PositionSort _sort = PositionSort.newest;
  bool _groupBySymbol = false;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PortfolioController>();
    final settings = Get.find<SettingsController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Positions'),
          actions: [
            IconButton(
              tooltip: _groupBySymbol ? 'Show as list' : 'Group by symbol',
              icon: Icon(_groupBySymbol ? Icons.view_list : Icons.workspaces_outline),
              onPressed: () => setState(() => _groupBySymbol = !_groupBySymbol),
            ),
            PopupMenuButton<PositionSort>(
              tooltip: 'Sort',
              icon: const Icon(Icons.sort),
              initialValue: _sort,
              onSelected: (s) => setState(() => _sort = s),
              itemBuilder: (_) => [for (final s in PositionSort.values) PopupMenuItem(value: s, child: Text(s.label))],
            ),
          ],
          bottom: TabBar(tabs: [
            Obx(() => Tab(text: 'Open (${c.positions.length})')),
            Obx(() => Tab(text: 'Pending (${c.orders.length})')),
          ]),
        ),
        body: Column(children: [
          const SizedBox(height: 4),
          const FilterBar(),
          Expanded(
            child: Obx(() {
              final hidden = settings.privacyMode.value;
              final positions = c.positions.sorted(_sort.compare);
              final orders = c.orders;
              return TabBarView(children: [
                _buildPositions(c, positions, hidden),
                orders.isEmpty
                    ? const EmptyState('No pending orders.')
                    : ListView.separated(
                        itemCount: orders.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) =>
                            OrderTile(order: orders[i], account: c.accountById(orders[i].accountId)),
                      ),
              ]);
            }),
          ),
        ]),
      ),
    );
  }

  Widget _buildPositions(PortfolioController c, List<Position> positions, bool hidden) {
    if (positions.isEmpty) return const EmptyState('No open positions.');
    final buys = positions.where((p) => p.side == Side.buy).length;
    final accountsInProfit = <String>{};
    final accountsInLoss = <String>{};
    groupBy(positions, (Position p) => p.accountId).forEach((id, ps) {
      final total = ps.fold<double>(0, (s, p) => s + p.floatingPnl);
      (total >= 0 ? accountsInProfit : accountsInLoss).add(id);
    });

    final summary = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        '${positions.length} open · $buys buy · ${positions.length - buys} sell · '
        '${accountsInProfit.length} account${accountsInProfit.length == 1 ? '' : 's'} in profit · '
        '${accountsInLoss.length} in loss',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );

    if (!_groupBySymbol) {
      return ListView(children: [
        summary,
        for (final p in positions) ...[
          PositionTile(position: p, account: c.accountById(p.accountId), hidden: hidden),
          const Divider(height: 1),
        ],
      ]);
    }

    final groups = groupBy(positions, (Position p) => p.symbol);
    return ListView(children: [
      summary,
      for (final entry in groups.entries) ...[
        _SymbolGroupHeader(symbol: entry.key, positions: entry.value, hidden: hidden),
        for (final p in entry.value) PositionTile(position: p, account: c.accountById(p.accountId), hidden: hidden),
        const Divider(height: 1),
      ],
    ]);
  }
}

class _SymbolGroupHeader extends StatelessWidget {
  const _SymbolGroupHeader({required this.symbol, required this.positions, required this.hidden});
  final String symbol;
  final List<Position> positions;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final accounts = positions.map((p) => p.accountId).toSet().length;
    final currencies = positions.map((p) => p.currency).toSet();
    final buyVol = positions.where((p) => p.side == Side.buy).fold<double>(0, (s, p) => s + p.volume);
    final sellVol = positions.where((p) => p.side == Side.sell).fold<double>(0, (s, p) => s + p.volume);
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(symbol, style: Theme.of(context).textTheme.titleSmall),
            Text(
              '${positions.length} positions · $accounts account${accounts == 1 ? '' : 's'} · '
              'buy ${buyVol.toStringAsFixed(2)} / sell ${sellVol.toStringAsFixed(2)} lots',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ]),
        ),
        // Only sum P&L when every position shares one currency.
        if (currencies.length == 1)
          PnlText(positions.fold<double>(0, (s, p) => s + p.floatingPnl), currencies.first, hidden: hidden)
        else
          Text('Mixed currencies', style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
