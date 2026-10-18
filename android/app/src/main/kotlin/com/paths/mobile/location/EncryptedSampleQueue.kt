package com.paths.mobile.location

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** Storage is account/session scoped by tracker checks, encrypted, and excluded from backups. */
class EncryptedSampleQueue(context: Context) {
    private val file = AtomicFile(File(context.noBackupFilesDir, "location.queue"))
    private val alias = "paths.location.queue.v1"
    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").run {
            init(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build())
            generateKey()
        }
    }
    @Synchronized fun read(now: Long = System.currentTimeMillis()): MutableList<JSONObject> {
        if (!file.baseFile.exists()) return mutableListOf()
        return try {
            val bytes = file.openRead().use { it.readBytes() }
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, bytes.copyOfRange(0, 12)))
            val array = JSONArray(String(cipher.doFinal(bytes.copyOfRange(12, bytes.size)), Charsets.UTF_8))
            val filtered=(0 until array.length()).map { array.getJSONObject(it) }
                .filter { now - it.getLong("capturedAt") in -30_000L..900_000L }.takeLast(200).toMutableList()
            if(filtered.isEmpty()) file.delete() else if(filtered.size != array.length()) write(filtered)
            filtered
        } catch (error: Exception) {
            // Corrupt/key-invalidated queues are purged, never surfaced or logged as raw bytes.
            file.delete(); throw IllegalStateException("queue_unavailable", error)
        }
    }
    @Synchronized fun write(samples: List<JSONObject>) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding").apply { init(Cipher.ENCRYPT_MODE, key()) }
        val data = JSONArray(samples.takeLast(200)).toString().toByteArray(Charsets.UTF_8)
        val output = file.startWrite()
        try { output.write(cipher.iv + cipher.doFinal(data)); file.finishWrite(output) }
        catch (error: Exception) { file.failWrite(output); throw error }
    }
    @Synchronized fun clear() { file.delete() }
}
