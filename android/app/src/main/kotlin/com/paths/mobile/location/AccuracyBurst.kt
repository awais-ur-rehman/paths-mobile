package com.paths.mobile.location

/** One bounded precision attempt per explicit tracking start, using monotonic time. */
class AccuracyBurst {
    private var deadline = 0L
    fun start(now: Long) { deadline = now + 20_000L }
    fun active(now: Long, foreground: Boolean, precise: Boolean): Boolean =
        foreground && precise && remaining(now) > 0
    fun remaining(now: Long): Long = (deadline - now).coerceAtLeast(0L)
    fun accept(accuracyM: Double) {
        if (accuracyM.isFinite() && accuracyM in 0.0..25.0) stop()
    }
    fun stop() { deadline = 0L }
}
