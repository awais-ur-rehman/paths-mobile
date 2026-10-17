package com.paths.mobile.push

import android.Manifest
import android.app.Application
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.paths.mobile.MainActivity
import com.paths.mobile.R
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class PathsApplication: Application(){
 override fun onCreate(){super.onCreate();PathsPush.initialize(this)}
}
/** Only public Firebase options and a random binding ID are persisted here. */
object PathsPush {
 const val CHANNEL="paths_events"
 var emit:((String,Any?)->Unit)?=null
 private fun prefs(context:Context)=context.getSharedPreferences("paths_push",Context.MODE_PRIVATE)
 fun initialize(context:Context):Boolean {
  val p=prefs(context)
  if(p.getString("applicationId","").isNullOrEmpty())return false
  return try {
   if(FirebaseApp.getApps(context).isEmpty())FirebaseApp.initializeApp(context,FirebaseOptions.Builder().setApplicationId(p.getString("applicationId","")!!).setApiKey(p.getString("apiKey","")!!).setProjectId(p.getString("projectId","")!!).setGcmSenderId(p.getString("senderId","")!!).build())
   FirebaseMessaging.getInstance().isAutoInitEnabled=p.getBoolean("enabled",false)
   true
  }catch(_:IllegalArgumentException){false}
 }
 fun configure(context:Context,args:Map<*,*>){
  val fields=listOf("projectId","applicationId","apiKey","senderId")
  if(fields.any{(args[it] as? String).isNullOrBlank()})return
  val p=prefs(context)
  // Firebase options cannot change inside a process. Require a fresh build/restart.
  if(FirebaseApp.getApps(context).isNotEmpty()&&fields.any{p.getString(it,"")!=args[it]})throw IllegalStateException()
  val edit=p.edit();fields.forEach{edit.putString(it,args[it] as String)};check(edit.commit());check(initialize(context))
 }
 fun granted(context:Context)= (Build.VERSION.SDK_INT<33||context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)==PackageManager.PERMISSION_GRANTED)&&context.getSystemService(NotificationManager::class.java).areNotificationsEnabled()
 @Synchronized fun generation(context:Context):Int {
  val p=prefs(context);val next=Math.addExact(p.getInt("generation",0),1);check(p.edit().putInt("generation",next).commit());return next
 }
 @Synchronized fun bind(context:Context,binding:String,generation:Int):Boolean {
  UUID.fromString(binding)
  val p=prefs(context);if(p.getInt("generation",0)!=generation)return false
  check(p.edit().putString("binding",binding).putBoolean("enabled",true).commit());FirebaseMessaging.getInstance().isAutoInitEnabled=true;return true
 }
 @Synchronized fun clear(context:Context){
  generation(context)
  val p=prefs(context);check(p.edit().remove("binding").remove("tap").remove("seen").putBoolean("enabled",false).commit())
  val manager=context.getSystemService(NotificationManager::class.java)
  manager.activeNotifications.filter{it.notification.channelId==CHANNEL}.forEach{manager.cancel(it.tag,it.id)}
  if(FirebaseApp.getApps(context).isNotEmpty())FirebaseMessaging.getInstance().isAutoInitEnabled=false
 }
 fun tap(context:Context,intent:Intent?):String?{
  val event=intent?.getStringExtra("paths_event")?:return null
  val binding=intent.getStringExtra("paths_binding")
  intent.removeExtra("paths_event");intent.removeExtra("paths_binding")
  if(binding!=prefs(context).getString("binding",null)||!prefs(context).getBoolean("enabled",false))return null
  try{UUID.fromString(event)}catch(_:IllegalArgumentException){return null}
  check(prefs(context).edit().putString("tap",event).commit());return event
 }
 @Synchronized fun receive(context:Context,data:Map<String,String>){
  val event=data["eventId"]?:return;val binding=data["bindingId"]?:return
  try{UUID.fromString(event);UUID.fromString(binding)}catch(_:IllegalArgumentException){return}
  val kind=data["kind"]?:return
  val body=when(kind){"encounter"->"You crossed paths with someone.";"request_received"->"You have a connection request.";"request_accepted"->"Your connection request was accepted.";else->return}
  val p=prefs(context)
  if(!p.getBoolean("enabled",false)||binding!=p.getString("binding",null)||!granted(context))return
  val seen=p.getString("seen","")!!.split(',').filter{it.isNotEmpty()}
  if(event in seen)return
  check(p.edit().putString("seen",(seen+event).takeLast(100).joinToString(",")).commit())
  val manager=context.getSystemService(NotificationManager::class.java)
  manager.createNotificationChannel(NotificationChannel(CHANNEL,"Paths",NotificationManager.IMPORTANCE_DEFAULT))
  val intent=Intent(context,MainActivity::class.java).setAction("com.paths.mobile.PUSH").setData(Uri.parse("paths://notification/$event")).putExtra("paths_event",event).putExtra("paths_binding",binding).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
  val tap=PendingIntent.getActivity(context,0,intent,PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
  manager.notify(event,0,Notification.Builder(context,CHANNEL).setSmallIcon(R.drawable.paths_symbol).setContentTitle("Paths").setContentText(body).setAutoCancel(true).setContentIntent(tap).setVisibility(Notification.VISIBILITY_PRIVATE).build())
  emit?.invoke("received",null)
 }
 fun status(context:Context)=mapOf("configured" to initialize(context),"granted" to granted(context),"optedIn" to prefs(context).getBoolean("enabled",false),"bound" to (prefs(context).getString("binding",null)!=null))
 fun takeTap(context:Context):String? {val p=prefs(context);val value=p.getString("tap",null);check(p.edit().remove("tap").commit());return value}
}
class PathsMessagingService:FirebaseMessagingService(){
 override fun onMessageReceived(message:RemoteMessage){PathsPush.receive(this,message.data)}
 override fun onNewToken(token:String){PathsPush.emit?.invoke("tokenChanged",null)}
}
class PathsPushChannel(private val activity:FlutterActivity,private val channel:MethodChannel){
 private var permission:MethodChannel.Result?=null
 init {
  PathsPush.emit={method,value->activity.runOnUiThread{channel.invokeMethod(method,value)}}
  PathsPush.tap(activity,activity.intent)
  channel.setMethodCallHandler{call,result->try{when(call.method){
   "configure"->{PathsPush.configure(activity,call.arguments as Map<*,*>);result.success(null)}
   "status"->result.success(PathsPush.status(activity))
   "requestPermission"->{if(permission!=null)result.error("busy","Permission request in progress",null) else if(Build.VERSION.SDK_INT>=33&&!PathsPush.granted(activity)){permission=result;activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS),102)}else result.success(PathsPush.granted(activity))}
   "token"->{check(PathsPush.initialize(activity));FirebaseMessaging.getInstance().token.addOnCompleteListener{task->if(task.isSuccessful)result.success(mapOf("provider" to "fcm","token" to task.result))else result.error("unavailable","Push registration unavailable",null)}}
   "nextGeneration"->result.success(PathsPush.generation(activity))
   "bind"->{val args=call.arguments as Map<*,*>;result.success(PathsPush.bind(activity,args["bindingId"] as String,args["generation"] as Int))}
   "clear"->{PathsPush.clear(activity);result.success(null)}
   "pendingTap"->result.success(PathsPush.takeTap(activity))
   "openSettings"->{activity.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,Uri.parse("package:${activity.packageName}")));result.success(null)}
   else->result.notImplemented()
  }}catch(_:Exception){result.error("unavailable","Push registration unavailable",null)}}
 }
 fun permissions(code:Int){if(code==102){permission?.success(PathsPush.granted(activity));permission=null}}
 fun intent(intent:Intent){PathsPush.tap(activity,intent)?.let{channel.invokeMethod("tap",it)}}
 fun dispose(){PathsPush.emit=null;channel.setMethodCallHandler(null);permission?.error("cancelled","Activity closed",null);permission=null}
}
