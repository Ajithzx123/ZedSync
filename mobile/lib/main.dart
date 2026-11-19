import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_bindings.dart';
import 'ui/core/theme.dart';
import 'ui/shell.dart';

void main() {
  runApp(const ZedSyncApp());
}

class ZedSyncApp extends StatelessWidget {
  const ZedSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ZedSync Trading Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialBinding: AppBindings(),
      home: const AppShell(),
    );
  }
}
