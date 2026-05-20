import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/app_update/presentation/widgets/app_update_host.dart';
import 'features/ota_update/presentation/widgets/ota_update_host.dart';

class NaganoorApp extends ConsumerWidget {
  const NaganoorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return OtaUpdateHost(
      child: AppUpdateHost(
        child: MaterialApp.router(
          title: 'Naganoor Village App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
  }
}
