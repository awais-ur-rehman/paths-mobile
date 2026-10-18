import 'dart:async';

import 'package:flutter/material.dart';

class ResendCodeControl extends StatefulWidget {
  const ResendCodeControl({
    required this.resendAt,
    required this.expiresAt,
    required this.busy,
    required this.onResend,
    super.key,
  });
  final DateTime resendAt, expiresAt;
  final bool busy;
  final VoidCallback onResend;
  @override
  State<ResendCodeControl> createState() => _ResendState();
}

class _ResendState extends State<ResendCodeControl> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.resendAt.difference(DateTime.now()).inSeconds + 1;
    return Column(
      children: [
        if (!widget.expiresAt.isAfter(DateTime.now()))
          const Text(
            'This code expired. Request a new one.',
            style: TextStyle(color: Color(0xFFB42318)),
          ),
        TextButton(
          onPressed: remaining > 0 || widget.busy ? null : widget.onResend,
          child: Text(
            remaining > 0 ? 'Resend in ${remaining}s' : 'Send a new code',
          ),
        ),
      ],
    );
  }
}
