import 'package:dio/dio.dart';

final class ProfileDetails {
  const ProfileDetails({
    this.revision,
    required this.username,
    required this.name,
    required this.gender,
    required this.bio,
    this.visibility = 'private',
    this.avatarAssetId,
    this.profileComplete = false,
  });
  final String? revision;
  final String username, name, gender, bio, visibility;
  final String? avatarAssetId;
  final bool profileComplete;
}

abstract interface class ProfileRepository {
  Future<ProfileDetails> loadProfile({CancelToken? cancelToken});
  Future<ProfileDetails> saveProfile(
    ProfileDetails profile, {
    CancelToken? cancelToken,
  });
}

final class ProfileSummary {
  const ProfileSummary({
    required this.userId,
    required this.username,
    required this.name,
    required this.age,
    required this.gender,
    required this.bio,
    required this.visibility,
    required this.verificationStatus,
    this.avatarAssetId,
    this.photoState = 'unavailable',
  });
  final String userId,
      username,
      name,
      gender,
      bio,
      visibility,
      verificationStatus;
  final int age;
  final String? avatarAssetId;
  final String photoState;
}

abstract interface class ProfileSummaryRepository {
  Future<ProfileSummary> loadProfileSummary(
    String userId, {
    CancelToken? cancelToken,
  });
}

/// Optional own-account memory optimization; never used to authorize setup.
abstract interface class OwnProfileSnapshotRepository {
  ProfileSummary? get cachedOwnProfile;
  Future<ProfileSummary> refreshOwnProfile({CancelToken? cancelToken});
  void invalidateOwnProfile();
}
