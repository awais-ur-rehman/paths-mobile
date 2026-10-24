import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/paths_icon.dart';

class ProfileSetting {
  const ProfileSetting({
    required this.section,
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });
  final String section, label;
  final PathsIconName icon;
  final VoidCallback onTap;
  final bool destructive;
}

class _SettingsSearch extends Cubit<String> {
  _SettingsSearch() : super('');
  void search(String value) => emit(value.trim().toLowerCase());
}

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({
    required this.entries,
    required this.onBack,
    super.key,
  });
  final List<ProfileSetting> entries;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => _SettingsSearch(),
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: const PathsIcon(PathsIconName.back),
        ),
        centerTitle: true,
        title: const Text(
          'Settings and activity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Builder(
              builder: (context) => TextField(
                onChanged: context.read<_SettingsSearch>().search,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: 'Search settings',
                  counterText: '',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(14),
                    child: PathsIcon(PathsIconName.search, size: 20),
                  ),
                  fillColor: const Color(0xFFF5F5F5),
                  filled: true,
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
            ),
          ),
          Expanded(
            child: BlocBuilder<_SettingsSearch, String>(
              builder: (context, query) {
                final filtered = entries
                    .where(
                      (item) =>
                          query.isEmpty ||
                          '${item.label} ${item.section}'
                              .toLowerCase()
                              .contains(query),
                    )
                    .toList(growable: false);
                if (filtered.isEmpty) {
                  return const Center(child: Text('No settings found'));
                }
                return ListView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 24,
                  ),
                  children: [
                    for (var i = 0; i < filtered.length; i++) ...[
                      if (i == 0 ||
                          filtered[i].section != filtered[i - 1].section) ...[
                        if (i > 0)
                          const Divider(
                            height: 32,
                            thickness: 6,
                            color: Color(0xFFF5F5F5),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
                          child: Text(
                            filtered[i].section,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF52616D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      _SettingRow(entry: filtered[i]),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.entry});
  final ProfileSetting entry;
  @override
  Widget build(BuildContext context) {
    final color = entry.destructive
        ? Theme.of(context).colorScheme.error
        : const Color(0xFF101418);
    return InkWell(
      onTap: entry.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          children: [
            PathsIcon(entry.icon, size: 25, color: color),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                entry.label,
                style: TextStyle(fontSize: 16, color: color),
              ),
            ),
            const SizedBox(width: 12),
            const PathsIcon(
              PathsIconName.chevronRight,
              size: 18,
              color: Color(0xFF77838C),
            ),
          ],
        ),
      ),
    );
  }
}
