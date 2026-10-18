import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/paths_theme.dart';
import 'experiment_cubit.dart';

class ExperimentScreen extends StatelessWidget {
  const ExperimentScreen({super.key});
  @override
  Widget build(BuildContext context) => _VisibilityOwner(
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/brand/paths-symbol.png',
                      width: 48,
                      height: 48,
                      semanticLabel: 'Paths',
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'PATHS',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Every connection\nstarts somewhere.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Private location experiment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Paths uses precise location to measure real-world encounters. Samples stay encrypted on this phone unless you explicitly configure the private test server. No public discovery or real accounts are enabled.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Background delivery is best effort. Force-stop, permission changes and battery settings may prevent updates. Pause and sign out purge pending fixes. Pending samples expire after 15 minutes; paired trials need the private server.',
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: PathsTheme.aqua.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlocSelector<ExperimentCubit, ExperimentState, String>(
                        selector: (s) => s.status,
                        builder: (c, status) => Text(
                          status,
                          semanticsLabel: 'Tracking status: $status',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      BlocSelector<ExperimentCubit, ExperimentState, int>(
                        selector: (s) => s.count,
                        builder: (c, count) =>
                            Text('$count pending samples · maximum 200'),
                      ),
                      BlocSelector<ExperimentCubit, ExperimentState, bool?>(
                        selector: (s) => s.matched,
                        builder: (c, matched) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            matched == null
                                ? 'Pair test not connected'
                                : matched
                                ? 'Qualifying evidence recorded for this trial'
                                : 'No qualifying evidence in this trial',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                BlocSelector<ExperimentCubit, ExperimentState, bool>(
                  selector: (s) => s.busy,
                  builder: (context, busy) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () => context.read<ExperimentCubit>().start(
                                background: false,
                              ),
                        child: const Text('Enable foreground experiment'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => context.read<ExperimentCubit>().start(
                                background: true,
                              ),
                        child: const Text('Opt into background experiment'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => context.read<ExperimentCubit>().stop(),
                        child: const Text('Pause & purge'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => context.read<ExperimentCubit>().stop(
                                logout: true,
                              ),
                        child: const Text('Sign out & purge'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => context.read<ExperimentCubit>().refresh(),
                        child: const Text('Refresh evidence counts'),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => context.read<ExperimentCubit>().settings(),
                        child: const Text('Open permission settings'),
                      ),
                    ],
                  ),
                ),
                BlocSelector<ExperimentCubit, ExperimentState, String?>(
                  selector: (s) => s.error,
                  builder: (context, error) => error == null
                      ? const SizedBox.shrink()
                      : Semantics(
                          liveRegion: true,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              error,
                              style: const TextStyle(color: Color(0xFFB42318)),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Phase 0 · adaptive.v1 · brief crossings off\nNo names, coordinates or tokens appear in test reports.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF52616D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _VisibilityOwner extends StatefulWidget {
  const _VisibilityOwner({required this.child});
  final Widget child;
  @override
  State<_VisibilityOwner> createState() => _VisibilityOwnerState();
}

class _VisibilityOwnerState extends State<_VisibilityOwner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => context
      .read<ExperimentCubit>()
      .visibility(state == AppLifecycleState.resumed);
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
