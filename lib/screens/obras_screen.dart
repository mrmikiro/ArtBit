import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/art_collection_provider.dart';
import '../utils/constants.dart';
import '../utils/nav_helper.dart';
import '../widgets/obra_list_tile.dart';
import '../widgets/empty_state.dart';
import 'artwork_detail_screen.dart';

class ObrasScreen extends StatefulWidget {
  const ObrasScreen({super.key});

  @override
  State<ObrasScreen> createState() => _ObrasScreenState();
}

class _ObrasScreenState extends State<ObrasScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _localQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToDetail(artwork) {
    navigateWithProvider(context, ArtworkDetailScreen(artwork: artwork));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _buildSearchField(),
            ),

            const SizedBox(height: AppSpacing.md),

            // List
            Expanded(child: _buildList()),
          ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _localQuery = v),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Buscar en tu colección...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (_localQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _localQuery = '');
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.close, size: 18, color: AppColors.textTertiary),
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildList() {
    return Consumer<ArtCollectionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.textTertiary,
            ),
          );
        }

        if (provider.totalCount == 0) {
          return const EmptyState(
            title: 'Sin obras aún',
            subtitle: 'Agrega tu primera obra\npresionando el botón +',
          );
        }

        var works = provider.allArtworks;
        if (_localQuery.isNotEmpty) {
          final q = _localQuery.toLowerCase();
          works = works.where((a) {
            return a.title.toLowerCase().contains(q) ||
                a.author.toLowerCase().contains(q) ||
                a.technique.toLowerCase().contains(q) ||
                a.formato.toLowerCase().contains(q) ||
                a.comments.toLowerCase().contains(q);
          }).toList();
        }

        if (works.isEmpty) {
          return const EmptyState(
            title: 'Sin resultados',
            subtitle: 'Intenta con otros términos',
            icon: Icons.search_off,
          );
        }

        return AnimationLimiter(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, 100,
            ),
            itemCount: works.length,
            separatorBuilder: (_, __) => const Divider(
              height: 0.5,
              thickness: 0.5,
              color: AppColors.divider,
            ),
            itemBuilder: (context, index) {
              final artwork = works[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 350),
                child: FadeInAnimation(
                  child: SlideAnimation(
                    verticalOffset: 20,
                    child: ObraListTile(
                      artwork: artwork,
                      onTap: () => _navigateToDetail(artwork),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
