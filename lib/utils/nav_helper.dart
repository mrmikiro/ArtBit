import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/art_collection_provider.dart';

/// Navigates to a screen while preserving the ArtCollectionProvider context
void navigateWithProvider(
  BuildContext context,
  Widget child, {
  Duration duration = const Duration(milliseconds: 350),
  Duration reverseDuration = const Duration(milliseconds: 300),
  bool slideUp = false,
  bool slideRight = false,
}) {
  final provider = context.read<ArtCollectionProvider>();

  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) =>
          ChangeNotifierProvider.value(
        value: provider,
        child: child,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        if (slideUp) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        }

        if (slideRight) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        }

        return FadeTransition(opacity: curved, child: child);
      },
    ),
  );
}
