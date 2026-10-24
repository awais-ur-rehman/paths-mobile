import Flutter
import Foundation
import CryptoKit
import Security

/// Serial encrypted slots; a fresh session binding is required after every launch.
final class OwnCacheChannel {
    private let queue = DispatchQueue(label: "com.paths.own-cache")
    private let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("own-profile-cache-v1", isDirectory: true)
    private let limits = ["profile": 65536, "thumbnail": 1048576, "display": 8388608]
    private var active: String?
    private var lease: String?
    private var channel: FlutterMethodChannel?
    private var keyQuery: [String: Any] { [kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "com.paths.mobile.own-cache", kSecAttrAccount as String: "aes-key",
        kSecAttrSynchronizable as String: false] }
    enum Failure: Error { case invalid, storage }
    func attach(_ messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: "paths/own_cache", binaryMessenger: messenger)
        self.channel = channel
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { result(FlutterError(code: "own_cache_unavailable", message: "Private cache unavailable.", details: nil)); return }
            self.queue.async {
                do {
                    var value: Any? = nil
                    let args = call.arguments as? [String: Any] ?? [:]
                    switch call.method {
                    case "activate":
                        guard let owner=args["owner"] as? String, let lease=args["lease"] as? String, UUID(uuidString: owner) != nil, UUID(uuidString: lease) != nil else { throw Failure.invalid }
                        try self.activate(owner, lease)
                    case "purge": try self.purge()
                    case "deactivate":
                        if let owner=args["owner"] as? String,let lease=args["lease"] as? String,self.active==self.hash(owner),self.lease==lease { self.active=nil;self.lease=nil }
                    case "read", "write", "remove":
                        guard let owner=args["owner"] as? String, let lease=args["lease"] as? String, let entry=args["entry"] as? String else { throw Failure.invalid }
                        let file=try self.file(owner, lease, entry)
                        switch call.method {
                        case "read": if let data=try self.read(file,owner,entry) { value=FlutterStandardTypedData(bytes:data) }
                        case "write":
                            guard let bytes=args["bytes"] as? FlutterStandardTypedData, !bytes.data.isEmpty, bytes.data.count<=self.limits[entry]! else { throw Failure.invalid }
                            let sealed=try AES.GCM.seal(bytes.data,using:self.key(true)!,authenticating:self.aad(owner,entry))
                            guard let combined=sealed.combined else { throw Failure.storage }
                            try self.write(Data([1])+combined,to:file)
                        default: if FileManager.default.fileExists(atPath:file.path) { try FileManager.default.removeItem(at:file) }
                        }
                    default: throw Failure.invalid
                    }
                    let reply=value
                    DispatchQueue.main.async { result(reply) }
                } catch { DispatchQueue.main.async { result(FlutterError(code:"own_cache_unavailable",message:"Private cache unavailable.",details:nil)) } }
            }
        }
    }
    private func hash(_ owner:String)->String { SHA256.hash(data:Data(owner.utf8)).map{String(format:"%02x",$0)}.joined() }
    private func aad(_ owner:String,_ entry:String)->Data { Data("paths.own.cache.v1|\(hash(owner))|\(entry)".utf8) }
    private func activate(_ owner:String,_ session:String)throws {
        let marker=root.appendingPathComponent("owner"), bound=hash(owner)
        var previous=""
        if FileManager.default.fileExists(atPath:marker.path) {
            let size=try marker.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? 0
            if size<=64 { previous=String(data:try Data(contentsOf:marker),encoding:.utf8) ?? "" }
        }
        if previous != bound { try purge() }
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true,attributes:[.protectionKey:FileProtectionType.complete])
        var directory=root; var exclusion=URLResourceValues();exclusion.isExcludedFromBackup=true;try directory.setResourceValues(exclusion)
        try write(Data(bound.utf8),to:marker)
        active=bound;lease=session
    }
    private func file(_ owner:String,_ session:String,_ entry:String)throws->URL {
        guard active==hash(owner),lease==session,limits[entry] != nil else { throw Failure.invalid }
        return root.appendingPathComponent(entry)
    }
    private func key(_ create:Bool)throws->SymmetricKey? {
        var value:CFTypeRef?
        let status=SecItemCopyMatching(keyQuery.merging([kSecReturnData as String:true,kSecMatchLimit as String:kSecMatchLimitOne]){_,new in new} as CFDictionary,&value)
        if status==errSecSuccess,let data=value as? Data { return SymmetricKey(data:data) }
        guard status==errSecItemNotFound else { throw Failure.storage }
        if !create { return nil }
        let key=SymmetricKey(size:.bits256),data=key.withUnsafeBytes{Data($0)}
        let item=keyQuery.merging([kSecValueData as String:data,kSecAttrAccessible as String:kSecAttrAccessibleWhenUnlockedThisDeviceOnly]){_,new in new}
        guard SecItemAdd(item as CFDictionary,nil)==errSecSuccess else { throw Failure.storage }
        return key
    }
    private func read(_ file:URL,_ owner:String,_ entry:String)throws->Data? {
        guard FileManager.default.fileExists(atPath:file.path) else { return nil }
        let size=try file.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? 0
        guard size>=30,size<=limits[entry]!+64 else { try FileManager.default.removeItem(at:file);return nil }
        let data=try Data(contentsOf:file)
        guard data.first==1,let key=try key(false) else { try purge();return nil }
        do {
            let box=try AES.GCM.SealedBox(combined:Data(data.dropFirst()))
            let plain=try AES.GCM.open(box,using:key,authenticating:aad(owner,entry))
            guard plain.count<=limits[entry]! else { try purge();return nil }
            return plain
        } catch is CryptoKitError { try purge();return nil }
    }
    private func write(_ data:Data,to file:URL)throws { try data.write(to:file,options:[.atomic,.completeFileProtection]) }
    private func purge()throws {
        active=nil;lease=nil
        let status=SecItemDelete(keyQuery as CFDictionary)
        // Only remove files after successful key shredding; failures are surfaced.
        guard status==errSecSuccess||status==errSecItemNotFound else { throw Failure.storage }
        if FileManager.default.fileExists(atPath:root.path) { try FileManager.default.removeItem(at:root) }
    }
}
