import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void registerBrandLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in {
      'Inter': 'assets/fonts/Inter-OFL.txt',
      'Lilita One': 'assets/fonts/LilitaOne-OFL.txt',
    }.entries) {
      yield LicenseEntryWithLineBreaks([
        entry.key,
      ], await rootBundle.loadString(entry.value));
    }
  });
}
