package com.paths.mobile.location
import java.net.URI
object UploadEndpointPolicy {
 fun valid(value: String, debug: Boolean): Boolean = try {
  val uri=URI(value)
  uri.host?.isNotEmpty()==true && uri.rawPath=="/v1/locations" && uri.rawUserInfo==null && uri.rawQuery==null && uri.rawFragment==null && (uri.scheme=="https" || (debug && uri.scheme=="http" && uri.host=="127.0.0.1"))
 } catch (_: Exception) { false }
}
