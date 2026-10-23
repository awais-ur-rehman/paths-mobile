package com.paths.mobile.location

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.net.ConnectivityManager
import android.net.Network
import android.os.*
import com.google.android.gms.location.*
import org.json.JSONObject
import java.util.UUID

/** Native ownership continues collection without a Dart timer or mounted screen. */
class PathsLocationTracker private constructor(private val context: Context) {
    companion object {
        @Volatile private var instance: PathsLocationTracker? = null
        fun get(context: Context): PathsLocationTracker = instance ?: synchronized(this) {
            instance ?: PathsLocationTracker(context.applicationContext).also { instance = it }
        }
    }
    private val provider = LocationServices.getFusedLocationProviderClient(context)
    private val queue = EncryptedSampleQueue(context)
    private var session: String? = null
    private var epoch = 0L
    private var sequence = 0L
    private var background = false
    private val accuracyBurst = AccuracyBurst()
    private val endBurst = Runnable { synchronized(this) { if(session != null && (foreground || background)) subscribe() } }
    private var foreground = true
    private var callback: LocationCallback? = null
    private var endpoint: String? = null
    private var testToken: String? = null
    private var production = false
    private var expiresAtMs = Long.MAX_VALUE
    private var attempts = 0
    private var retryAt = 0L
    private val retryHandler = Handler(Looper.getMainLooper())
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private val retry = Runnable { flush(false) }
    private fun granted(): Boolean = context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)==PackageManager.PERMISSION_GRANTED || context.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION)==PackageManager.PERMISSION_GRANTED
    @Synchronized fun permissions(): Map<String,Boolean> = mapOf("granted" to granted(),"precise" to (context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)==PackageManager.PERMISSION_GRANTED),"backgroundEnabled" to (background && session != null),"backgroundAllowed" to (Build.VERSION.SDK_INT<33 || context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)==PackageManager.PERMISSION_GRANTED),"servicesEnabled" to context.getSystemService(android.location.LocationManager::class.java).isLocationEnabled)
    @Synchronized fun notificationTitle(): String = if(production) "Paths location sharing" else "Paths location experiment"
    @Synchronized fun flush(reset: Boolean = true) { if(reset) { attempts=0;retryAt=0 }; val active=session ?: return; sendPending(active,epoch) }
    private fun watchNetwork() {
        val next=object:ConnectivityManager.NetworkCallback(){override fun onAvailable(network:Network){retryHandler.post {flush()}}}
        context.getSystemService(ConnectivityManager::class.java).registerDefaultNetworkCallback(next);networkCallback=next
    }
    @Synchronized private fun retryUpload(active:String,activeEpoch:Long) {
        if(session!=active || epoch!=activeEpoch || attempts>=5) return
        lastStatus="offline";emit?.invoke(mapOf("status" to lastStatus));attempts++
        val wait=(1000L shl (attempts-1)).coerceAtMost(60_000L);retryAt=SystemClock.elapsedRealtime()+wait
        retryHandler.removeCallbacks(retry);retryHandler.postDelayed(retry,wait)
    }
    private var upload: java.util.concurrent.Future<*>? = null
    private val executor = java.util.concurrent.Executors.newSingleThreadExecutor()
    private var connection: java.net.HttpURLConnection? = null
    private var lastStatus = "stopped"
    private var startedElapsed = 0L
    var emit: ((Map<String, Any>) -> Unit)? = null
    @Synchronized fun serviceEpoch(): Long = if(background && session != null) epoch else -1L
    @Synchronized fun serviceDestroyed(serviceEpoch: Long) { if(serviceEpoch == epoch) stop() }
    @Synchronized fun status(): String {
        if(session != null && (!granted() || !context.getSystemService(android.location.LocationManager::class.java).isLocationEnabled)) { stop(); lastStatus = "permissionNeeded" }
        return lastStatus
    }
    init { queue.clear() } // Process restart requires explicit consent; never resurrect a previous lease.

    @Synchronized fun start(policy: Map<*, *>) {
        stop(false)
        check(granted()) { "precise_permission_needed" }
        session = policy["deviceSessionId"] as? String
        epoch = (policy["consentEpoch"] as? Number)?.toLong() ?: 0
        require(!session.isNullOrEmpty() && epoch > 0 && policy["policyVersion"] == "adaptive.v1")
        val configured=policy["endpoint"] as? String ?: ""
        production=policy["uploadMode"]=="production"
        if(production) {
            require(UploadEndpointPolicy.valid(configured,(context.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE)!=0)) { "invalid_upload_endpoint" }
            testToken=(policy["uploadToken"] as? String)?.takeIf { Regex("^[a-f0-9]{64}$").matches(it) }
            expiresAtMs=(policy["expiresAtMs"] as? Number)?.toLong() ?: 0L
            require(expiresAtMs>System.currentTimeMillis()) { "expired_location_lease" }
        } else {
            require(configured.isEmpty() || configured=="http://127.0.0.1:8787") { "unsupported_test_endpoint" }
            testToken=(policy["testToken"] as? String)?.takeIf { it.isNotEmpty() };expiresAtMs=Long.MAX_VALUE
        }
        endpoint = configured.takeIf { it.isNotEmpty() }
        require((endpoint == null) == (testToken == null)) { "incomplete_test_configuration" }
        startedElapsed = SystemClock.elapsedRealtimeNanos()
        accuracyBurst.start(SystemClock.elapsedRealtime())
        background = policy["background"] == true
        lastStatus = if(background) "background" else "active"
        if (background) context.startForegroundService(Intent(context, PathsLocationService::class.java))
        else context.stopService(Intent(context, PathsLocationService::class.java))
        if(endpoint!=null) watchNetwork()
        subscribe()
        emit?.invoke(mapOf("status" to lastStatus))
    }
    @Synchronized fun visibility(isForeground: Boolean) {
        foreground = isForeground
        if (session != null) {
            if (!foreground && !background) removeUpdates() else subscribe()
        }
    }
    @Synchronized private fun subscribe() {
        removeUpdates()
        val activeSession = session ?: return
        val activeEpoch = epoch
        val burst = accuracyBurst.active(SystemClock.elapsedRealtime(),foreground,permissions()["precise"]==true)
        retryHandler.removeCallbacks(endBurst)
        if(burst) retryHandler.postDelayed(endBurst,accuracyBurst.remaining(SystemClock.elapsedRealtime()))
        val interval = if(burst) 2_000L else if (foreground) 20_000L else 90_000L
        val request = LocationRequest.Builder(if(burst) Priority.PRIORITY_HIGH_ACCURACY else Priority.PRIORITY_BALANCED_POWER_ACCURACY, interval)
            .setMinUpdateDistanceMeters(if(burst) 0f else if (foreground) 25f else 50f)
            .setMaxUpdateDelayMillis(if(burst) 0L else if (foreground) 30_000L else 120_000L).build()
        val next = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                synchronized(this@PathsLocationTracker) {
                    if (session != activeSession || epoch != activeEpoch || callback !== this || (!foreground && !background)) return
                    try {
                        if (!granted() || System.currentTimeMillis()>=expiresAtMs) { stop(); return }
                        val samples = queue.read()
                        for (fix in result.locations) {
                            if (fix.elapsedRealtimeNanos < startedElapsed || isMock(fix) || !fix.hasAccuracy() || fix.accuracy < 0 || System.currentTimeMillis()-fix.time !in -30_000L..900_000L) continue
                            accuracyBurst.accept(fix.accuracy.toDouble())
                            val sample=toJson(fix, activeSession, activeEpoch)
                            samples.add(sample)
                            emit?.invoke(mapOf("sample" to sample.keys().asSequence().associateWith { sample.get(it) }))
                        }
                        queue.write(samples)
                        lastStatus = if((samples.lastOrNull()?.optDouble("horizontalAccuracyM", 100.0) ?: 100.0) > 25.0) "inaccurate" else if(foreground) "active" else "background"
                        emit?.invoke(mapOf("status" to lastStatus))
                        sendPending(activeSession, activeEpoch)
                        if(burst && !accuracyBurst.active(SystemClock.elapsedRealtime(),foreground,permissions()["precise"]==true)) {
                            retryHandler.removeCallbacks(endBurst);retryHandler.post(endBurst)
                        }
                    } catch (_: Exception) { stop(); lastStatus="unavailable"; emit?.invoke(mapOf("status" to lastStatus)) } // Fail closed on permission or encryption failure.
                }
            }
        }
        callback = next
        try { provider.requestLocationUpdates(request, next, Looper.getMainLooper()).addOnFailureListener { synchronized(this) { if(callback === next) stop() } } }
        catch (_: SecurityException) { stop(); lastStatus="permissionNeeded"; emit?.invoke(mapOf("status" to lastStatus)) }
    }
    @Suppress("DEPRECATION")
    private fun isMock(fix: Location): Boolean = if(Build.VERSION.SDK_INT >= 31) fix.isMock else fix.isFromMockProvider
    private fun toJson(fix: Location, activeSession: String, activeEpoch: Long) = JSONObject().apply {
        put("sampleId", UUID.randomUUID().toString()); put("deviceSessionId", activeSession)
        put("consentEpoch", activeEpoch); put("sequence", ++sequence); put("capturedAt", fix.time)
        put("latitude", fix.latitude); put("longitude", fix.longitude); put("horizontalAccuracyM", fix.accuracy.toDouble())
        if(fix.hasSpeed()) put("speedMps", fix.speed.toDouble())
        put("appState", if(foreground) "foreground" else "background"); put("precisionMode", if(permissions()["precise"]==true) "precise" else "coarse"); put("policyVersion", "adaptive.v1")
    }
    @Synchronized private fun sendPending(activeSession: String, activeEpoch: Long) {
        if(System.currentTimeMillis()>=expiresAtMs) {stop();return}
        if(attempts>=5 && SystemClock.elapsedRealtime()>retryAt+300_000L){attempts=0}
        if(attempts>=5 || SystemClock.elapsedRealtime()<retryAt) return
        val target = endpoint ?: return
        val token = testToken ?: return
        if(upload?.isDone == false) return
        val batch = queue.read().take(50)
        if(batch.isEmpty()) return
        upload = executor.submit {
            var request: java.net.HttpURLConnection? = null
            try {
                synchronized(this) {
                    if(session != activeSession || epoch != activeEpoch) return@submit
                    request = java.net.URL("$target/batch").openConnection() as java.net.HttpURLConnection
                    connection = request
                }
                request!!.apply {
                    requestMethod = "POST"; connectTimeout = 5000; readTimeout = 5000; doOutput = true; instanceFollowRedirects = false; useCaches = false
                    setRequestProperty("Authorization", "Bearer $token"); setRequestProperty("Content-Type", "application/json")
                    outputStream.use { it.write(JSONObject().put("samples",org.json.JSONArray(batch)).toString().toByteArray(Charsets.UTF_8)) }
                    if(responseCode == 200) {
                        val response = inputStream.bufferedReader().use { JSONObject(it.readText()) }
                        val ids = response.getJSONArray("acknowledged")
                        val sent=batch.map {it.getString("sampleId")}.toSet()
                        synchronized(this@PathsLocationTracker) {
                            if(session == activeSession && epoch == activeEpoch) { acknowledge((0 until ids.length()).map { ids.getString(it) }.filter {it in sent}); attempts=0;retryAt=0;lastStatus=if(permissions()["precise"]!=true || batch.last().optDouble("horizontalAccuracyM",100.0)>25)"inaccurate" else if(foreground)"active" else "background";emit?.invoke(mapOf("status" to lastStatus)); retryHandler.postDelayed({flush(false)},250) }
                        }
                    } else if(responseCode in listOf(400,401,403,409,413)) {
                        synchronized(this@PathsLocationTracker) {if(session==activeSession && epoch==activeEpoch){stop();lastStatus="unavailable";emit?.invoke(mapOf("status" to lastStatus))}}
                    } else retryUpload(activeSession,activeEpoch)
                }
            } catch (_: Exception) { retryUpload(activeSession,activeEpoch) }
            finally { request?.disconnect(); synchronized(this) { if(connection === request) connection = null } }
        }
    }
    private fun removeUpdates() { retryHandler.removeCallbacks(endBurst); callback?.let { provider.removeLocationUpdates(it) }; callback = null }
    @Synchronized fun stop(stopService: Boolean = true) {
        val oldSession=session; val oldEpoch=epoch; val oldEndpoint=endpoint; val oldToken=testToken
        session = null; epoch++; sequence = 0; lastStatus = "stopped"; endpoint = null; testToken = null
        accuracyBurst.stop();retryHandler.removeCallbacksAndMessages(null);attempts=0;retryAt=0
        networkCallback?.let { context.getSystemService(ConnectivityManager::class.java).unregisterNetworkCallback(it) };networkCallback=null
        connection?.disconnect(); connection = null; upload?.cancel(true); upload = null
        removeUpdates(); queue.clear()
        if(stopService) context.stopService(Intent(context, PathsLocationService::class.java))
        emit?.invoke(mapOf("status" to lastStatus))
        if(oldSession != null && oldEndpoint != null && oldToken != null) executor.submit {
            var request: java.net.HttpURLConnection?=null
            try {
                request=java.net.URL("$oldEndpoint/stop").openConnection() as java.net.HttpURLConnection
                request.apply {
                    requestMethod="POST"; connectTimeout=5000; readTimeout=5000; doOutput=true; instanceFollowRedirects=false; useCaches=false
                    setRequestProperty("Authorization","Bearer $oldToken"); setRequestProperty("Content-Type","application/json")
                    outputStream.use { it.write(JSONObject().put("deviceSessionId",oldSession).put("consentEpoch",oldEpoch).toString().toByteArray(Charsets.UTF_8)) }
                    inputStream.close()
                }
            } catch (_: Exception) { /* Flutter retries control on resume and displays pending remote stop while offline. */ }
            finally { request?.disconnect() }
        }
    }
    @Synchronized fun pending(): List<Map<String, Any>> = queue.read().filter {
        session != null && it.getString("deviceSessionId") == session && it.getLong("consentEpoch") == epoch
    }.map { obj -> obj.keys().asSequence().associateWith { obj.get(it) } }
    @Synchronized fun acknowledge(ids: List<String>) { val removed=ids.toSet(); queue.write(queue.read().filterNot { it.getString("sampleId") in removed }) }
}

class PathsLocationService : Service() {
    private var generation=0L
    override fun onCreate() {
        super.onCreate()
        generation=PathsLocationTracker.get(this).serviceEpoch()
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel("paths_tracking", "Paths location", NotificationManager.IMPORTANCE_LOW))
        val stopIntent = PendingIntent.getService(this, 1, Intent(this, PathsLocationService::class.java).setAction("stop"), PendingIntent.FLAG_IMMUTABLE)
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val notification = Notification.Builder(this, "paths_tracking").setSmallIcon(com.paths.mobile.R.drawable.paths_notification)
            .setContentTitle(PathsLocationTracker.get(this).notificationTitle()).setContentText("Best-effort capture is active. Tap Stop to purge samples.")
            .setContentIntent(PendingIntent.getActivity(this, 0, launchIntent, PendingIntent.FLAG_IMMUTABLE))
            .addAction(Notification.Action.Builder(null,"Stop",stopIntent).build()).setOngoing(true).build()
        startForeground(41, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if(intent?.action == "stop") { PathsLocationTracker.get(this).stop(); stopSelf() }
        else generation=PathsLocationTracker.get(this).serviceEpoch()
        return START_NOT_STICKY
    }
    override fun onTaskRemoved(rootIntent: Intent?) { /* No restart: OS/user termination is respected. */ }
    override fun onDestroy() { PathsLocationTracker.get(this).serviceDestroyed(generation); super.onDestroy() }
    override fun onBind(intent: Intent?) = null
}
