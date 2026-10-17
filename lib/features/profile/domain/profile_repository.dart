import 'package:dio/dio.dart';

final class ProfileDetails {
  const ProfileDetails({
    required this.username,
    required this.name,
    required this.gender,
    required this.bio,
  });
  final String username, name, gender, bio;
}

abstract interface class ProfileRepository {
  Future<ProfileDetails> loadProfile({CancelToken? cancelToken});
  Future<ProfileDetails> saveProfile(
    ProfileDetails profile, {
    CancelToken? cancelToken,
  });
}
