import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/resource.dart';

class SearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ResourceType? selectedType;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ResourceType?> onTypeChanged;

  const SearchFilterBar({
    super.key,
    required this.searchController,
    required this.selectedType,
    required this.onSearchChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;
        return Container(
          padding: EdgeInsets.all(isCompact ? 14 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un sujet, un auteur ou un mot-clé',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.white.withOpacity(0.55),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (isCompact)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip(null, 'Tout', context),
                    ...ResourceType.values.map(
                      (type) => _buildFilterChip(
                        type,
                        '${type.icon} ${type.label}',
                        context,
                      ),
                    ),
                  ],
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(null, 'Tout', context),
                      const SizedBox(width: 8),
                      ...ResourceType.values.map(
                        (type) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            type,
                            '${type.icon} ${type.label}',
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    ResourceType? type,
    String label,
    BuildContext context,
  ) {
    final isSelected = selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTypeChanged(type),
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.24),
      backgroundColor: Colors.white.withOpacity(0.04),
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.52)
            : Colors.white.withOpacity(0.12),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.white.withOpacity(0.78),
      ),
      showCheckmark: false,
    );
  }
}
