package com.paths.mobile.location
import android.content.Context
import org.json.JSONObject

/** Synthetic data only, compiled exclusively into debug builds. */
object QueueLifecycleProbe {
    @JvmStatic fun run(context: Context): Map<String, Any> {
        val queue = EncryptedSampleQueue(context)
        queue.clear()
        val now = System.currentTimeMillis()
        val samples = (0..200).map { JSONObject().put("sampleId","synthetic-$it").put("capturedAt",now) }
        queue.write(samples)
        val capped = queue.read(now).size == 200
        val expired = queue.read(now + 900_001).isEmpty()
        queue.clear()
        return mapOf("capped" to capped,"expired" to expired,"purged" to queue.read().isEmpty())
    }
}
