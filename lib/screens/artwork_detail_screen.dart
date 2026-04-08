import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/artwork.dart';
import '../providers/art_collection_provider.dart';
import '../utils/constants.dart';
import '../utils/nav_helper.dart';
import '../widgets/artwork_image.dart';
import 'artwork_form_screen.dart';

class ArtworkDetailScreen extends StatefulWidget {
  final ArtWork artwork;

  const ArtworkDetailScreen({super.key, required this.artwork});

  @override
  State<ArtworkDetailScreen> createState() => _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends State<ArtworkDetailScreen> {
  int _currentImageIndex = 0;

  ArtWork get artwork => widget.artwork;

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
    navigateWithProvider(
      context,
      ArtworkFormScreen(artwork: artwork),
      slideRight: true,
    );
  }

  void _openImageViewer(BuildContext context, {int index = 0}) {
    if (!artwork.hasImages) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) =>
            _FullScreenImageViewer(imagePaths: artwork.imagePaths, initialIndex: index),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
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
              background: artwork.hasImages
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: artwork.imagePaths.length,
                          onPageChanged: (i) => setState(() => _currentImageIndex = i),
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => _openImageViewer(context, index: i),
                            child: i == 0
                                ? Hero(
                                    tag: 'artwork_${artwork.id}',
                                    child: ArtworkImage(
                                      imagePath: artwork.imagePaths[i],
                                      fit: BoxFit.contain,
                                      iconSize: 64,
                                    ),
                                  )
                                : ArtworkImage(
                                    imagePath: artwork.imagePaths[i],
                                    fit: BoxFit.contain,
                                    iconSize: 64,
                                  ),
                          ),
                        ),
                        if (artwork.imagePaths.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(artwork.imagePaths.length, (i) =>
                                Container(
                                  width: i == _currentImageIndex ? 8 : 6,
                                  height: i == _currentImageIndex ? 8 : 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == _currentImageIndex
                                        ? AppColors.textPrimary
                                        : AppColors.textTertiary.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : const ArtworkImage(imagePath: null, iconSize: 64),
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
                  _buildDetailRow('Formato', artwork.formato),
                  if (artwork.technique.isNotEmpty) ...[
                    _buildDivider(),
                    _buildDetailRow('Técnica', artwork.technique),
                  ],
                  if (artwork.isArtePopular && artwork.rama.isNotEmpty) ...[
                    _buildDivider(),
                    _buildDetailRow('Rama', artwork.rama),
                  ],
                  if (artwork.country.isNotEmpty) ...[
                    _buildDivider(),
                    _buildDetailRow('Comunidad', [
                      artwork.country,
                      if (artwork.state.isNotEmpty) artwork.state,
                      if (artwork.locality.isNotEmpty) artwork.locality,
                    ].join(', ')),
                  ],
                  if (artwork.purchasePlace.isNotEmpty) ...[
                    _buildDivider(),
                    _buildDetailRow('Lugar de compra', artwork.purchasePlace),
                  ],
                  if (artwork.comments.isNotEmpty) ...[
                    _buildDivider(),
                    _buildDetailRow('Comentarios', artwork.comments),
                  ],

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
            color: AppColors.background.withValues(alpha: 0.85),
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
            color: AppColors.background.withValues(alpha: 0.85),
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

/// Fullscreen image viewer with zoom, pan, and swipe between images.
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const _FullScreenImageViewer({required this.imagePaths, this.initialIndex = 0});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformController = TransformationController();
  late AnimationController _animController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_animation != null) {
          _transformController.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    final currentScale = _transformController.value.getMaxScaleOnAxis();

    Matrix4 endMatrix;
    if (currentScale > 1.1) {
      endMatrix = Matrix4.identity();
    } else {
      endMatrix = Matrix4.identity()
        ..translate(position.dx * -1.5, position.dy * -1.5)
        ..scale(2.5);
    }

    _animation = Matrix4Tween(
      begin: _transformController.value,
      end: endMatrix,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = widget.imagePaths.length > 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.transparent),
          ),

          // Swipeable images with zoom
          Center(
            child: GestureDetector(
              onDoubleTapDown: (d) => _doubleTapDetails = d,
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.5,
                maxScale: 5.0,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.imagePaths.length,
                    onPageChanged: (i) => setState(() {
                      _currentIndex = i;
                      _transformController.value = Matrix4.identity();
                    }),
                    itemBuilder: (_, i) => ArtworkImage(
                      imagePath: widget.imagePaths[i],
                      fit: BoxFit.contain,
                      iconSize: 64,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Counter
          if (hasMultiple)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imagePaths.length}',
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 22, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
