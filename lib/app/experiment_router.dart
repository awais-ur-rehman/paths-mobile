import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/platform/location_tracker.dart';
import '../features/experiment/data/experiment_api.dart';
import '../features/experiment/presentation/experiment_cubit.dart';
import '../features/experiment/presentation/experiment_screen.dart';

GoRouter createRouter() => GoRouter(
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
