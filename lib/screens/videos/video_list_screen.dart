import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/video.dart';
import '../../services/video_service.dart';
import '../../widgets/loading_shimmer.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

enum _VideoSortMode {
  newest,
  title,
}

enum _VideoViewMode {
  grid,
  list,
}

class _VideoListScreenState extends State<VideoListScreen> {
  final _videoService = VideoService();
  final _searchController = TextEditingController();

  Timer? _searchDebounce;

  List<Video> _loadedVideos = [];
  List<Video> _videos = [];

  bool _isLoading = true;
  bool _hasError = false;
  bool _showSavedOnly = false;

  String? _selectedCategory;

  _VideoSortMode _sortMode = _VideoSortMode.newest;
  _VideoViewMode _viewMode = _VideoViewMode.grid;

  final Set<String> _savedVideoIds = {};

  final List<String> _categories = const [
    'Programmation',
    'Mathematiques',
    'Physique',
    'Design',
    'Marketing',
    'Langues',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final videos = await _videoService.getPublicVideos(
        category: _selectedCategory,
        searchQuery: _searchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _loadedVideos = videos;
        _videos = _applyLocalFiltersAndSort(videos);
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Impossible de charger les vidéos.'),
          backgroundColor: _AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});

    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 380),
      _loadVideos,
    );
  }

  List<Video> _applyLocalFiltersAndSort(List<Video> source) {
    var result = [...source];

    if (_showSavedOnly) {
      result = result
          .where((video) => _savedVideoIds.contains(video.id.toString()))
          .toList();
    }

    switch (_sortMode) {
      case _VideoSortMode.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;

      case _VideoSortMode.title:
        result.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
    }

    return result;
  }

  void _refreshLocalList() {
    setState(() {
      _videos = _applyLocalFiltersAndSort(_loadedVideos);
    });
  }

  void _changeSort(_VideoSortMode mode) {
    setState(() {
      _sortMode = mode;
      _videos = _applyLocalFiltersAndSort(_loadedVideos);
    });
  }

  void _setCategory(String? category) {
    if (_selectedCategory == category) return;

    setState(() => _selectedCategory = category);
    _loadVideos();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _showSavedOnly = false;
      _sortMode = _VideoSortMode.newest;
      _searchController.clear();
    });

    _loadVideos();
  }

  void _toggleSaved(Video video) {
    final id = video.id.toString();

    setState(() {
      if (_savedVideoIds.contains(id)) {
        _savedVideoIds.remove(id);
      } else {
        _savedVideoIds.add(id);
      }

      _videos = _applyLocalFiltersAndSort(_loadedVideos);
    });
  }

  int get _activeFilterCount {
    var count = 0;

    if (_selectedCategory != null) count++;
    if (_searchController.text.trim().isNotEmpty) count++;
    if (_showSavedOnly) count++;

    return count;
  }

  bool get _hasSearch => _searchController.text.trim().isNotEmpty;

  int _gridCount(double width) {
    if (width < 620) return 1;
    if (width < 980) return 2;
    if (width < 1320) return 3;
    return 5;
  }

  double _gridHeight(double width) {
  if (width < 620) return 300;
  if (width < 980) return 285;
  return 275;
}

  double _horizontalPadding(double width) {
    if (width >= 1280) return 40;
    if (width >= 900) return 28;
    return 16;
  }

  String _sortLabel() {
    switch (_sortMode) {
      case _VideoSortMode.newest:
        return 'Plus récent';
      case _VideoSortMode.title:
        return 'Titre A-Z';
    }
  }

  String _viewLabel() {
    switch (_viewMode) {
      case _VideoViewMode.grid:
        return 'Grille';
      case _VideoViewMode.list:
        return 'Liste';
    }
  }

  String _categoryLabel(String? category) {
    switch (category) {
      case 'Mathematiques':
        return 'Mathématiques';
      default:
        return category ?? 'Toutes';
    }
  }

  IconData _categoryIcon(String? category) {
    switch (category) {
      case 'Programmation':
        return Icons.code_rounded;
      case 'Mathematiques':
        return Icons.functions_rounded;
      case 'Physique':
        return Icons.science_rounded;
      case 'Design':
        return Icons.palette_rounded;
      case 'Marketing':
        return Icons.campaign_rounded;
      case 'Langues':
        return Icons.translate_rounded;
      case 'Autre':
        return Icons.more_horiz_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'Programmation':
        return const Color(0xFF2563EB);
      case 'Mathematiques':
        return const Color(0xFF16A34A);
      case 'Physique':
        return const Color(0xFFF59E0B);
      case 'Design':
        return const Color(0xFFF43F5E);
      case 'Marketing':
        return const Color(0xFFEC4899);
      case 'Langues':
        return const Color(0xFF4F46E5);
      case 'Autre':
        return const Color(0xFF7C3AED);
      default:
        return _AppColors.primary;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final compact = width < 760;
    final horizontalPadding = _horizontalPadding(width);

    return Scaffold(
      backgroundColor: _AppColors.background,
      floatingActionButton: compact
          ? FloatingActionButton(
              onPressed: () => context.go('/videos/upload'),
              backgroundColor: _AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _AppColors.primary,
          onRefresh: _loadVideos,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    22,
                    horizontalPadding,
                    0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(compact),
                          const SizedBox(height: 22),
                          _buildSearchAndPrimaryAction(compact),
                          const SizedBox(height: 20),
                          // _buildCategoryFilters(),
                          // const SizedBox(height: 24),  
                          _buildToolbar(compact),
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
                    child: const LoadingShimmer(),
                  ),
                )
              else if (_hasError)
                SliverFillRemaining(
                  child: _buildErrorState(),
                )
              else if (_videos.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else if (_viewMode == _VideoViewMode.grid)
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
                      mainAxisExtent: _gridHeight(width),
                     crossAxisSpacing: 14,
mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final video = _videos[index];

                        return _buildModernVideoCard(video);
                      },
                      childCount: _videos.length,
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
                  sliver: SliverList.separated(
                    itemCount: _videos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final video = _videos[index];

                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 980),
                          child: _buildModernVideoListItem(video),
                        ),
                      );
                    },
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
              Text(
                'Vidéos',
                style: TextStyle(
                  color: _AppColors.text,
                  fontSize: compact ? 30 : 38,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tutoriels, cours vidéo et contenus pédagogiques partagés.',
                style: TextStyle(
                  color: _AppColors.muted,
                  fontSize: compact ? 13.5 : 16,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // if (!compact) 
        // ...[
        //   const SizedBox(width: 16),
        //   _topIconButton(Icons.notifications_none_rounded),
        //   const SizedBox(width: 10),
        //   _topIconButton(Icons.dark_mode_outlined),
        //   const SizedBox(width: 10),
        //   Container(
        //     height: 48,
        //     padding: const EdgeInsets.symmetric(horizontal: 12),
        //     decoration: BoxDecoration(
        //       color: Colors.white,
        //       borderRadius: BorderRadius.circular(16),
        //       border: Border.all(color: _AppColors.border),
        //       boxShadow: _AppShadows.soft,
        //     ),
        //     child: const Row(
        //       children: [
        //         CircleAvatar(
        //           radius: 15,
        //           backgroundColor: _AppColors.primarySoft,
        //           child: Text(
        //             'M',
        //             style: TextStyle(
        //               color: _AppColors.primary,
        //               fontWeight: FontWeight.w900,
        //             ),
        //           ),
        //         ),
        //         SizedBox(width: 8),
        //         Icon(
        //           Icons.keyboard_arrow_down_rounded,
        //           color: _AppColors.muted,
        //         ),
        //       ],
        //     ),
        //   ),
        // ],
      
      
      ],
    );
  }

  Widget _topIconButton(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.border),
        boxShadow: _AppShadows.soft,
      ),
      child: Icon(
        icon,
        color: _AppColors.text,
        size: 22,
      ),
    );
  }

  Widget _buildSearchAndPrimaryAction(bool compact) {
    final search = TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _loadVideos(),
      style: const TextStyle(
        color: _AppColors.text,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'Rechercher une vidéo, un sujet, un auteur...',
        hintStyle: const TextStyle(
          color: _AppColors.placeholder,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _AppColors.text,
          size: 25,
        ),
        suffixIcon: _hasSearch
            ? IconButton(
                tooltip: 'Effacer',
                onPressed: () {
                  _searchController.clear();
                  _loadVideos();
                },
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: _AppColors.primary,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );

    final addButton = ElevatedButton.icon(
      onPressed: () => context.go('/videos/upload'),
      icon: const Icon(Icons.add_rounded, size: 22),
      label: const Text('Ajouter une vidéo'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(190, 58),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    if (compact) {
      return Column(
        children: [
          search,
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: addButton,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: search),
        const SizedBox(width: 18),
        addButton,
      ],
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _categoryChip(null),
          const SizedBox(width: 10),
          ..._categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _categoryChip(category),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String? category) {
    final selected = _selectedCategory == category;
    final color = _categoryColor(category);

    return InkWell(
      onTap: () => _setCategory(category),
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: selected ? _AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? _AppColors.primary : _AppColors.border,
          ),
          boxShadow: selected ? _AppShadows.primary : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.14) : color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                _categoryIcon(category),
                size: 15,
                color: selected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              _categoryLabel(category),
              style: TextStyle(
                color: selected ? Colors.white : _AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(bool compact) {
    final savedCount = _savedVideoIds.length;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _resultText(),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _viewButton(
                  icon: Icons.grid_view_rounded,
                  selected: _viewMode == _VideoViewMode.grid,
                  onTap: () => setState(() => _viewMode = _VideoViewMode.grid),
                ),
                const SizedBox(width: 8),
                _viewButton(
                  icon: Icons.view_list_rounded,
                  selected: _viewMode == _VideoViewMode.list,
                  onTap: () => setState(() => _viewMode = _VideoViewMode.list),
                ),
                const SizedBox(width: 8),
                _sortButton(),
                const SizedBox(width: 8),
                _filterButton(),
                const SizedBox(width: 8),
                _refreshButton(),
                const SizedBox(width: 8),
                _statPill('Favoris', '$savedCount'),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _resultText()),
        _viewButton(
          icon: Icons.grid_view_rounded,
          selected: _viewMode == _VideoViewMode.grid,
          onTap: () => setState(() => _viewMode = _VideoViewMode.grid),
        ),
        const SizedBox(width: 8),
        _viewButton(
          icon: Icons.view_list_rounded,
          selected: _viewMode == _VideoViewMode.list,
          onTap: () => setState(() => _viewMode = _VideoViewMode.list),
        ),
        const SizedBox(width: 14),
        _sortButton(),
        const SizedBox(width: 10),
        _filterButton(),
        const SizedBox(width: 10),
        _refreshButton(),
      ],
    );
  }

  Widget _resultText() {
    return Text(
      '${_videos.length} vidéo(s) trouvée(s)'
      '${_loadedVideos.length != _videos.length ? ' sur ${_loadedVideos.length}' : ''}',
      style: const TextStyle(
        color: _AppColors.muted,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _viewButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: selected ? 'Vue ${_viewLabel()}' : 'Changer la vue',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: selected ? _AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? _AppColors.primary : _AppColors.border,
            ),
            boxShadow: selected ? _AppShadows.primary : _AppShadows.soft,
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

  Widget _sortButton() {
    return PopupMenuButton<_VideoSortMode>(
      tooltip: 'Trier',
      onSelected: _changeSort,
      color: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      itemBuilder: (context) => [
        _sortItem(
          _VideoSortMode.newest,
          'Plus récent',
          Icons.schedule_rounded,
        ),
        _sortItem(
          _VideoSortMode.title,
          'Titre A-Z',
          Icons.sort_by_alpha_rounded,
        ),
      ],
      child: _toolbarButtonShell(
        icon: Icons.swap_vert_rounded,
        label: _sortLabel(),
      ),
    );
  }

  PopupMenuItem<_VideoSortMode> _sortItem(
    _VideoSortMode mode,
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
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? _AppColors.primary : _AppColors.text,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          if (selected)
            const Icon(
              Icons.check_rounded,
              color: _AppColors.primary,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _filterButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: _openFilterSheet,
          borderRadius: BorderRadius.circular(15),
          child: _toolbarButtonShell(
            icon: Icons.filter_alt_outlined,
            label: 'Filtres',
            selected: _activeFilterCount > 0,
          ),
        ),
        if (_activeFilterCount > 0)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                color: _AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Center(
                child: Text(
                  '$_activeFilterCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _refreshButton() {
    return Tooltip(
      message: 'Actualiser',
      child: InkWell(
        onTap: _loadVideos,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _AppColors.border),
            boxShadow: _AppShadows.soft,
          ),
          child: const Icon(
            Icons.refresh_rounded,
            color: _AppColors.muted,
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget _toolbarButtonShell({
    required IconData icon,
    required String label,
    bool selected = false,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: selected ? _AppColors.primarySoft : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected ? _AppColors.primary.withOpacity(0.18) : _AppColors.border,
        ),
        boxShadow: _AppShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selected ? _AppColors.primary : _AppColors.muted,
            size: 19,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: selected ? _AppColors.primary : _AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _AppColors.border),
        boxShadow: _AppShadows.soft,
      ),
      child: Center(
        child: Text(
          '$label: $value',
          style: const TextStyle(
            color: _AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

 Widget _buildModernVideoCard(Video video) {
  final saved = _savedVideoIds.contains(video.id.toString());
  final hasThumbnail = video.thumbnailUrl.trim().isNotEmpty;
  final category = _selectedCategory;

  return Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: () => context.go('/videos/${video.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(
                    height: 112,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasThumbnail)
                          Image.network(
                            video.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallbackThumbnail(),
                          )
                        else
                          _fallbackThumbnail(),

                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.02),
                                Colors.black.withOpacity(0.28),
                              ],
                            ),
                          ),
                        ),

                        Center(
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.48),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 27,
                            ),
                          ),
                        ),

                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.72),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Text(
                              'VIDÉO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _AppColors.text,
                            fontSize: 13.5,
                            height: 1.18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          video.description.trim().isEmpty
                              ? 'Cliquez pour découvrir cette ressource vidéo.'
                              : video.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _AppColors.muted,
                            fontSize: 11.5,
                            height: 1.25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const Spacer(),

                        Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: _AppColors.primarySoft,
                              child: Text(
                                video.title.isEmpty
                                    ? 'V'
                                    : video.title[0].toUpperCase(),
                                style: const TextStyle(
                                  color: _AppColors.primary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),

                            const SizedBox(width: 6),

                            Expanded(
                              child: Text(
                                _formatDate(video.createdAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _AppColors.text,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),

                            const Icon(
                              Icons.visibility_rounded,
                              color: _AppColors.muted,
                              size: 14,
                            ),

                            const SizedBox(width: 3),

                            const Text(
                              '0',
                              style: TextStyle(
                                color: _AppColors.muted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 7),

                        _miniCompactCategoryTag(category),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                elevation: 3,
                shadowColor: Colors.black.withOpacity(0.12),
                child: InkWell(
                  onTap: () => _toggleSaved(video),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _AppColors.border),
                    ),
                    child: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: saved ? _AppColors.primary : _AppColors.muted,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _miniCompactCategoryTag(String? category) {
  final color = _categoryColor(category);
  final label = category == null ? 'Vidéo' : _categoryLabel(category);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
} Widget _buildModernVideoListItem(Video video) {
    final saved = _savedVideoIds.contains(video.id.toString());
    final hasThumbnail = video.thumbnailUrl.trim().isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => context.go('/videos/${video.id}'),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _AppColors.border),
            boxShadow: _AppShadows.card,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: SizedBox(
                  width: 150,
                  height: 92,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasThumbnail)
                        Image.network(
                          video.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackThumbnail(),
                        )
                      else
                        _fallbackThumbnail(),
                      Container(
                        color: Colors.black.withOpacity(0.14),
                      ),
                      Center(
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.48),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.description.trim().isEmpty
                          ? 'Cliquez pour découvrir cette ressource vidéo.'
                          : video.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AppColors.muted,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _miniCategoryTag(_selectedCategory),
                        const SizedBox(width: 10),
                        Text(
                          _formatDate(video.createdAt),
                          style: const TextStyle(
                            color: _AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _bookmarkButton(
                saved: saved,
                onTap: () => _toggleSaved(video),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: _AppColors.muted,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackThumbnail() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD6DF),
            Color(0xFFF1ECFF),
          ],
        ),
      ),
      child: Center(
        child: Text(
          'KHEDMAA.COM',
          style: TextStyle(
            color: _AppColors.primary.withOpacity(0.92),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _bookmarkButton({
    required bool saved,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _AppColors.border),
          ),
          child: Icon(
            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: saved ? _AppColors.primary : _AppColors.muted,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _miniCategoryTag(String? category) {
    final color = _categoryColor(category);
    final label = category == null ? 'Vidéo' : _categoryLabel(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _stateCard(
          icon: Icons.videocam_off_rounded,
          title: 'Aucune vidéo trouvée',
          message: _showSavedOnly
              ? 'Aucune vidéo favorite ne correspond aux filtres actuels.'
              : 'Essayez une autre recherche ou une autre catégorie.',
          buttonLabel: 'Réinitialiser',
          onPressed: _resetFilters,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _stateCard(
          icon: Icons.wifi_off_rounded,
          title: 'Erreur de chargement',
          message: 'Vérifiez votre connexion puis réessayez.',
          buttonLabel: 'Réessayer',
          onPressed: _loadVideos,
        ),
      ),
    );
  }

  Widget _stateCard({
    required IconData icon,
    required String title,
    required String message,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 450,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _AppColors.border),
        boxShadow: _AppShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: _AppColors.primarySoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: _AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _AppColors.muted,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh_rounded, size: 19),
            label: Text(buttonLabel),
            style: _primaryButtonStyle(),
          ),
        ],
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void updateSheet(VoidCallback action) {
              setState(action);
              setSheetState(() {});
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                22 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtres',
                    style: TextStyle(
                      color: _AppColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Catégorie',
                    style: TextStyle(
                      color: _AppColors.muted,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      _sheetChip(
                        label: 'Toutes',
                        selected: _selectedCategory == null,
                        onTap: () => updateSheet(() => _selectedCategory = null),
                      ),
                      ..._categories.map(
                        (category) => _sheetChip(
                          label: _categoryLabel(category),
                          selected: _selectedCategory == category,
                          onTap: () => updateSheet(() => _selectedCategory = category),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SwitchListTile(
                    value: _showSavedOnly,
                    onChanged: (value) {
                      updateSheet(() => _showSavedOnly = value);
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: _AppColors.primary,
                    title: const Text(
                      'Afficher seulement les favoris',
                      style: TextStyle(
                        color: _AppColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _resetFilters();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _AppColors.text,
                            side: const BorderSide(color: _AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _loadVideos();
                            _refreshLocalList();
                          },
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

  Widget _sheetChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? _AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _AppColors.primary : _AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _AppColors.muted,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _AppColors {
  static const primary = Color(0xFF15196C);
  static const primarySoft = Color(0xFFEDEEFF);

  static const background = Color(0xFFF7F8FC);
  static const text = Color(0xFF101828);
  static const muted = Color(0xFF667085);
  static const placeholder = Color(0xFF98A2B3);
  static const border = Color(0xFFE4E7EC);
  static const danger = Color(0xFFBA1A1A);
}

class _AppShadows {
  static final soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.035),
      blurRadius: 18,
      offset: const Offset(0, 10),
    ),
  ];

  static final card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.055),
      blurRadius: 24,
      offset: const Offset(0, 14),
    ),
  ];

  static final primary = [
    BoxShadow(
      color: _AppColors.primary.withOpacity(0.22),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
}