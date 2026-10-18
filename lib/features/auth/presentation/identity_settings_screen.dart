import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../domain/provider_auth.dart';
import 'provider_auth_cubit.dart';
import 'provider_auth_sheet.dart';
import 'provider_scope.dart';

class IdentitySettingsScreen extends StatefulWidget {
  const IdentitySettingsScreen({super.key});
  @override
  State<IdentitySettingsScreen> createState() => _IdentitySettingsState();
}

class _IdentitySettingsState extends State<IdentitySettingsScreen> {
  ProviderAuthCubit? cubit;
  bool opening = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = ProviderAuthScope.maybeOf(context)!;
    cubit ??= ProviderAuthCubit(
      scope.repository!,
      scope.sdk,
      action: ReauthAction.link,
    )..load();
  }

  @override
  void dispose() {
    unawaited(cubit?.close());
    super.dispose();
  }

  Future<void> add() async {
    if (opening) return;
    setState(() => opening = true);
    final scope = ProviderAuthScope.maybeOf(context)!;
    try {
      final pending = scope.linkOffer.value;
      final valid =
          pending != null &&
          DateTime.parse(pending.expiresAt).isAfter(DateTime.now());
      final result = await showProviderReauth(
        context,
        ReauthAction.link,
        pending: valid ? pending : null,
      );
      if (!mounted || result == null) return;
      if (result['status'] == 'linked') {
        scope.linkOffer.value = null;
        PathsToast.show(
          context,
          'Sign-in method linked',
          tone: ToastTone.success,
        );
      } else if (result['token'] is String) {
        final linked = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => ProviderAuthSheet(
            repository: scope.repository!,
            sdk: scope.sdk,
            linking: true,
            proof: result['token'] as String,
          ),
        );
        if (!mounted) return;
        if (linked?['status'] == 'linked') {
          PathsToast.show(
            context,
            'Sign-in method linked',
            tone: ToastTone.success,
          );
        }
      }
      await cubit!.load();
    } catch (_) {
      if (mounted) {
        PathsToast.show(context, 'Could not link this method. Retry.');
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  Future<void> remove(IdentityProvider provider) async {
    if (opening) return;
    setState(() => opening = true);
    try {
      final proof = await showProviderReauth(context, ReauthAction.unlink);
      if (!mounted || proof?['token'] is! String) return;
      await cubit!.unlink(provider, proof!['token'] as String);
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sign-in methods')),
    body: BlocConsumer<ProviderAuthCubit, ProviderState>(
      bloc: cubit,
      listener: (context, state) {
        if (state.error != null) PathsToast.show(context, state.error!.message);
      },
      builder: (context, state) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (state.busy) const Center(child: PathsLoader()),
            if (state.methods == null && !state.busy)
              TextButton(onPressed: cubit!.load, child: const Text('Retry')),
            if (state.methods?.passwordEnabled == true)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Password'),
                trailing: Icon(Icons.check),
              ),
            for (final provider in IdentityProvider.values)
              if (state.methods?.providers.contains(provider.name) == true)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    provider == IdentityProvider.google ? 'Google' : 'Apple',
                  ),
                  trailing: TextButton(
                    onPressed: state.busy || opening
                        ? null
                        : () => remove(provider),
                    child: const Text('Remove'),
                  ),
                ),
            if (state.config != null)
              FilledButton(
                onPressed: state.busy || opening ? null : add,
                child: const Text('Add sign-in method'),
              ),
          ],
        ),
      ),
    ),
  );
}
