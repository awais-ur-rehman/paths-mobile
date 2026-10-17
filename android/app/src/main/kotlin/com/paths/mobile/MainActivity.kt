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
    private var permissionResult: MethodChannel.Result? = null
    private val tracker by lazy { PathsLocationTracker.get(this) }
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
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
                    "queueCount" -> result.success(tracker.pending().size)
                    "pendingSamples" -> result.success(tracker.pending())
                    "acknowledge" -> { tracker.acknowledge((call.arguments as List<*>).map { require(it is String); it }); result.success(null) }
                    "requestForegroundPermission" -> {
                        if(permissionResult != null) { result.error("busy","Permission request in progress",null) }
                        else if(checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)==PackageManager.PERMISSION_GRANTED) result.success(true)
                        else { permissionResult=result; requestPermissions(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION,Manifest.permission.ACCESS_COARSE_LOCATION),100) }
                    }
                    "requestBackgroundPermission" -> {
                        if(Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED) requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS),101)
                        // FGS starts only from the visible opt-in action; no silent background launches.
                        result.success(true)
                    }
                    "openSettings" -> { startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,Uri.parse("package:$packageName"))); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) { tracker.stop(); result.error("tracker_unavailable","Tracking could not continue; check precise location and system settings.",null) }
        }
    }
    override fun onRequestPermissionsResult(code: Int, permissions: Array<out String>, results: IntArray) {
        super.onRequestPermissionsResult(code,permissions,results)
        if(code==100) { permissionResult?.success(checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)==PackageManager.PERMISSION_GRANTED); permissionResult=null }
    }
    override fun onResume() { super.onResume(); tracker.visibility(true) }
    override fun onPause() { tracker.visibility(false); super.onPause() }
    override fun onDestroy() { tracker.emit=null; permissionResult?.error("cancelled","Activity closed",null); permissionResult=null; super.onDestroy() }
}
