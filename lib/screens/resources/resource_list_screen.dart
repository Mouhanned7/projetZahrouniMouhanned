import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/resource.dart';
import '../../services/resource_service.dart';
import '../../widgets/loading_shimmer.dart';

class ResourceListScreen extends StatefulWidget {
  const ResourceListScreen({super.key});

  @override
  State<ResourceListScreen> createState() => _ResourceListScreenState();
}

enum _SortMode {
  newest,
  title,
  rating,
  downloads,
}

enum _ViewMode {
  grid,
  list,
  compact,
}

class _ResourceListScreenState extends State<ResourceListScreen> {
  final _resourceService = ResourceService();
  final _searchController = TextEditingController();

  Timer? _searchDebounce;

  List<Resource> _resources = [];
  bool _isLoading = true;

  ResourceType? _selectedType;
  String? _selectedSubject;

  _SortMode _sortMode = _SortMode.newest;
  _ViewMode _viewMode = _ViewMode.grid;

  final Set<String> _savedResourceIds = {};

  final List<String> _subjects = [
    'IOT',
    'GLSI',
    'SIOT',
    'Réseaux',
  ];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    setState(() => _isLoading = true);

    try {
      final resources = await _resourceService.getResources(
        type: _selectedType,
        subject: _selectedSubject,
        searchQuery: _searchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _resources = _sortResources(resources);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de charger les ressources.'),
          backgroundColor: _AppColors.danger,
        ),
      );
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});

    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      _loadResources,
    );
  }

  List<Resource> _sortResources(List<Resource> resources) {
    final sorted = [...resources];

    switch (_sortMode) {
      case _SortMode.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortMode.title:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case _SortMode.rating:
        sorted.sort((a, b) => b.avgRating.compareTo(a.avgRating));
        break;
      case _SortMode.downloads:
        sorted.sort((a, b) => b.downloadsCount.compareTo(a.downloadsCount));
        break;
    }

    return sorted;
  }

  void _changeSort(_SortMode mode) {
    setState(() {
      _sortMode = mode;
      _resources = _sortResources(_resources);
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedType = null;
      _selectedSubject = null;
      _sortMode = _SortMode.newest;
      _searchController.clear();
    });

    _loadResources();
  }

  void _toggleSaved(Resource resource) {
    final id = resource.id.toString();

    setState(() {
      if (_savedResourceIds.contains(id)) {
        _savedResourceIds.remove(id);
      } else {
        _savedResourceIds.add(id);
      }
    });
  }

  int get _activeFiltersCount {
    var count = 0;

    if (_selectedType != null) count++;
    if (_selectedSubject != null) count++;
    if (_searchController.text.trim().isNotEmpty) count++;

    return count;
  }

  int _gridCount(double width) {
    if (width < 560) return 1;
    if (width < 920) return 2;
    if (width < 1280) return 3;
    return 4;
  }

  double _gridCardHeight(double width) {
    if (width < 560) return 252;
    if (width < 920) return 255;
    return 270;
  }

  String _sortLabel() {
    switch (_sortMode) {
      case _SortMode.newest:
        return 'Plus récent';
      case _SortMode.title:
        return 'Titre A-Z';
      case _SortMode.rating:
        return 'Meilleure note';
      case _SortMode.downloads:
        return 'Plus téléchargé';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    final horizontalPadding = width >= 1280
        ? 40.0
        : width >= 900
            ? 28.0
            : 16.0;

    final compact = width < 720;

    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _AppColors.primary,
          onRefresh: _loadResources,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    18,
                    horizontalPadding,
                    0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(compact),
                          const SizedBox(height: 18),
                          _buildSearchAndMainActions(compact),
                          const SizedBox(height: 14),
                          if (!compact) ...[
                            _buildTypeFilters(),
                            const SizedBox(height: 10),
                            _buildSubjectFilters(),
                            const SizedBox(height: 12),
                          ],
                          _buildActiveFilters(),
                          const SizedBox(height: 14),
                          _buildStatsAndResultBar(compact),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                SliverFillRemaining(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: LoadingShimmer(isGrid: _viewMode == _ViewMode.grid),
                  ),
                )
              else if (_resources.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else if (_viewMode == _ViewMode.grid)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    120 + bottomSafe,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridCount(width),
                      mainAxisExtent: _gridCardHeight(width),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildResourceGridCard(_resources[index]);
                      },
                      childCount: _resources.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    120 + bottomSafe,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final resource = _resources[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _viewMode == _ViewMode.compact
                              ? _buildCompactItem(resource)
                              : _buildResourceListItem(resource),
                        );
                      },
                      childCount: _resources.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool compact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ressources',
                style: TextStyle(
                  color: _AppColors.text,
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cours, rapports, présentations et codes partagés.',
                style: TextStyle(
                  color: _AppColors.muted,
                  fontSize: compact ? 13 : 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 14),
          ElevatedButton.icon(
            onPressed: () => context.go('/resources/upload'),
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('Ajouter'),
            style: _primaryButtonStyle(),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchAndMainActions(bool compact) {
    final searchField = TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _loadResources(),
      decoration: InputDecoration(
        hintText: 'Rechercher...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.trim().isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  _loadResources();
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: _AppColors.primary,
            width: 1.4,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _viewModeButton(
          icon: Icons.grid_view_rounded,
          tooltip: 'Grille',
          selected: _viewMode == _ViewMode.grid,
          onTap: () => setState(() => _viewMode = _ViewMode.grid),
        ),
        const SizedBox(width: 8),
        _viewModeButton(
          icon: Icons.density_medium_rounded,
          tooltip: 'Compact',
          selected: _viewMode == _ViewMode.compact,
          onTap: () => setState(() => _viewMode = _ViewMode.compact),
        ),
        const SizedBox(width: 8),
        _sortMenuButton(),
        if (compact) ...[
          const SizedBox(width: 8),
          _iconButton(
            icon: Icons.tune_rounded,
            tooltip: 'Filtres',
            onTap: _openFilterSheet,
          ),
        ],
      ],
    );

    if (compact) {
      return Column(
        children: [
          searchField,
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: actions,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => context.go('/resources/upload'),
                style: _primaryButtonStyle(),
                child: const Icon(Icons.add_rounded, size: 20),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 12),
        actions,
      ],
    );
  }

  Widget _buildTypeFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Type',
              style: TextStyle(
                color: _AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChipButton(
                  label: 'Tout',
                  selected: _selectedType == null,
                  onTap: () {
                    setState(() => _selectedType = null);
                    _loadResources();
                  },
                ),
                const SizedBox(width: 8),
                ...ResourceType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _filterChipButton(
                      label: type.label,
                      selected: _selectedType == type,
                      onTap: () {
                        setState(() => _selectedType = type);
                        _loadResources();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Parcours',
              style: TextStyle(
                color: _AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _smallChipButton(
                  label: 'Tous les parcours',
                  selected: _selectedSubject == null,
                  onTap: () {
                    setState(() => _selectedSubject = null);
                    _loadResources();
                  },
                ),
                const SizedBox(width: 8),
                ..._subjects.map(
                  (subject) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _smallChipButton(
                      label: subject,
                      selected: _selectedSubject == subject,
                      onTap: () {
                        setState(() {
                          _selectedSubject =
                              _selectedSubject == subject ? null : subject;
                        });
                        _loadResources();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    final chips = <Widget>[];

    if (_searchController.text.trim().isNotEmpty) {
      chips.add(
        _activeFilterChip(
          label: 'Recherche: ${_searchController.text.trim()}',
          onRemove: () {
            _searchController.clear();
            _loadResources();
          },
        ),
      );
    }

    if (_selectedType != null) {
      chips.add(
        _activeFilterChip(
          label: _selectedType!.label,
          onRemove: () {
            setState(() => _selectedType = null);
            _loadResources();
          },
        ),
      );
    }

    if (_selectedSubject != null) {
      chips.add(
        _activeFilterChip(
          label: _selectedSubject!,
          onRemove: () {
            setState(() => _selectedSubject = null);
            _loadResources();
          },
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...chips,
        TextButton.icon(
          onPressed: _resetFilters,
          icon: const Icon(Icons.filter_alt_off_rounded, size: 17),
          label: const Text('Reset'),
          style: TextButton.styleFrom(
            foregroundColor: _AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _activeFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 11, right: 5, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: _AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _AppColors.primary.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(
                Icons.close_rounded,
                size: 15,
                color: _AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsAndResultBar(bool compact) {
    final averageRating = _resources.isEmpty
        ? 0.0
        : _resources.map((r) => r.avgRating).reduce((a, b) => a + b) /
            _resources.length;

    final downloads = _resources.fold<int>(
      0,
      (sum, resource) => sum + resource.downloadsCount,
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _resultText(),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statPill('Note moyenne', averageRating.toStringAsFixed(1)),
                const SizedBox(width: 8),
                _statPill('Téléchargements', '$downloads'),
                const SizedBox(width: 8),
                _statPill('Tri', _sortLabel()),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _resultText()),
        _statPill('Note moyenne', averageRating.toStringAsFixed(1)),
        const SizedBox(width: 8),
        _statPill('Téléchargements', '$downloads'),
        const SizedBox(width: 8),
        _statPill('Tri', _sortLabel()),
      ],
    );
  }

  Widget _resultText() {
    return Text(
      '${_resources.length} ressource(s) trouvée(s)',
      style: const TextStyle(
        color: _AppColors.muted,
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _statPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: _AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceGridCard(Resource resource) {
    final saved = _savedResourceIds.contains(resource.id.toString());

    return InkWell(
      onTap: () => context.go('/resources/${resource.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 72,
              padding: const EdgeInsets.all(14),
              color: _AppColors.primarySoft,
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(
                        resource.type.icon,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      resource.type.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _toggleSaved(resource),
                    icon: Icon(
                      saved ? Icons.bookmark_rounded : Icons.bookmark_border,
                      color: saved ? _AppColors.primary : _AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AppColors.text,
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      resource.description.isEmpty
                          ? 'Aucune description disponible.'
                          : resource.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AppColors.muted,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _tinyBadge(
                          resource.subject.isEmpty
                              ? 'Général'
                              : resource.subject,
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 17,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          resource.avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: _AppColors.text,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: _AppColors.primarySoft,
                          child: Text(
                            _authorInitial(resource),
                            style: const TextStyle(
                              color: _AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            resource.authorName ?? 'Anonyme',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.download_rounded,
                                color: _AppColors.muted,
                                size: 15,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  '${resource.downloadsCount}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _AppColors.muted,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceListItem(Resource resource) {
    final saved = _savedResourceIds.contains(resource.id.toString());

    return InkWell(
      onTap: () => context.go('/resources/${resource.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: _AppColors.primarySoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  resource.type.icon,
                  style: const TextStyle(fontSize: 23),
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${resource.type.label} • ${resource.authorName ?? "Anonyme"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _AppColors.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _toggleSaved(resource),
              icon: Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_border,
                color: saved ? _AppColors.primary : _AppColors.muted,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactItem(Resource resource) {
    final saved = _savedResourceIds.contains(resource.id.toString());

    return ListTile(
      onTap: () => context.go('/resources/${resource.id}'),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _AppColors.border),
      ),
      leading: CircleAvatar(
        backgroundColor: _AppColors.primarySoft,
        child: Text(resource.type.icon),
      ),
      title: Text(
        resource.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _AppColors.text,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        '${resource.type.label} • ${resource.subject.isEmpty ? "Général" : resource.subject}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        onPressed: () => _toggleSaved(resource),
        icon: Icon(
          saved ? Icons.bookmark_rounded : Icons.bookmark_border,
          color: saved ? _AppColors.primary : _AppColors.muted,
        ),
      ),
    );
  }

  Widget _filterChipButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF121B78), Color(0xFF2633A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _AppColors.primary : _AppColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _AppColors.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _AppColors.muted,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallChipButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? _AppColors.primary : _AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _AppColors.primary : _AppColors.muted,
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewModeButton({
    required IconData icon,
    required String tooltip,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: selected ? _AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _AppColors.primary : _AppColors.border,
            ),
          ),
          child: Icon(
            icon,
            color: selected ? Colors.white : _AppColors.muted,
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _AppColors.border),
          ),
          child: Icon(
            icon,
            color: _AppColors.muted,
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget _sortMenuButton() {
    return PopupMenuButton<_SortMode>(
      tooltip: 'Trier',
      onSelected: _changeSort,
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      itemBuilder: (context) => [
        _sortItem(_SortMode.newest, 'Plus récent', Icons.schedule_rounded),
        _sortItem(_SortMode.title, 'Titre A-Z', Icons.sort_by_alpha_rounded),
        _sortItem(_SortMode.rating, 'Meilleure note', Icons.star_rounded),
        _sortItem(
          _SortMode.downloads,
          'Plus téléchargé',
          Icons.download_rounded,
        ),
      ],
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _AppColors.border),
        ),
        child: const Icon(
          Icons.swap_vert_rounded,
          color: _AppColors.muted,
        ),
      ),
    );
  }

  PopupMenuItem<_SortMode> _sortItem(
    _SortMode mode,
    String label,
    IconData icon,
  ) {
    final selected = _sortMode == mode;

    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(
            icon,
            color: selected ? _AppColors.primary : _AppColors.muted,
            size: 19,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: selected ? _AppColors.primary : _AppColors.text,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tinyBadge(String label) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _AppColors.primary,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _authorInitial(Resource resource) {
    final name = resource.authorName;

    if (name == null || name.trim().isEmpty) return '?';

    return name.trim()[0].toUpperCase();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.folder_open_rounded,
                color: _AppColors.primary,
                size: 48,
              ),
              const SizedBox(height: 14),
              const Text(
                'Aucune ressource trouvée',
                style: TextStyle(
                  color: _AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Essayez une autre recherche ou réinitialisez les filtres.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _AppColors.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _resetFilters,
                style: _primaryButtonStyle(),
                child: const Text('Réinitialiser'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void refreshBoth(VoidCallback action) {
              setState(action);
              setSheetState(() {});
              _loadResources();
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                6,
                18,
                18 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtres',
                    style: TextStyle(
                      color: _AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Type',
                    style: TextStyle(
                      color: _AppColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _filterChipButton(
                        label: 'Tout',
                        selected: _selectedType == null,
                        onTap: () {
                          refreshBoth(() => _selectedType = null);
                        },
                      ),
                      ...ResourceType.values.map(
                        (type) => _filterChipButton(
                          label: type.label,
                          selected: _selectedType == type,
                          onTap: () {
                            refreshBoth(() => _selectedType = type);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Parcours',
                    style: TextStyle(
                      color: _AppColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _smallChipButton(
                        label: 'Tous',
                        selected: _selectedSubject == null,
                        onTap: () {
                          refreshBoth(() => _selectedSubject = null);
                        },
                      ),
                      ..._subjects.map(
                        (subject) => _smallChipButton(
                          label: subject,
                          selected: _selectedSubject == subject,
                          onTap: () {
                            refreshBoth(() {
                              _selectedSubject =
                                  _selectedSubject == subject ? null : subject;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _resetFilters();
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: _primaryButtonStyle(),
                          child: const Text('Appliquer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _AppColors {
  static const primary = Color(0xFF15196C);
  static const primarySoft = Color(0xFFEDEEFF);
  static const background = Color(0xFFF6F7FB);
  static const text = Color(0xFF151725);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE4E7EC);
  static const danger = Color(0xFFBA1A1A);
}
