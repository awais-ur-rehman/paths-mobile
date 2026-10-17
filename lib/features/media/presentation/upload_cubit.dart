import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/authenticated_api.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/media_repository.dart';

final class UploadState {
  const UploadState({
    this.photo,
    this.asset,
    this.busy = false,
    this.progress = 0,
    this.error,
  });
  final PickedPhoto? photo;
  final MediaAsset? asset;
  final bool busy;
  final double progress;
  final AuthFailure? error;
}

class UploadCubit extends Cubit<UploadState> {
  UploadCubit(
    this.repository,
    this.picker,
    this.kind, {
    this.pollDelay = const Duration(seconds: 1),
    this.pollAttempts = 20,
  }) : owner = repository.accountId,
       super(const UploadState());
  final MediaRepository repository;
  final PhotoPicker picker;
  final MediaKind kind;
  final Duration pollDelay;
  final int pollAttempts;
  final String? owner;
  String? _intentKey;
  CancelToken? _token;
  int _generation = 0;
  bool _released = false;
  bool _current(int generation) =>
      !isClosed &&
      generation == _generation &&
      owner != null &&
      owner == repository.accountId;
  Future<void> pick(PhotoSource source) async {
    if (isClosed || state.busy) return;
    final generation = ++_generation;
    emit(UploadState(photo: state.photo, asset: state.asset, busy: true));
    PickedPhoto? selected;
    try {
      final photo = selected = await picker.pick(source);
      if (!_current(generation)) {
        photo?.clear();
        return;
      }
      if (photo == null) {
        emit(UploadState(photo: state.photo, asset: state.asset));
        return;
      }
      final old = state.asset;
      if (old != null) await repository.cancel(old.id);
      if (!_current(generation)) {
        photo.clear();
        return;
      }
      state.photo?.clear();
      _intentKey = newIntentKey();
      _released = false;
      emit(UploadState(photo: photo));
      selected = null;
    } catch (error) {
      selected?.clear();
      if (_current(generation)) {
        emit(
          UploadState(
            photo: state.photo,
            asset: state.asset,
            error: _failure(error),
          ),
        );
      }
    }
  }

  Future<void> upload() async {
    if (isClosed || state.busy || state.photo == null) return;
    if (owner == null || owner != repository.accountId) {
      emit(
        UploadState(photo: state.photo, error: const AuthFailure('cancelled')),
      );
      return;
    }
    final generation = ++_generation,
        photo = state.photo!,
        token = _token = CancelToken();
    var asset = state.asset;
    emit(UploadState(photo: photo, asset: asset, busy: true));
    try {
      var current =
          asset ??
          await repository.intent(
            kind,
            photo,
            _intentKey ??= newIntentKey(),
            cancelToken: token,
          );
      asset = current;
      if (!_current(generation)) return;
      emit(UploadState(photo: photo, asset: asset, busy: true));
      if (current.terminal) throw const AuthFailure('image_rejected');
      if (!current.ready) {
        await repository.upload(
          current.id,
          photo,
          cancelToken: token,
          onProgress: (sent, total) {
            if (_current(generation) && total > 0) {
              emit(
                UploadState(
                  photo: photo,
                  asset: current,
                  busy: true,
                  progress: (sent / total).clamp(0, 1),
                ),
              );
            }
          },
        );
        current = await repository.complete(current.id, cancelToken: token);
        for (
          var attempt = 0;
          !current.ready && !current.terminal && attempt < pollAttempts;
          attempt++
        ) {
          await Future.any([
            Future<void>.delayed(pollDelay),
            token.whenCancel.then<void>((_) {}),
          ]);
          if (!_current(generation) || token.isCancelled) return;
          current = await repository.status(current.id, cancelToken: token);
        }
      }
      asset = current;
      if (!_current(generation)) return;
      if (current.terminal) throw const AuthFailure('image_rejected');
      if (!current.ready) throw const AuthFailure('image_processing');
      emit(UploadState(photo: photo, asset: current, progress: 1));
    } catch (error) {
      if (_current(generation)) {
        emit(
          UploadState(
            photo: photo,
            asset: asset,
            progress: state.progress,
            error: _failure(error),
          ),
        );
      }
    }
  }

  void release() {
    _released = true;
  }

  Future<void> cancel() async {
    if (isClosed) return;
    ++_generation;
    _token?.cancel();
    final asset = state.asset;
    state.photo?.clear();
    emit(const UploadState());
    if (!_released && asset != null && owner == repository.accountId) {
      try {
        await repository.cancel(asset.id);
      } catch (error) {
        if (!isClosed) emit(UploadState(error: _failure(error)));
      }
    }
  }

  AuthFailure _failure(Object error) =>
      error is AuthFailure ? error : const AuthFailure('unavailable');
  @override
  Future<void> close() {
    ++_generation;
    _token?.cancel();
    state.photo?.clear();
    return super.close();
  }
}
