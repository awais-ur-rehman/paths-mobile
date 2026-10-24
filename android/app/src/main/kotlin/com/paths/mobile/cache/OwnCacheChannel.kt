package com.paths.mobile.cache

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.KeyStore
import java.security.MessageDigest
import java.security.GeneralSecurityException
import java.util.concurrent.Executors
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** Three fixed encrypted slots, never arbitrary paths or peer/gallery caches. */
class OwnCacheChannel(context: Context, private val channel: MethodChannel) {
    companion object {
        private val executor = Executors.newSingleThreadExecutor()
        private var sharedStore: OwnCacheFiles? = null
        @Synchronized private fun files(context: Context): OwnCacheFiles = sharedStore ?: OwnCacheFiles(File(context.noBackupFilesDir,"own-profile-cache-v1"),"paths.own-profile.cache.v1").also { sharedStore=it }
    }
    private val main = Handler(Looper.getMainLooper())
    private val store = files(context.applicationContext)
    private var boundOwner:String?=null
    private var boundLease:String?=null
    init {
        channel.setMethodCallHandler { call, result ->
            executor.execute {
                try {
                    val value: Any? = when (call.method) {
                        "activate" -> { val owner=call.argument<String>("owner")!!;val lease=call.argument<String>("lease")!!;store.activate(owner,lease);boundOwner=owner;boundLease=lease;null }
                        "purge" -> { store.purge(); null }
                        "deactivate" -> { store.deactivate(call.argument<String>("owner")!!,call.argument<String>("lease")!!); null }
                        "read", "write", "remove" -> {
                            val owner = call.argument<String>("owner")!!
                            val lease = call.argument<String>("lease")!!
                            val entry = call.argument<String>("entry")!!
                            when (call.method) {
                                "read" -> store.read(owner, lease, entry)
                                "write" -> { val bytes=call.argument<ByteArray>("bytes")!!; try { store.write(owner,lease,entry,bytes) } finally { bytes.fill(0) }; null }
                                else -> { store.remove(owner,lease,entry); null }
                            }
                        }
                        else -> throw IllegalArgumentException("method")
                    }
                    main.post { try { result.success(value) } finally { if(value is ByteArray)value.fill(0) } }
                } catch (_: Exception) { main.post { result.error("own_cache_unavailable", "Private cache unavailable.", null) } }
            }
        }
    }
    fun close() { channel.setMethodCallHandler(null); executor.execute { val owner=boundOwner;val lease=boundLease;if(owner!=null&&lease!=null)store.deactivate(owner,lease) } }
}

internal class OwnCacheFiles(private val root:File,private val alias:String) {
    private val limits=mapOf("profile" to 65536,"thumbnail" to 1048576,"display" to 8388608)
    private var active:String?=null
    private var lease:String?=null
    private fun hash(owner:String)=MessageDigest.getInstance("SHA-256").digest(owner.toByteArray()).joinToString(""){"%02x".format(it)}
    private fun key(create:Boolean):SecretKey? {
        val store=KeyStore.getInstance("AndroidKeyStore").apply{load(null)}
        (store.getKey(alias,null) as? SecretKey)?.let{return it}
        if(!create)return null
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES,"AndroidKeyStore").run {
            init(KeyGenParameterSpec.Builder(alias,KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setKeySize(256).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build())
            generateKey()
        }
    }
    fun activate(owner:String,session:String) {
        require(Regex("^[a-fA-F0-9-]{36}$").matches(owner)&&Regex("^[a-fA-F0-9-]{36}$").matches(session))
        val bound=hash(owner)
        val marker=AtomicFile(File(root,"owner"))
        val previous=if(marker.baseFile.exists() && marker.baseFile.length()<=64)marker.openRead().use{String(it.readBytes())} else ""
        if(previous!=bound)purge()
        check(root.isDirectory||root.mkdirs())
        val out=marker.startWrite()
        try{out.write(bound.toByteArray());marker.finishWrite(out)}catch(e:Exception){marker.failWrite(out);throw e}
        active=bound;lease=session
    }
    private fun file(owner:String,session:String,entry:String):AtomicFile {
        check(active==hash(owner)&&lease==session)
        require(limits.containsKey(entry))
        return AtomicFile(File(root,entry))
    }
    private fun aad(owner:String,entry:String)="paths.own.cache.v1|${hash(owner)}|$entry".toByteArray()
    fun read(owner:String,session:String,entry:String):ByteArray? {
        val target=file(owner,session,entry)
        if(!target.baseFile.exists())return null
        if(target.baseFile.length() !in 30L..(limits.getValue(entry)+64L)){target.delete();return null}
        return try {
            val data=target.openRead().use{it.readBytes()}
            if(data[0]!=1.toByte()){purge();return null}
            val secret=key(false)?:run{purge();return null}
            val cipher=Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE,secret,GCMParameterSpec(128,data.copyOfRange(1,13)))
            cipher.updateAAD(aad(owner,entry))
            cipher.doFinal(data.copyOfRange(13,data.size)).also { if(it.size>limits.getValue(entry)){it.fill(0);purge();throw IllegalStateException("size")} }
        } catch (_:GeneralSecurityException){purge();null}
    }
    fun write(owner:String,session:String,entry:String,bytes:ByteArray) {
        val target=file(owner,session,entry)
        require(bytes.isNotEmpty()&&bytes.size<=limits.getValue(entry))
        val cipher=Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE,key(true));cipher.updateAAD(aad(owner,entry))
        val encrypted=byteArrayOf(1)+cipher.iv+cipher.doFinal(bytes)
        val out=target.startWrite()
        try{out.write(encrypted);target.finishWrite(out)}catch(e:Exception){target.failWrite(out);throw e}
    }
    fun remove(owner:String,session:String,entry:String){val target=file(owner,session,entry);target.delete();check(!target.baseFile.exists())}
    fun deactivate(owner:String,session:String){if(active==hash(owner)&&lease==session){active=null;lease=null}}
    fun purge(){
        active=null;lease=null
        var failure:Exception?=null
        try{KeyStore.getInstance("AndroidKeyStore").apply{load(null)}.deleteEntry(alias)}catch(e:Exception){failure=e}
        if(root.exists()&&!root.deleteRecursively())failure=IllegalStateException("cleanup")
        if(failure!=null)throw IllegalStateException("cache_cleanup",failure)
    }
}
