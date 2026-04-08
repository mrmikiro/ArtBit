import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/art_collection_provider.dart';
import '../utils/constants.dart';
import '../utils/nav_helper.dart';
import '../widgets/section_header.dart';
import '../widgets/category_tile.dart';
import 'category_works_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  void _navigateToCategory(
    BuildContext context, {
    required String title,
    required String categoryType,
    required String categoryValue,
  }) {
    navigateWithProvider(
      context,
      CategoryWorksScreen(
        title: title,
        categoryType: categoryType,
        categoryValue: categoryValue,
      ),
      slideRight: true,
    );
  }

  @override
  Widget build(BuildContext context) {
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

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

                  // Autores
                  if (provider.authors.isNotEmpty) ...[
                    const SectionHeader(title: 'Autores'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCategoryList(
                      context,
                      items: provider.authors,
                      categoryType: 'author',
                      countFn: (val) =>
                          provider.getWorksByAuthor(val).length,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Formatos
                  if (provider.formatos.isNotEmpty) ...[
                    const SectionHeader(title: 'Formatos'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCategoryList(
                      context,
                      items: provider.formatos,
                      categoryType: 'formato',
                      countFn: (val) =>
                          provider.getWorksByFormato(val).length,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Técnicas
                  if (provider.techniques.isNotEmpty) ...[
                    const SectionHeader(title: 'Técnicas'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCategoryList(
                      context,
                      items: provider.techniques,
                      categoryType: 'technique',
                      countFn: (val) =>
                          provider.getWorksByTechnique(val).length,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],

                  if (provider.totalCount == 0)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Center(
                        child: Text(
                          'Agrega obras para explorar\npor categorías',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textTertiary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
    );
  }

  Widget _buildCategoryList(
    BuildContext context, {
    required List<String> items,
    required String categoryType,
    required int Function(String) countFn,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final count = countFn(item);
        return CategoryTile(
          title: item,
          count: count,
          onTap: () => _navigateToCategory(
            context,
            title: item,
            categoryType: categoryType,
            categoryValue: item,
          ),
        );
      },
    );
  }
}
