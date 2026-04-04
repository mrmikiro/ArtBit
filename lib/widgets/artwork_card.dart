import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/artwork.dart';
import '../utils/constants.dart';

class ArtworkCard extends StatelessWidget {
  final ArtWork artwork;
  final VoidCallback onTap;

  const ArtworkCard({
    super.key,
    required this.artwork,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'artwork_${artwork.id}',
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: artwork.imagePath != null
                      ? (kIsWeb
                          ? Image.network(
                              artwork.imagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholder(),
                            )
                          : Image.file(
                              File(artwork.imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholder(),
                            ))
                      : _buildPlaceholder(),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Title
              Text(
                artwork.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 2),

              // Author
              Text(
                artwork.author,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        Icons.image_outlined,
        size: 32,
        color: AppColors.textTertiary,
      ),
    );
  }
}
