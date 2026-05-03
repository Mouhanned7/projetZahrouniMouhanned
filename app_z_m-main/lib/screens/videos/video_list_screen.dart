import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../models/video.dart';
import '../../services/video_service.dart';
import '../../widgets/video_card.dart';
import '../../widgets/loading_shimmer.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final _videoService = VideoService();
  final _searchController = TextEditingController();
  List<Video> _videos = [];
  bool _isLoading = true;
  String? _selectedCategory;

  final List<String> _categories = [
    'Programmation', 'Mathématiques', 'Physique', 'Design',
    'Marketing', 'Langues', 'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    try {
      final videos = await _videoService.getPublicVideos(
        category: _selectedCategory,
        searchQuery: _searchController.text,
      );
      if (mounted) setState(() { _videos = videos; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🎬 Vidéos',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tutoriels et cours vidéo de la communauté',
                              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/videos/upload'),
                        icon: const Icon(Icons.videocam_rounded, size: 18),
                        label: const Text('Ajouter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _loadVideos(),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Rechercher des vidéos...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.4)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Category chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip(null, 'Toutes'),
                        ..._categories.map((c) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildCategoryChip(c, c),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: LoadingShimmer())
          else if (_videos.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_off_rounded, size: 64, color: Colors.white.withOpacity(0.15)),
                    const SizedBox(height: 16),
                    Text('Aucune vidéo trouvée', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 380,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => VideoCard(
                    video: _videos[index],
                    onTap: () => context.go('/videos/${_videos[index].id}'),
                  ),
                  childCount: _videos.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
        _loadVideos();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.secondaryColor : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppTheme.secondaryColor : Colors.white.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
