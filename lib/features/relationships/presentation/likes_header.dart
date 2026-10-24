import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_icon.dart';
import 'likes_cubit.dart';

class LikesHeader extends StatelessWidget {
  const LikesHeader({required this.cubit, required this.controller, super.key});
  final LikesCubit cubit;
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Likes',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            onChanged: cubit.search,
            maxLength: 100,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search name or username',
              counterText: '',
              prefixIcon: const Padding(
                padding: EdgeInsets.all(14),
                child: PathsIcon(PathsIconName.search, size: 20),
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          controller.clear();
                          cubit.search('');
                        },
                        icon: Transform.rotate(
                          angle: math.pi / 4,
                          child: const PathsIcon(PathsIconName.plus, size: 20),
                        ),
                      ),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          BlocSelector<LikesCubit, LikesState, LikesCriteria>(
            bloc: cubit,
            selector: (s) => s.criteria,
            builder: (context, criteria) {
              final buttons = [
                for (final (box, label) in [
                  ('saved', 'Saved'),
                  ('incoming', 'Requests'),
                  ('sent', 'Sent'),
                  ('connections', 'Connected'),
                ])
                  _SectionButton(
                    label: label,
                    selected: criteria.box == box,
                    onTap: () => cubit.load(box: box),
                  ),
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (MediaQuery.textScalerOf(context).scale(1) > 1.3)
                    Wrap(spacing: 8, runSpacing: 8, children: buttons)
                  else
                    Row(
                      children: [
                        for (final button in buttons) Expanded(child: button),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Filter(
                        label: 'Verified',
                        selected: criteria.verifiedOnly,
                        icon: PathsIconName.verified,
                        onSelected: (value) =>
                            cubit.filter(verifiedOnly: value),
                      ),
                      if (criteria.box == 'incoming' || criteria.box == 'sent')
                        _Filter(
                          label: 'Pending only',
                          selected: criteria.pendingOnly,
                          onSelected: (value) =>
                              cubit.filter(pendingOnly: value),
                        ),
                      if (criteria.query.isNotEmpty ||
                          criteria.verifiedOnly ||
                          ((criteria.box == 'incoming' ||
                                  criteria.box == 'sent') &&
                              criteria.pendingOnly))
                        TextButton(
                          onPressed: () {
                            controller.clear();
                            cubit.resetFilters();
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: Color(0xFF0B5AA1)),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _SectionButton extends StatelessWidget {
  const _SectionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected
                  ? const Color(0xFF0B5AA1)
                  : const Color(0xFFE8EDF1),
              width: selected ? 2 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF0B5AA1) : const Color(0xFF52616D),
          ),
        ),
      ),
    ),
  );
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final PathsIconName? icon;
  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    avatar: icon == null
        ? null
        : PathsIcon(
            icon!,
            size: 17,
            color: selected ? Colors.white : const Color(0xFF52616D),
          ),
    selected: selected,
    onSelected: onSelected,
    showCheckmark: false,
    selectedColor: const Color(0xFF0B5AA1),
    backgroundColor: const Color(0xFFF5F5F5),
    side: BorderSide.none,
    shape: const StadiumBorder(),
    labelStyle: TextStyle(
      color: selected ? Colors.white : const Color(0xFF52616D),
      fontSize: 13,
    ),
  );
}
