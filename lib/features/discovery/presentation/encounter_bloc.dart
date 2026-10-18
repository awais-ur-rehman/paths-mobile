import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/domain/auth_models.dart';
import '../domain/encounter_repository.dart';

sealed class EncounterEvent {
  const EncounterEvent();
}

final class RefreshEncounters extends EncounterEvent {
  const RefreshEncounters();
}

final class InvalidateEncounters extends EncounterEvent {
  const InvalidateEncounters();
}

final class MoreEncounters extends EncounterEvent {
  const MoreEncounters();
}

final class EncounterFilterChanged extends EncounterEvent {
  const EncounterFilterChanged(this.mode, {this.radiusKm = 1});
  final EncounterMode mode;
  final double radiusKm;
}

final class EncounterState {
  EncounterState({
    this.items = const [],
    this.mode = EncounterMode.recent,
    this.radiusKm = 1,
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.nextCursor,
    this.nearbyAvailable = true,
    this.centerLatitude,
    this.centerLongitude,
  });
  final List<Encounter> items;
  final EncounterMode mode;
  final double radiusKm;
  final bool loading, loadingMore, nearbyAvailable;
  final AuthFailure? error;
  final String? nextCursor;
  final double? centerLatitude, centerLongitude;
}

class EncounterBloc extends Bloc<EncounterEvent, EncounterState> {
  EncounterBloc(this.repository) : super(EncounterState()) {
    on<InvalidateEncounters>((event, emit) async {
      emit(EncounterState(mode: state.mode, radiusKm: state.radiusKm));
      await _load(emit);
    });
    on<RefreshEncounters>((event, emit) => _load(emit));
    on<MoreEncounters>((event, emit) => _load(emit, more: true));
    on<EncounterFilterChanged>((event, emit) async {
      if (!encounterRadii.contains(event.radiusKm)) return;
      emit(EncounterState(mode: event.mode, radiusKm: event.radiusKm));
      await _load(emit);
    });
  }
  final EncounterRepository repository;
  CancelToken? _cancel;
  int _generation = 0;
  String? _account;
  Future<void> _load(Emitter<EncounterState> emit, {bool more = false}) async {
    if (more &&
        (state.loading || state.loadingMore || state.nextCursor == null)) {
      return;
    }
    final account = repository.discoveryAccountId;
    final before = account == _account
        ? state
        : EncounterState(mode: state.mode, radiusKm: state.radiusKm);
    _account = account;
    final generation = ++_generation;
    _cancel?.cancel();
    final token = _cancel = CancelToken();
    emit(
      EncounterState(
        items: before.items,
        mode: before.mode,
        radiusKm: before.radiusKm,
        loading: !more,
        loadingMore: more,
        nextCursor: before.nextCursor,
        nearbyAvailable: before.nearbyAvailable,
        centerLatitude: before.centerLatitude,
        centerLongitude: before.centerLongitude,
      ),
    );
    bool current() {
      if (isClosed || emit.isDone || generation != _generation) return false;
      if (account != repository.discoveryAccountId) {
        emit(EncounterState(mode: before.mode, radiusKm: before.radiusKm));
        return false;
      }
      return true;
    }

    try {
      if (account == null) throw const AuthFailure('SESSION_INVALID');
      final page = await Future.any<EncounterPage>([
        repository.loadEncounters(
          mode: before.mode,
          radiusKm: before.radiusKm,
          cursor: more ? before.nextCursor : null,
          cancelToken: token,
        ),
        token.whenCancel.then<EncounterPage>(
          (_) => throw const AuthFailure('cancelled'),
        ),
      ]);
      if (!current()) return;
      final unique = <String, Encounter>{
        if (more)
          for (final item in before.items) item.userId: item,
        for (final item in page.items) item.userId: item,
      };
      emit(
        EncounterState(
          items: List.unmodifiable(unique.values),
          mode: before.mode,
          radiusKm: before.radiusKm,
          nextCursor: page.nextCursor,
          nearbyAvailable: page.nearbyAvailable,
          centerLatitude: more ? before.centerLatitude : page.centerLatitude,
          centerLongitude: more ? before.centerLongitude : page.centerLongitude,
        ),
      );
    } catch (error) {
      if (!current()) return;
      final failure = error is AuthFailure
          ? error
          : const AuthFailure('invalid_response');
      if (failure.code == 'cancelled') return;
      emit(
        EncounterState(
          items: failure.offline ? before.items : const [],
          mode: before.mode,
          radiusKm: before.radiusKm,
          error: failure,
          nearbyAvailable: before.nearbyAvailable,
          centerLatitude: before.centerLatitude,
          centerLongitude: before.centerLongitude,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _generation++;
    _cancel?.cancel();
    return super.close();
  }
}
