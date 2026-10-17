import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'app/theme/paths_theme.dart';
import 'core/platform/location_tracker.dart';
import 'features/experiment/data/experiment_api.dart';
import 'features/experiment/presentation/experiment_cubit.dart';
import 'features/experiment/presentation/experiment_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PathsExperimentApp());
}

class PathsExperimentApp extends StatefulWidget {
  const PathsExperimentApp({super.key});
  @override
  State<PathsExperimentApp> createState() => _PathsExperimentAppState();
}

class _PathsExperimentAppState extends State<PathsExperimentApp> {
  late final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => BlocProvider(
          create: (_) => ExperimentCubit(
            PlatformLocationTracker(),
            ExperimentApi(
              endpoint: const String.fromEnvironment('PATHS_TEST_ENDPOINT'),
              token: const String.fromEnvironment('PATHS_TEST_TOKEN'),
            ),
          ),
          child: const ExperimentScreen(),
        ),
      ),
    ],
  );
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Paths · Private experiment',
    theme: PathsTheme.light,
    routerConfig: _router,
  );
}
