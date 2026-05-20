import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

/// Startup gate: restores session and routes to the correct home.
class AuthGatePage extends ConsumerWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!next.initialized || next.loading) return;
      final target = next.isLoggedIn ? next.homeRoute : AppRoutePaths.signup;
      if (context.mounted) context.go(target);
    });

    if (auth.initialized && !auth.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(auth.isLoggedIn ? auth.homeRoute : AppRoutePaths.signup);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.sand,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Naganoor Village',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.soil,
                  ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
