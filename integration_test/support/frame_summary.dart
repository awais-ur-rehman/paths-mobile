class FrameSample {
  const FrameSample(this.buildMs, this.rasterMs);
  final double buildMs, rasterMs;
}

Map<String, Object?> frameSummary(List<FrameSample> frames) {
  double? p95(Iterable<double> values) {
    final sorted = values.toList()..sort();
    return sorted.isEmpty ? null : sorted[(sorted.length * .95).ceil() - 1];
  }

  return {
    'count': frames.length,
    'buildP95Ms': p95(frames.map((f) => f.buildMs)),
    'rasterP95Ms': p95(frames.map((f) => f.rasterMs)),
    'overBudgetFrames': frames
        .where((f) => f.buildMs > 1000 / 60 || f.rasterMs > 1000 / 60)
        .length,
    'budgetMs': 1000 / 60,
  };
}
