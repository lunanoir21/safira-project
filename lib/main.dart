import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Linux window configuration
  if (Platform.isLinux) {
    await _setupLinuxWindow();
  }

  runApp(
    const ProviderScope(
      child: SafiraApp(),
    ),
  );
}

/// Configures the native Linux window size and title bar.
Future<void> _setupLinuxWindow() async {
  // Import window_manager and bitsdojo_window in production:
  // await windowManager.ensureInitialized();
  // WindowOptions windowOptions = const WindowOptions(
  //   size: Size(1200, 800),
  //   minimumSize: Size(600, 500),
  //   center: true,
  //   title: 'Safira',
  //   titleBarStyle: TitleBarStyle.hidden,
  // );
  // await windowManager.waitUntilReadyToShow(windowOptions);
  // await windowManager.show();
  // await windowManager.focus();
}
