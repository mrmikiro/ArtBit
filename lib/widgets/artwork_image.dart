import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/constants.dart';

/// Shared widget that renders artwork images from any source:
/// asset paths, HTTP URLs, local file paths, and web blob URLs.
class ArtworkImage extends StatelessWidget {
  final String? imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double iconSize;

  const ArtworkImage({
    super.key,
    this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildPlaceholder();
    }

    final path = imagePath!;

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        width: width ?? double.infinity,
        height: height,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: fit,
        width: width ?? double.infinity,
        height: height,
        placeholder: (_, __) => _buildLoadingPlaceholder(),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      );
    }

    if (!kIsWeb) {
      return Image.file(
        File(path),
        fit: fit,
        width: width ?? double.infinity,
        height: height,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    // Web blob URLs or other network-like paths
    return Image.network(
      path,
      fit: fit,
      width: width ?? double.infinity,
      height: height,
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.chipBackground,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: iconSize,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.chipBackground,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
