import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/art_collection_provider.dart';
import '../utils/constants.dart';
import '../widgets/artwork_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chips_bar.dart';
import '../widgets/empty_state.dart';
import 'artwork_detail_screen.dart';
import 'artwork_form_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArtCollectionProvider>().loadArtworks();
    });
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _navigateToDetail(artwork) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ArtworkDetailScreen(artwork: artwork),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToAddForm() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ArtworkFormScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(
              opacity: curved,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            const SizedBox(height: AppSpacing.md),

            // Search bar
            Consumer<ArtCollectionProvider>(
              builder: (context, provider, _) => ArtBitSearchBar(
                initialQuery: provider.searchQuery,
                onChanged: provider.setSearchQuery,
                onFilterTap: _toggleFilters,
                hasActiveFilters: provider.hasActiveFilters,
              ),
            ),

            // Filters
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showFilters ? _buildFilters() : const SizedBox.shrink(),
            ),

            const SizedBox(height: AppSpacing.md),

            // Results count
            _buildResultsCount(),

            const SizedBox(height: AppSpacing.sm),

            // Grid
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ArtBit',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 2),
          Consumer<ArtCollectionProvider>(
            builder: (context, provider, _) => Text(
              provider.totalCount == 0
                  ? 'Tu colección personal'
                  : '${provider.totalCount} ${provider.totalCount == 1 ? 'obra' : 'obras'} en tu colección',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Consumer<ArtCollectionProvider>(
      builder: (context, provider, _) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clear filters button
            if (provider.hasActiveFilters)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  bottom: AppSpacing.sm,
                ),
                child: GestureDetector(
                  onTap: provider.clearFilters,
                  child: const Text(
                    'Limpiar filtros',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

            // Author filter
            if (provider.authors.isNotEmpty) ...[
              FilterChipsBar(
                label: 'Autor',
                options: provider.authors,
                selectedValue: provider.filterAuthor,
                onSelected: provider.setFilterAuthor,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Technique filter
            if (provider.techniques.isNotEmpty) ...[
              FilterChipsBar(
                label: 'Técnica',
                options: provider.techniques,
                selectedValue: provider.filterTechnique,
                onSelected: provider.setFilterTechnique,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Modality filter
            if (provider.modalities.isNotEmpty)
              FilterChipsBar(
                label: 'Modalidad',
                options: provider.modalities,
                selectedValue: provider.filterModality,
                onSelected: provider.setFilterModality,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCount() {
    return Consumer<ArtCollectionProvider>(
      builder: (context, provider, _) {
        if (provider.totalCount == 0) return const SizedBox.shrink();

        final showingFiltered = provider.filteredCount != provider.totalCount;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            showingFiltered
                ? '${provider.filteredCount} resultado${provider.filteredCount == 1 ? '' : 's'}'
                : '',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid() {
    return Consumer<ArtCollectionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.textSecondary,
            ),
          );
        }

        if (provider.totalCount == 0) {
          return const EmptyState(
            title: 'Comienza tu colección',
            subtitle:
                'Agrega tu primera obra de arte\npresionando el botón +',
          );
        }

        if (provider.filteredCount == 0) {
          return const EmptyState(
            title: 'Sin resultados',
            subtitle: 'Intenta con otros términos\no ajusta los filtros',
            icon: Icons.search_off,
          );
        }

        return AnimationLimiter(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              100,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.lg,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.72,
            ),
            itemCount: provider.filteredCount,
            itemBuilder: (context, index) {
              final artwork = provider.artworks[index];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                columnCount: 2,
                duration: const Duration(milliseconds: 400),
                child: FadeInAnimation(
                  child: SlideAnimation(
                    verticalOffset: 30,
                    child: ArtworkCard(
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

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _navigateToAddForm,
      backgroundColor: AppColors.textPrimary,
      elevation: 2,
      highlightElevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
