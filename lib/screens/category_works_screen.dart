import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/artwork.dart';
import '../providers/art_collection_provider.dart';
import '../utils/constants.dart';
import '../utils/nav_helper.dart';
import '../widgets/obra_list_tile.dart';
import 'artwork_detail_screen.dart';

class CategoryWorksScreen extends StatelessWidget {
  final String title;
  final String categoryType;
  final String categoryValue;

  const CategoryWorksScreen({
    super.key,
    required this.title,
    required this.categoryType,
    required this.categoryValue,
  });

  List<ArtWork> _getWorks(ArtCollectionProvider provider) {
    switch (categoryType) {
      case 'author':
        return provider.getWorksByAuthor(categoryValue);
      case 'modality':
        return provider.getWorksByModality(categoryValue);
      case 'technique':
        return provider.getWorksByTechnique(categoryValue);
      case 'movement':
        return provider.getWorksByMovement(categoryValue);
      default:
        return [];
    }
  }

  String get _categoryLabel {
    switch (categoryType) {
      case 'author':
        return 'Autor';
      case 'modality':
        return 'Modalidad';
      case 'technique':
        return 'Técnica';
      case 'movement':
        return 'Corriente';
      default:
        return '';
    }
  }

  void _navigateToDetail(BuildContext context, ArtWork artwork) {
    navigateWithProvider(context, ArtworkDetailScreen(artwork: artwork));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<ArtCollectionProvider>(
        builder: (context, provider, _) {
          final works = _getWorks(provider);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoryLabel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.8,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${works.length} ${works.length == 1 ? 'obra' : 'obras'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(
                height: 0.5,
                thickness: 0.5,
                color: AppColors.divider,
              ),

              // List
              Expanded(
                child: AnimationLimiter(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl,
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
                              onTap: () => _navigateToDetail(context, artwork),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
