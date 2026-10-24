import 'package:flutter/material.dart';

/// Static placeholders avoid decorative animation during network-bound startup.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading profile',
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, size) => SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: size.maxHeight * .5,
                color: const Color(0xFFF1F3F5),
              ),
              const SizedBox(height: 24),
              const _Bone(width: 180, height: 28),
              const SizedBox(height: 12),
              const _Bone(width: 120, height: 16),
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _Bone(height: 48),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(child: _Bone(height: 150)),
                    SizedBox(width: 12),
                    Expanded(child: _Bone(height: 150)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Bone extends StatelessWidget {
  const _Bone({this.width, required this.height});
  final double? width;
  final double height;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFE9EDF0),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
