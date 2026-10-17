import 'app/brand_licenses.dart';

import 'package:flutter/material.dart';

import 'app/theme/paths_theme.dart';
import 'app/experiment_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerBrandLicenses();
  runApp(const PathsExperimentApp());
}

class PathsExperimentApp extends StatefulWidget {
  const PathsExperimentApp({super.key});
  @override
  State<PathsExperimentApp> createState() => _PathsExperimentAppState();
}

class _PathsExperimentAppState extends State<PathsExperimentApp> {
  late final _router = createRouter();
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Paths · Private experiment',
    theme: PathsTheme.light.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF5FBFF),
      colorScheme: PathsTheme.light.colorScheme.copyWith(
        surface: const Color(0xFFF5FBFF),
      ),
      textButtonTheme: const TextButtonThemeData(),
    ),
    routerConfig: _router,
  );
}
