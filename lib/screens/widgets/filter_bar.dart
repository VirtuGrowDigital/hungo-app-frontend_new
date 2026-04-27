import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import '../../utils/ColorConstants.dart';

class FilterBar extends GetView<HomeController> {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          _FilterPill(
            icon: Icons.tune_rounded,
            label: controller.activeFilterCount > 0
                ? "Filters (${controller.activeFilterCount})"
                : "Filters",
            isSelected: controller.hasActiveFilters,
            onTap: () async {
              final result = await showFilterBottomSheet(
                context,
                initialSortIndex: controller.sortIndex.value,
                initialPriceRangeIndex: controller.priceRangeIndex.value,
                initialRatingEnabled: controller.ratingFilter.value,
                initialStockOnly: controller.inStockOnly.value,
              );

              if (result == null) return;

              controller.updateFilterState(
                sort: result.sortIndex,
                resetSort: result.sortIndex == null,
                priceRange: result.priceRangeIndex,
                resetPriceRange: result.priceRangeIndex == null,
                rating: result.ratingEnabled,
                stockOnly: result.stockOnly,
              );
            },
          ),
          const SizedBox(width: 10),
          _FilterPill(
            icon: Icons.swap_vert_rounded,
            label: controller.selectedSortLabel,
            isSelected: controller.sortIndex.value != null,
            onTap: () async {
              final result = await showSortBottomSheet(
                context,
                controller.sortIndex.value,
              );
              controller.setSortIndex(result);
            },
          ),
          const SizedBox(width: 10),
          _FilterPill(
            icon: Icons.currency_rupee_rounded,
            label: controller.selectedPriceRangeLabel,
            isSelected: controller.priceRangeIndex.value != null,
            onTap: () async {
              final result = await showPriceBottomSheet(
                context,
                controller.priceRangeIndex.value,
              );
              controller.setPriceRangeIndex(result);
            },
          ),
          const SizedBox(width: 10),
          _FilterPill(
            icon: Icons.star_rounded,
            label: "Rating 4+",
            isSelected: controller.ratingFilter.value,
            onTap: controller.toggleRatingFilter,
          ),
          const SizedBox(width: 10),
          _FilterPill(
            icon: Icons.inventory_2_outlined,
            label: "In stock",
            isSelected: controller.inStockOnly.value,
            onTap: controller.toggleInStockOnly,
          ),
          if (controller.hasActiveFilters) ...[
            const SizedBox(width: 10),
            _FilterPill(
              icon: Icons.restart_alt_rounded,
              label: "Reset",
              isSelected: false,
              isGhost: true,
              onTap: controller.clearFilters,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isGhost;
  final VoidCallback onTap;

  const _FilterPill({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isGhost = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? ColorConstants.primaryDark
        : isGhost
            ? const Color(0xFFD4E2DB)
            : const Color(0xFFE0EAE5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEAF7F1) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF113B2C).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? ColorConstants.primaryDark
                    : const Color(0xFF38564A),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF17392D),
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<int?> showSortBottomSheet(
  BuildContext context,
  int? currentIndex,
) {
  return showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ChoiceBottomSheet(
      title: "Sort products",
      subtitle: "Choose how you want the listing ordered.",
      options: HomeController.sortOptions,
      initialIndex: currentIndex,
    ),
  );
}

Future<int?> showPriceBottomSheet(
  BuildContext context,
  int? currentIndex,
) {
  return showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ChoiceBottomSheet(
      title: "Price range",
      subtitle: "Quickly narrow the products to your budget.",
      options: HomeController.priceRangeOptions,
      initialIndex: currentIndex,
      clearLabel: "Any price",
    ),
  );
}

Future<FilterSheetResult?> showFilterBottomSheet(
  BuildContext context, {
  required int? initialSortIndex,
  required int? initialPriceRangeIndex,
  required bool initialRatingEnabled,
  required bool initialStockOnly,
}) {
  return showModalBottomSheet<FilterSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FilterBottomSheet(
      initialSortIndex: initialSortIndex,
      initialPriceRangeIndex: initialPriceRangeIndex,
      initialRatingEnabled: initialRatingEnabled,
      initialStockOnly: initialStockOnly,
    ),
  );
}

class _ChoiceBottomSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> options;
  final int? initialIndex;
  final String clearLabel;

  const _ChoiceBottomSheet({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.initialIndex,
    this.clearLabel = "Clear selection",
  });

  @override
  State<_ChoiceBottomSheet> createState() => _ChoiceBottomSheetState();
}

class _ChoiceBottomSheetState extends State<_ChoiceBottomSheet> {
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetShell(
      title: widget.title,
      subtitle: widget.subtitle,
      child: Column(
        children: [
          ...List.generate(widget.options.length, (index) {
            final isSelected = selectedIndex == index;
            return Padding(
              padding: EdgeInsets.only(
                  bottom: index == widget.options.length - 1 ? 0 : 10),
              child: _ChoiceTile(
                label: widget.options[index],
                isSelected: isSelected,
                onTap: () => setState(() => selectedIndex = index),
              ),
            );
          }),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD7E3DD)),
                    foregroundColor: const Color(0xFF38564A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(widget.clearLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, selectedIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Apply"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final int? initialSortIndex;
  final int? initialPriceRangeIndex;
  final bool initialRatingEnabled;
  final bool initialStockOnly;

  const _FilterBottomSheet({
    required this.initialSortIndex,
    required this.initialPriceRangeIndex,
    required this.initialRatingEnabled,
    required this.initialStockOnly,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late int? selectedSortIndex;
  late int? selectedPriceRangeIndex;
  late bool ratingEnabled;
  late bool stockOnly;

  @override
  void initState() {
    super.initState();
    selectedSortIndex = widget.initialSortIndex;
    selectedPriceRangeIndex = widget.initialPriceRangeIndex;
    ratingEnabled = widget.initialRatingEnabled;
    stockOnly = widget.initialStockOnly;
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetShell(
      title: "All filters",
      subtitle: "Refine the list without losing your place in the catalog.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetSectionTitle("Sort by"),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(HomeController.sortOptions.length, (index) {
              return _SelectableChip(
                label: HomeController.sortOptions[index],
                selected: selectedSortIndex == index,
                onTap: () => setState(() => selectedSortIndex = index),
              );
            }),
          ),
          const SizedBox(height: 18),
          const _SheetSectionTitle("Price range"),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                List.generate(HomeController.priceRangeOptions.length, (index) {
              return _SelectableChip(
                label: HomeController.priceRangeOptions[index],
                selected: selectedPriceRangeIndex == index,
                onTap: () => setState(() => selectedPriceRangeIndex = index),
              );
            }),
          ),
          const SizedBox(height: 18),
          _SwitchTile(
            icon: Icons.star_rounded,
            title: "Highly rated",
            subtitle: "Show products rated 4.0 and above.",
            value: ratingEnabled,
            onChanged: (value) => setState(() => ratingEnabled = value),
          ),
          const SizedBox(height: 12),
          _SwitchTile(
            icon: Icons.inventory_2_outlined,
            title: "Ready to add",
            subtitle: "Only include products with available variants.",
            value: stockOnly,
            onChanged: (value) => setState(() => stockOnly = value),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    const FilterSheetResult(),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD7E3DD)),
                    foregroundColor: const Color(0xFF38564A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Reset"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    FilterSheetResult(
                      sortIndex: selectedSortIndex,
                      priceRangeIndex: selectedPriceRangeIndex,
                      ratingEnabled: ratingEnabled,
                      stockOnly: stockOnly,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Apply"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomSheetShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _BottomSheetShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FCFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6E3DC),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17392D),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: Color(0xFF567267),
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF7F1) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? ColorConstants.primaryDark
                : const Color(0xFFDDE8E2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF17392D),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: isSelected
                      ? ColorConstants.primaryDark
                      : const Color(0xFFB9CAC2),
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: CircleAvatar(
                        radius: 5,
                        backgroundColor: ColorConstants.primaryDark,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF7F1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                selected ? ColorConstants.primaryDark : const Color(0xFFDDE8E2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: const Color(0xFF17392D),
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE8E2)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ColorConstants.primaryDark, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF17392D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Color(0xFF5F786E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: ColorConstants.primaryDark,
          ),
        ],
      ),
    );
  }
}

class _SheetSectionTitle extends StatelessWidget {
  final String title;

  const _SheetSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF17392D),
      ),
    );
  }
}

class FilterSheetResult {
  final int? sortIndex;
  final int? priceRangeIndex;
  final bool ratingEnabled;
  final bool stockOnly;

  const FilterSheetResult({
    this.sortIndex,
    this.priceRangeIndex,
    this.ratingEnabled = false,
    this.stockOnly = false,
  });
}
