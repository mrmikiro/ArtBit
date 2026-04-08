import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/art_collection_provider.dart';
import '../utils/constants.dart';
import '../utils/nav_helper.dart';
import '../widgets/vault_search_bar.dart';
import '../widgets/featured_card.dart';
import '../widgets/section_header.dart';
import 'artwork_detail_screen.dart';
import 'artwork_form_screen.dart';
import 'search_results_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: VaultSearchBar(
                  onTap: () => navigateWithProvider(
                    context,
                    const SearchResultsScreen(),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl + AppSpacing.sm),

              // Featured section
              _buildFeaturedSection(context),

              const SizedBox(height: AppSpacing.xl),

              // Collection summary
              _buildCollectionSummary(context),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
    );
  }

  Widget _buildFeaturedSection(BuildContext context) {
    return Consumer<ArtCollectionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.textTertiary,
              ),
            ),
          );
        }

        if (provider.totalCount == 0) {
          return _buildEmptyHome(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Selección curada',
              trailing: GestureDetector(
                onTap: () => provider.refreshFeatured(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Renovar',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.75,
                ),
                itemCount: provider.featuredArtworks.length > 4
                    ? 4
                    : provider.featuredArtworks.length,
                itemBuilder: (context, index) {
                  final artwork = provider.featuredArtworks[index];
                  return FeaturedCard(
                    artwork: artwork,
                    onTap: () => navigateWithProvider(
                      context,
                      ArtworkDetailScreen(artwork: artwork),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyHome(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          Icon(
            Icons.collections_outlined,
            size: 56,
            color: AppColors.textTertiary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Comienza tu colección',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Registra tu primera obra y empieza\na construir tu archivo personal',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textTertiary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: () => navigateWithProvider(
              context,
              const ArtworkFormScreen(),
              slideUp: true,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: const Text(
                'Agregar obra',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionSummary(BuildContext context) {
    return Consumer<ArtCollectionProvider>(
      builder: (context, provider, _) {
        if (provider.totalCount == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(
                color: AppColors.border,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                _buildStat('${provider.totalCount}', 'Obras'),
                Container(width: 0.5, height: 36, color: AppColors.divider),
                _buildStat('${provider.authors.length}', 'Autores'),
                Container(width: 0.5, height: 36, color: AppColors.divider),
                _buildStat('${provider.formatos.length}', 'Formatos'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.textTertiary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
