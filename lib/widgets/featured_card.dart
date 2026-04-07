import 'package:flutter/material.dart';
import '../models/artwork.dart';
import '../utils/constants.dart';
import 'artwork_image.dart';

class FeaturedCard extends StatelessWidget {
  final ArtWork artwork;
  final VoidCallback onTap;

  const FeaturedCard({
    super.key,
    required this.artwork,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area — full thumbnail, not cropped
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: ArtworkImage(
                  imagePath: artwork.imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(
                    artwork.author,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    artwork.year != null
                        ? '${artwork.modality} \u00B7 ${artwork.year}'
                        : artwork.modality,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
