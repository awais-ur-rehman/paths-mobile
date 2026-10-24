import 'package:dio/dio.dart';

enum EncounterMode { recent, nearby }

const encounterRadii = [.5, 1.0, 3.0, 5.0];

final class Encounter {
  const Encounter({
    required this.encounterId,
    this.isSaved = false,
    this.avatarAssetId,
    this.requestState = "none",
    required this.userId,
    required this.username,
    required this.displayName,
    required this.age,
    required this.bio,
    required this.verificationStatus,
    required this.coarseAreaId,
    required this.coarseAreaLabel,
    required this.areaLatitude,
    required this.areaLongitude,
    required this.timeBucket,
    required this.encounterDate,
    required this.encounterCount,
    required this.eligibilityExpiresAt,
  });
  final String encounterId,
      userId,
      username,
      displayName,
      bio,
      verificationStatus,
      coarseAreaId,
      coarseAreaLabel,
      timeBucket,
      encounterDate,
      eligibilityExpiresAt;
  final int age, encounterCount;
  final bool isSaved;
  final String? avatarAssetId;
  final String requestState;
  final double areaLatitude, areaLongitude;
  String get timeLabel => switch (timeBucket) {
    'recently' => 'Recently',
    'earlier_today' => 'Earlier today',
    _ => encounterDate,
  };
}

final class EncounterPage {
  EncounterPage({
    required List<Encounter> items,
    required this.nextCursor,
    required this.nearbyAvailable,
    required this.centerLatitude,
    required this.centerLongitude,
  }) : items = List.unmodifiable(items);
  final List<Encounter> items;
  final String? nextCursor;
  final bool nearbyAvailable;
  final double? centerLatitude, centerLongitude;
}

abstract interface class EncounterRepository {
  String? get discoveryAccountId;
  Future<EncounterPage> loadEncounters({
    EncounterMode mode = EncounterMode.recent,
    double radiusKm = 1,
    String search = '',
    String? cursor,
    CancelToken? cancelToken,
  });
}
