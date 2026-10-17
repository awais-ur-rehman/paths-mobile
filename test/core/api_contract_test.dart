import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';

void main() {
  test(
    'required nullable review reason distinguishes missing from explicit null',
    () {
      final value = {
        'status': 'none',
        'offerSeen': false,
        'uploadsAvailable': false,
        'reason': null,
      };
      expect(VerificationDto.fromJson(value).reason, isNull);
      value.remove('reason');
      expect(() => VerificationDto.fromJson(value), throwsFormatException);
    },
  );
  test(
    'optional back and visibility are omitted and consent stays boolean',
    () {
      final input = VerificationInput(
        frontAssetId: 'fixture-id',
        consent: true,
      );
      expect(input.toJson(), {'frontAssetId': 'fixture-id', 'consent': true});
      expect(
        () => VerificationInput.fromJson({
          'frontAssetId': 'fixture-id',
          'consent': 1,
        }),
        throwsFormatException,
      );
      expect(
        ProfileDetailsInput(
          username: 'fixture',
          name: 'Fixture',
          gender: 'man',
          bio: '',
        ).toJson().containsKey('visibility'),
        false,
      );
    },
  );
}
