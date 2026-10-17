import Foundation

enum UploadEndpointPolicy {
 static func valid(_ value:String,debug:Bool)->Bool {
  guard let parts=URLComponents(string:value),let host=parts.host,!host.isEmpty,parts.percentEncodedPath=="/v1/locations",parts.user==nil,parts.password==nil,parts.query==nil,parts.fragment==nil else {return false}
  return parts.scheme=="https" || (debug && parts.scheme=="http" && host=="127.0.0.1")
 }
}
