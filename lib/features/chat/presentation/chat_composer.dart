import 'package:flutter/material.dart';

import '../../../shared/widgets/paths_icon.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    required this.controller,
    required this.onSend,
    super.key,
  });
  final TextEditingController controller;
  final VoidCallback onSend;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD8E4EC)),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 4000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Your message',
                    counterText: '',
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) => IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: value.text.trim().isEmpty ? null : onSend,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF0B5AA1),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE5EDF3),
                      disabledForegroundColor: const Color(0xFF52616D),
                      minimumSize: const Size(48, 48),
                      shape: const CircleBorder(),
                    ),
                    icon: const PathsIcon(PathsIconName.send, size: 23),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
