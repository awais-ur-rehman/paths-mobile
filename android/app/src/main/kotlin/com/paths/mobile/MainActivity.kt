package com.paths.mobile

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.paths.mobile.location.PathsLocationTracker
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var push:com.paths.mobile.push.PathsPushChannel?=null
    private var permissionResult: MethodChannel.Result? = null
    private fun canAskLocation():Boolean = tracker.permissions()["granted"]==true || !getSharedPreferences("paths_permissions",MODE_PRIVATE).getBoolean("location_asked",false) || shouldShowRequestPermissionRationale(Manifest.permission.ACCESS_FINE_LOCATION) || shouldShowRequestPermissionRationale(Manifest.permission.ACCESS_COARSE_LOCATION)
    private val tracker by lazy { PathsLocationTracker.get(this) }
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger,"paths/media").setMethodCallHandler { call,result ->
            if(call.method != "cacheDirectory") result.notImplemented()
            else try { result.success(cacheDir.canonicalPath) }
            catch (_: Exception) { result.error("media_cleanup","Photo cleanup could not finish.",null) }
        }
        push=com.paths.mobile.push.PathsPushChannel(this,MethodChannel(engine.dartExecutor.binaryMessenger,"paths/push"))
        val channel=MethodChannel(engine.dartExecutor.binaryMessenger,"paths/location")
        tracker.emit={ event -> channel.invokeMethod("event",event) }
        channel.setMethodCallHandler { call,result ->
            try {
                when(call.method) {
                    "runQueueProbe" -> {
                        if((applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) == 0) result.notImplemented()
                        else { tracker.stop(); result.success(Class.forName("com.paths.mobile.location.QueueLifecycleProbe").getMethod("run", android.content.Context::class.java).invoke(null,this)) }
                    }
                    "start" -> { tracker.start(call.arguments as Map<*, *>); check(tracker.status() in listOf("active","background","inaccurate")); result.success(null) }
                    "pause", "stopAndPurge" -> { tracker.stop(); result.success(null) }
                    "status" -> result.success(tracker.status())
                    "permissions" -> result.success(tracker.permissions()+mapOf("canRequestForeground" to canAskLocation()))
                    "flushPending" -> { tracker.flush(); result.success(null) }
                    "queueCount" -> result.success(tracker.pending().size)
                    "pendingSamples" -> result.success(tracker.pending())
                    "acknowledge" -> { tracker.acknowledge((call.arguments as List<*>).map { require(it is String); it }); result.success(null) }
                    "requestForegroundPermission" -> {
                        if(permissionResult != null) { result.error("busy","Permission request in progress",null) }
                        else if(tracker.permissions()["granted"]==true) result.success(true)
                        else if(!canAskLocation())result.success(false)
                        else {getSharedPreferences("paths_permissions",MODE_PRIVATE).edit().putBoolean("location_asked",true).apply();permissionResult=result;requestPermissions(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION,Manifest.permission.ACCESS_COARSE_LOCATION),100)}
                    }
                    "requestBackgroundPermission" -> {
                        if(permissionResult!=null) result.error("busy","Permission request in progress",null)
                        else if(Build.VERSION.SDK_INT < 33 || checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)==PackageManager.PERMISSION_GRANTED) result.success(true)
                        else {permissionResult=result;requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS),101)}
                    }
                    "openSettings" -> { startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,Uri.parse("package:$packageName"))); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) { tracker.stop(); result.error("tracker_unavailable","Tracking could not continue; check precise location and system settings.",null) }
        }
    }
    override fun onRequestPermissionsResult(code: Int, permissions: Array<out String>, results: IntArray) {
        super.onRequestPermissionsResult(code,permissions,results)
        push?.permissions(code)
        if(code==100) {permissionResult?.success(tracker.permissions()["granted"]==true);permissionResult=null}
        if(code==101) {permissionResult?.success(Build.VERSION.SDK_INT<33 || checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)==PackageManager.PERMISSION_GRANTED);permissionResult=null}
    }
    override fun onNewIntent(intent:Intent){super.onNewIntent(intent);setIntent(intent);push?.intent(intent)}
    override fun onResume() { super.onResume(); tracker.visibility(true) }
    override fun onPause() { tracker.visibility(false); super.onPause() }
    override fun onDestroy() { push?.dispose();push=null; tracker.emit=null; permissionResult?.error("cancelled","Activity closed",null); permissionResult=null; super.onDestroy() }
}
