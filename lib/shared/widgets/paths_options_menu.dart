import 'package:flutter/material.dart';

import 'paths_icon.dart';

class PathsMenuOption<T> {
  const PathsMenuOption(this.value, this.label, this.icon);
  final T value;
  final String label;
  final PathsIconName icon;
}

Future<T?> showPathsOptions<T>(
  BuildContext context,
  List<PathsMenuOption<T>> options,
) => showDialog<T>(
  context: context,
  barrierLabel: 'Close options',
  barrierColor: Colors.black26,
  builder: (context) => Dialog(
    alignment: Alignment.topRight,
    insetPadding: const EdgeInsets.fromLTRB(20, 72, 20, 20),
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in options)
                Semantics(
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context, option.value),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 52),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            PathsIcon(option.icon, size: 22),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                option.label,
                                style: const TextStyle(
                                  color: Color(0xFF101418),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  ),
);
