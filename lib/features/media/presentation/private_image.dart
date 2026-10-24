import 'dart:async';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/http_media_repository.dart';

/// Owns decoded pixels directly; private photos never enter Flutter's global image cache.
class PrivateImage extends StatefulWidget {
  const PrivateImage({
    required this.repository,
    required this.assetId,
    this.thumbnail = true,
    this.fit = BoxFit.cover,
    this.imageBuilder,
    super.key,
  });
  final HttpMediaRepository repository;
  final String assetId;
  final bool thumbnail;
  final BoxFit fit;

  /// Paint only: consumers must not retain or dispose this private frame.
  final Widget Function(BuildContext, ui.Image)? imageBuilder;
  @override
  State<PrivateImage> createState() => _PrivateImageState();
}

class _PrivateImageState extends State<PrivateImage> {
  ui.Image? _image;
  CancelToken? _token;
  int _generation = 0;
  bool _visible = false, _foreground = true;
  late final AppLifecycleListener _lifecycle;
  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_invalidate);
    _lifecycle = AppLifecycleListener(
      onPause: () {
        _foreground = false;
        _clear();
      },
      onHide: () {
        _foreground = false;
        _clear();
      },
      onResume: () {
        _foreground = true;
        _invalidate();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible != _visible) {
      _visible = visible;
      _invalidate();
    }
  }

  void _clear() {
    ++_generation;
    _token?.cancel();
    final old = _image;
    _image = null;
    if (mounted) setState(() {});
    old?.dispose();
  }

  void _invalidate() {
    _clear();
    if (_visible && _foreground && widget.repository.accountId != null) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final generation = ++_generation,
        account = widget.repository.accountId,
        token = _token = CancelToken();
    if (account == null || !_visible || !_foreground) return;
    try {
      final bytes = await widget.repository.bytes(
        widget.assetId,
        thumbnail: widget.thumbnail,
        cancelToken: token,
      );
      ui.Codec? codec;
      try {
        if (!mounted ||
            generation != _generation ||
            account != widget.repository.accountId) {
          return;
        }
        codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: widget.thumbnail ? 320 : 1600,
          allowUpscaling: false,
        );
        final frame = await codec.getNextFrame();
        if (!mounted ||
            generation != _generation ||
            account != widget.repository.accountId) {
          frame.image.dispose();
          return;
        }
        setState(() => _image = frame.image);
      } finally {
        codec?.dispose();
        bytes.fillRange(0, bytes.length, 0);
      }
    } catch (_) {
      // The placeholder is the denied/offline state; tap explicitly retries authorization.
      if (mounted && generation == _generation) setState(() => _image = null);
    }
  }

  @override
  void didUpdateWidget(PrivateImage old) {
    super.didUpdateWidget(old);
    if (old.repository != widget.repository) {
      old.repository.removeListener(_invalidate);
      widget.repository.addListener(_invalidate);
    }
    if (old.assetId != widget.assetId ||
        old.repository != widget.repository ||
        old.thumbnail != widget.thumbnail) {
      _invalidate();
    }
  }

  @override
  void dispose() {
    widget.repository.removeListener(_invalidate);
    _lifecycle.dispose();
    ++_generation;
    _token?.cancel();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _image == null
      ? Semantics(
          label: 'Photo unavailable. Tap to retry.',
          button: true,
          child: InkWell(
            onTap: _invalidate,
            child: const Center(child: Icon(Icons.image_outlined)),
          ),
        )
      : widget.imageBuilder?.call(context, _image!) ??
            RawImage(image: _image, fit: widget.fit);
}
