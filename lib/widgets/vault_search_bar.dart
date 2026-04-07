import 'package:flutter/material.dart';
import '../utils/constants.dart';

class VaultSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const VaultSearchBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.chipBackground,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: AppColors.borderLight,
            width: 0.5,
          ),
        ),
        child: const Row(
          children: [
            SizedBox(width: 16),
            Icon(
              Icons.search,
              size: 20,
              color: AppColors.textTertiary,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Buscar obra, autor o técnica',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
