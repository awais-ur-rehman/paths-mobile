import 'package:dio/dio.dart';

final class ProfileDetails {
  const ProfileDetails({
    required this.username,
    required this.name,
    required this.gender,
    required this.bio,
    this.visibility = 'private',
  });
  final String username, name, gender, bio, visibility;
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
  });
  final String userId,
      username,
      name,
      gender,
      bio,
      visibility,
      verificationStatus;
  final int age;
}

abstract interface class ProfileSummaryRepository {
  Future<ProfileSummary> loadProfileSummary(
    String userId, {
    CancelToken? cancelToken,
  });
}
