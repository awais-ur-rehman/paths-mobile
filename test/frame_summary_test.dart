import 'package:flutter_test/flutter_test.dart';

import '../integration_test/support/frame_summary.dart';

void main() {
  test('frame summary reports separate build/raster latency without hiding missed budgets', () {
    final result = frameSummary([
      const FrameSample(1, 2),
      const FrameSample(3, 30),
      const FrameSample(20, 4),
    ]);
    expect(result['count'], 3);
    expect(result['buildP95Ms'], 20);
    expect(result['rasterP95Ms'], 30);
    expect(result['overBudgetFrames'], 2);
    expect(frameSummary([])['buildP95Ms'], isNull);
  });
}
