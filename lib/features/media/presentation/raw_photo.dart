import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class RawPhoto extends StatefulWidget {
  const RawPhoto({required this.bytes, super.key});
  final Uint8List bytes;
  @override
  State<RawPhoto> createState() => _RawPhotoState();
}

class _RawPhotoState extends State<RawPhoto> {
  ui.Image? image;
  bool failed = false;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    final current = ++generation;
    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(
        widget.bytes,
        targetWidth: 800,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      if (!mounted || current != generation) {
        frame.image.dispose();
        return;
      }
      image?.dispose();
      setState(() {
        image = frame.image;
        failed = false;
      });
    } catch (_) {
      if (mounted && current == generation) setState(() => failed = true);
    } finally {
      codec?.dispose();
    }
  }

  @override
  void didUpdateWidget(RawPhoto old) {
    super.didUpdateWidget(old);
    if (old.bytes != widget.bytes) {
      image?.dispose();
      image = null;
      unawaited(load());
    }
  }

  @override
  void dispose() {
    ++generation;
    image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => failed
      ? const Center(child: Text('Photo preview unavailable'))
      : RawImage(image: image, fit: BoxFit.contain);
}
