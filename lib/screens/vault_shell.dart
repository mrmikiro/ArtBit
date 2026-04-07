import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/art_collection_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'obras_screen.dart';
import 'explore_screen.dart';
import 'artwork_form_screen.dart';

class VaultShell extends StatefulWidget {
  const VaultShell({super.key});

  @override
  State<VaultShell> createState() => _VaultShellState();
}

class _VaultShellState extends State<VaultShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ObrasScreen(),
    ExploreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArtCollectionProvider>().loadArtworks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Banner negro
          Container(
            color: const Color(0xFF1C1B1A),
            child: SafeArea(
              bottom: false,
              child: _buildBanner(),
            ),
          ),

          // Nav gris (pegado al banner, sin gap)
          _buildTopNav(),

          // Content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final provider = context.read<ArtCollectionProvider>();
          Navigator.of(context).push(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 350),
              reverseTransitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ChangeNotifierProvider.value(
                    value: provider,
                    child: const ArtworkFormScreen(),
                  ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(curved),
                  child: FadeTransition(opacity: curved, child: child),
                );
              },
            ),
          );
        },
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo_vault.png',
            height: 72,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          Consumer<ArtCollectionProvider>(
            builder: (context, provider, _) {
              final user = FirebaseAuth.instance.currentUser;
              final firstName = (user?.displayName ?? '').split(' ').first;
              final label = firstName.isNotEmpty
                  ? 'Colección de $firstName'
                  : 'Tu colección personal';

              return Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.right,
              );
            },
          ),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: () => AuthService().signOut(),
            child: Icon(
              Icons.logout_rounded,
              size: 20,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNav() {
    return Container(
      color: const Color(0xFF4A4845),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Inicio',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'Colección',
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore_rounded,
            label: 'Explorar',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 18,
                color: isActive
                    ? AppColors.navBarActive
                    : AppColors.navBarInactive,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? AppColors.navBarActive
                      : AppColors.navBarInactive,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
