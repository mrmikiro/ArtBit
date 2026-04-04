import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/artwork.dart';
import '../providers/art_collection_provider.dart';
import '../utils/constants.dart';
import 'artwork_form_screen.dart';

class ArtworkDetailScreen extends StatelessWidget {
  final ArtWork artwork;

  const ArtworkDetailScreen({super.key, required this.artwork});

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        title: const Text(
          'Eliminar obra',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          '¿Estás seguro de eliminar "${artwork.title}"?\nEsta acción no se puede deshacer.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<ArtCollectionProvider>()
                  .deleteArtwork(artwork.id)
                  .then((_) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              });
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ArtworkFormScreen(artwork: artwork),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Image header - 40% of screen
          SliverAppBar(
            expandedHeight: screenHeight * 0.40,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            leading: _buildBackButton(context),
            actions: [
              _buildActionButton(
                icon: Icons.edit_outlined,
                onTap: () => _navigateToEdit(context),
              ),
              _buildActionButton(
                icon: Icons.delete_outline,
                onTap: () => _showDeleteDialog(context),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'artwork_${artwork.id}',
                child: artwork.imagePath != null
                    ? (kIsWeb
                        ? Image.network(
                            artwork.imagePath!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(),
                          )
                        : Image.file(
                            File(artwork.imagePath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(),
                          ))
                    : _buildImagePlaceholder(),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),

                  // Title
                  Text(
                    artwork.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.8,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // Author
                  Text(
                    artwork.author,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.1,
                    ),
                  ),

                  if (artwork.year != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      artwork.year.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // Value
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.lg),
                      border: Border.all(
                        color: AppColors.border,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VALOR ESTIMADO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _formatCurrency(artwork.value),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Details grid
                  _buildDetailRow('Modalidad', artwork.modality),
                  _buildDivider(),
                  _buildDetailRow('Técnica', artwork.technique),
                  _buildDivider(),
                  _buildDetailRow('Corriente', artwork.movement),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.85),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(
            Icons.arrow_back,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.85),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.borderLight,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 64,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textTertiary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 0.5,
      thickness: 0.5,
      color: AppColors.divider,
    );
  }
}
