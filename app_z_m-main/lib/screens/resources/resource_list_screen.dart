import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../models/resource.dart';
import '../../services/resource_service.dart';
import '../../widgets/resource_card.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/loading_shimmer.dart';

class ResourceListScreen extends StatefulWidget {
  const ResourceListScreen({super.key});

  @override
  State<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends State<ResourceListScreen> {
  final _resourceService = ResourceService();
  final _searchController = TextEditingController();
  List<Resource> _resources = [];
  bool _isLoading = true;
  ResourceType? _selectedType;
  String? _selectedSubject;
  bool _isGridView = true;

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    setState(() => _isLoading = true);
    try {
      final resources = await _resourceService.getResources(
        type: _selectedType,
        subject: _selectedSubject,
        searchQuery: _searchController.text,
      );
      if (mounted) {
        setState(() {
          _resources = resources;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding =
        width >= 1280 ? 36.0 : (width >= 900 ? 24.0 : 16.0);
    final isCompactHeader = width < 920;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF061120), Color(0xFF0A1A2E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 24, horizontalPadding, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(isCompactHeader),
                    const SizedBox(height: 16),
                    SearchFilterBar(
                      searchController: _searchController,
                      selectedType: _selectedType,
                      onSearchChanged: (q) => _loadResources(),
                      onTypeChanged: (type) {
                        setState(() => _selectedType = type);
                        _loadResources();
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildSubjectFilters(),
                    const SizedBox(height: 14),
                    Text(
                      '${_resources.length} ressource(s) trouvée(s)'
                      '${_selectedSubject != null ? ' • ${_selectedSubject!}' : ''}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              SliverFillRemaining(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: LoadingShimmer(isGrid: _isGridView),
                ),
              )
            else if (_resources.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else if (_isGridView)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 0, horizontalPadding, 28),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: width >= 1280 ? 350 : 330,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ResourceCard(
                      resource: _resources[index],
                      onTap: () =>
                          context.go('/resources/${_resources[index].id}'),
                    ),
                    childCount: _resources.length,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 0, horizontalPadding, 28),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildListItem(_resources[index]),
                    ),
                    childCount: _resources.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isCompactHeader) {
    final selectedTypeLabel = _selectedType?.label ?? 'Tous les types';
    final subtitle = _selectedSubject == null
        ? 'PFE, cours, rapports et snippets à portée de main'
        : 'Filtre actif: ${_selectedSubject!} • $selectedTypeLabel';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.95),
            AppTheme.darkSurface.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isCompactHeader
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroTitle(subtitle),
                const SizedBox(height: 14),
                _buildHeroActions(wrap: true),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildHeroTitle(subtitle)),
                const SizedBox(width: 14),
                _buildHeroActions(wrap: false),
              ],
            ),
    );
  }

  Widget _buildHeroTitle(String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bibliothèque PFE',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroActions({required bool wrap}) {
    final viewToggle = Container(
      decoration: AppTheme.glassDecoration(opacity: 0.06),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => setState(() => _isGridView = true),
            icon: Icon(
              Icons.grid_view_rounded,
              color: _isGridView
                  ? AppTheme.primaryColor
                  : Colors.white.withOpacity(0.45),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _isGridView = false),
            icon: Icon(
              Icons.view_list_rounded,
              color: !_isGridView
                  ? AppTheme.primaryColor
                  : Colors.white.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );

    final uploadButton = ElevatedButton.icon(
      onPressed: () => context.go('/resources/upload'),
      icon: const Icon(Icons.upload_file_rounded, size: 18),
      label: const Text('Ajouter une ressource'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );

    if (wrap) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [viewToggle, uploadButton],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        viewToggle,
        const SizedBox(width: 10),
        uploadButton,
      ],
    );
  }

  Widget _buildSubjectFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildSubjectChip(
          label: 'Tous les parcours',
          selected: _selectedSubject == null,
          onTap: () {
            setState(() => _selectedSubject = null);
            _loadResources();
          },
        ),
        ..._subjects.map(
          (subject) => _buildSubjectChip(
            label: subject,
            selected: _selectedSubject == subject,
            onTap: () {
              setState(() {
                _selectedSubject = _selectedSubject == subject ? null : subject;
              });
              _loadResources();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryColor.withOpacity(0.24),
      backgroundColor: Colors.white.withOpacity(0.04),
      side: BorderSide(
        color: selected
            ? AppTheme.primaryColor.withOpacity(0.45)
            : Colors.white.withOpacity(0.12),
      ),
      labelStyle: TextStyle(
        color: selected ? AppTheme.primaryColor : Colors.white.withOpacity(0.8),
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface.withOpacity(0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(height: 14),
              const Text(
                'Aucune ressource trouvée',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Essayez un autre filtre ou publiez la première ressource de votre promo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.go('/resources/upload'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajouter une ressource'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(Resource resource) {
    return GestureDetector(
      onTap: () => context.go('/resources/${resource.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.95),
              AppTheme.darkSurface.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(resource.type.icon,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${resource.type.label} • ${resource.authorName ?? "Anonyme"} • ${resource.fileSizeFormatted}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ),
            ),
            if (resource.avgRating > 0)
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 3),
                  Text(
                    resource.avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.45)),
          ],
        ),
      ),
    );
  }
}
