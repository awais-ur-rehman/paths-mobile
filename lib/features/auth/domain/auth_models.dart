import '../../../core/network/refresh_coordinator.dart';

final class AuthAccount {
  const AuthAccount({
    required this.id,
    required this.email,
    required this.name,
    required this.restricted,
    required this.adultChecked,
  });
  final String id, email, name;
  final bool restricted, adultChecked;
}

final class AuthSession {
  const AuthSession({
    required this.account,
    required this.tokens,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
  });
  final AuthAccount account;
  final SessionTokens tokens;
  final DateTime accessExpiresAt, refreshExpiresAt;
}

final class AuthChallenge {
  const AuthChallenge({
    required this.id,
    required this.purpose,
    required this.expiresAt,
    required this.resendAt,
  });
  final String id, purpose;
  final DateTime expiresAt, resendAt;
}

final class ResetGrant {
  const ResetGrant(this.token, this.expiresAt);
  final String token;
  final DateTime expiresAt;
}

final class PolicyConfig {
  const PolicyConfig({
    this.supportEmail = '',
    this.termsUrl = '',
    this.privacyUrl = '',
  });
  final String supportEmail, termsUrl, privacyUrl;
}

final class AuthFailure implements Exception {
  const AuthFailure(this.code, {this.requestId});
  final String code;
  final String? requestId;
  bool get offline => code == 'offline' || code == 'timeout';
  String get message => switch (code) {
    'INVALID_CREDENTIALS' => 'Email or password is incorrect.',
    'OTP_INVALID' =>
      'The code is invalid or no longer available. Request a new code.',
    'OTP_EXPIRED' => 'The code expired. Request a new code.',
    'OTP_ATTEMPTS' => 'Too many incorrect codes. Request a new code.',
    'OTP_COOLDOWN' => 'Wait before requesting another code.',
    'RATE_LIMITED' => 'Too many attempts. Try again later.',
    'SESSION_INVALID' => 'Your session ended. Sign in again.',
    'ACCOUNT_RESTRICTED' =>
      'This account is restricted. Contact support for help.',
    'RESET_INVALID' =>
      'Your reset authorization expired. Start password recovery again.',
    'ADULT_REQUIRED' => 'Paths is available only to adults aged 18 or older.',
    'DOB_LOCKED' => 'Contact support to correct a confirmed date of birth.',
    'tracking_cleanup' =>
      'Location cleanup could not finish. Retry before continuing.',
    'storage' => 'Secure storage is unavailable. Unlock your phone and retry.',
    'offline' => 'Paths could not be reached. Check your connection and retry.',
    'timeout' => 'The connection timed out. Check your connection and retry.',
    'invalid_response' =>
      'Paths returned an unreadable response. Retry in a moment.',
    'cancelled' => 'The request was cancelled.',
    'configuration' => 'Paths could not connect with this app configuration.',
    _ => 'The request could not be completed. Retry in a moment.',
  };
}
