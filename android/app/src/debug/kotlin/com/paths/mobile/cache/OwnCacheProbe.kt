package com.paths.mobile.cache

import android.content.Context
import java.io.File
import java.security.KeyStore

/** Owner-invoked debug evidence only; never touches real cache files or keys. */
object OwnCacheProbe {
    @JvmStatic fun run(context:Context):Map<String,Any> {
        val root=File(context.noBackupFilesDir,"own-cache-probe-only")
        val alias="paths.own-cache.probe-only"
        val store=OwnCacheFiles(root,alias)
        val owner="11111111-1111-4111-8111-111111111111"
        val other="22222222-2222-4222-8222-222222222222"
        val first="33333333-3333-4333-8333-333333333333"
        val second="44444444-4444-4444-8444-444444444444"
        val payload="Paths isolated crypto probe fixture".toByteArray()
        try {
            store.purge();store.activate(owner,first);store.write(owner,first,"profile",payload)
            val clear=store.read(owner,first,"profile")!!
            val roundTrip=clear.contentEquals(payload);clear.fill(0)
            val sealed=File(root,"profile").readBytes()
            val encrypted=!String(sealed,Charsets.ISO_8859_1).contains(String(payload))
            sealed[sealed.lastIndex]=(sealed.last().toInt() xor 1).toByte()
            File(root,"profile").writeBytes(sealed)
            val tamper=store.read(owner,first,"profile")==null
            store.activate(owner,first);store.write(owner,first,"profile",payload)
            store.activate(other,second)
            val ownerPurged=store.read(other,second,"profile")==null
            val oldSession=try{store.write(owner,first,"profile",payload);false}catch(_:IllegalStateException){true}
            store.write(other,second,"profile",payload);store.purge()
            val keys=KeyStore.getInstance("AndroidKeyStore").apply{load(null)}
            return mapOf("roundTrip" to roundTrip,"encryptedAtRest" to encrypted,"tamperRejected" to tamper,
                "accountSwapPurged" to ownerPurged,"oldSessionRejected" to oldSession,
                "keyDestroyed" to !keys.containsAlias(alias),"fixtureFilesRemoved" to !root.exists())
        } finally { payload.fill(0);store.purge() }
    }
}
