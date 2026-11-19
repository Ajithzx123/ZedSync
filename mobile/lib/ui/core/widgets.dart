import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/models/enums.dart';
import 'format.dart';
import 'theme.dart';

Color pnlColor(double v) => v > 0 ? AppColors.profit : (v < 0 ? AppColors.loss : AppColors.neutral);

class PnlText extends StatelessWidget {
  const PnlText(this.value, this.currency, {super.key, this.hidden = false, this.style});

  final double value;
  final String currency;
  final bool hidden;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyMedium!;
    return Text(
      Fmt.money(value, currency, hidden: hidden, signed: true),
      style: base.copyWith(color: hidden ? null : pnlColor(value), fontWeight: FontWeight.w600),
      overflow: TextOverflow.ellipsis,
    );
  }
}

Color statusColor(ConnectionStatus s) => switch (s) {
      ConnectionStatus.connected => AppColors.profit,
      ConnectionStatus.syncing || ConnectionStatus.delayed || ConnectionStatus.maintenance => AppColors.warning,
      _ => AppColors.loss,
    };

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: c),
        const SizedBox(width: 5),
        Text(status.label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// "Updated 3s ago" that re-renders itself every second.
class FreshnessLabel extends StatefulWidget {
  const FreshnessLabel(this.time, {super.key, this.prefix = 'Updated', this.style});
  final DateTime? time;
  final String prefix;
  final TextStyle? style;

  @override
  State<FreshnessLabel> createState() => _FreshnessLabelState();
}

class _FreshnessLabelState extends State<FreshnessLabel> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
        '${widget.prefix} ${Fmt.ago(widget.time)}',
        style: widget.style ?? Theme.of(context).textTheme.bodySmall,
      );
}

class WarningBanner extends StatelessWidget {
  const WarningBanner({super.key, required this.message, this.icon = Icons.warning_amber_rounded, this.color});
  final String message;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: c, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
      ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Row(children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
          ?trailing,
        ]),
      );
}

/// Label/value row used on detail screens.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value, {super.key, this.valueWidget});
  final String label;
  final String value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          const SizedBox(width: 12),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget ??
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.right),
            ),
          ),
        ]),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key, this.icon = Icons.inbox_outlined});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 40, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ]),
      );
}
