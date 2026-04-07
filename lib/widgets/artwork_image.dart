import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/constants.dart';

/// Shared widget that renders artwork images from any source:
/// asset paths, HTTP URLs, base64 data URIs, local file paths, and web blob URLs.
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

    // Base64 data URI (persisted web images)
    if (path.startsWith('data:image/')) {
      try {
        final comma = path.indexOf(',');
        if (comma == -1) return _buildPlaceholder();
        final b64 = path.substring(comma + 1);
        final bytes = base64Decode(b64);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: fit,
          width: width ?? double.infinity,
          height: height,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      } catch (_) {
        return _buildPlaceholder();
      }
    }

    // Flutter asset
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        width: width ?? double.infinity,
        height: height,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    // HTTP/HTTPS URL (Firebase Storage, etc.)
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

    // Local file (mobile)
    if (!kIsWeb) {
      return Image.file(
        File(path),
        fit: fit,
        width: width ?? double.infinity,
        height: height,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    // Web blob URLs or other paths
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
