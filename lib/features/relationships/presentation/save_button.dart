import 'package:flutter/material.dart';

import '../../../shared/widgets/paths_loader.dart';
import '../../../shared/widgets/paths_toast.dart';
import '../data/relationship_repository.dart';

class SaveButton extends StatefulWidget {
  const SaveButton({
    required this.repository,
    required this.target,
    required this.saved,
    super.key,
  });
  final RelationshipRepository repository;
  final String target;
  final bool saved;
  @override
  State<SaveButton> createState() => _SaveState();
}

class _SaveState extends State<SaveButton> {
  late bool saved = widget.saved;
  bool busy = false;
  @override
  void didUpdateWidget(covariant SaveButton old) {
    super.didUpdateWidget(old);
    if (old.saved != widget.saved && !busy) saved = widget.saved;
  }

  Future<void> toggle() async {
    if (busy) return;
    final account = widget.repository.accountId, before = saved;
    setState(() {
      busy = true;
      saved = !saved;
    });
    try {
      final result = await widget.repository.save(widget.target, saved);
      if (mounted && account == widget.repository.accountId) {
        setState(() => saved = result.saved);
      }
    } catch (_) {
      if (mounted && account == widget.repository.accountId) {
        setState(() => saved = before);
        PathsToast.show(context, 'Could not save. Retry.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: saved ? 'Remove saved profile' : 'Save profile',
    onPressed: busy ? null : toggle,
    icon: busy
        ? const PathsLoader(size: 24)
        : Icon(saved ? Icons.bookmark : Icons.bookmark_outline),
  );
}
