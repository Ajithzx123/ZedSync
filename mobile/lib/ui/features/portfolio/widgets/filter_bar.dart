import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../portfolio_controller.dart';

/// Horizontal account filter chips, shared by Home, Accounts and Positions.
class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PortfolioController>();
    return SizedBox(
      height: 44,
      child: Obx(() {
        final current = c.filter.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: AccountFilter.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = AccountFilter.values[i];
            return Center(
              child: ChoiceChip(
                label: Text(f.label),
                selected: f == current,
                onSelected: (_) => c.setFilter(f),
              ),
            );
          },
        );
      }),
    );
  }
}
