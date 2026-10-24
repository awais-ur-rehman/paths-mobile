import CoreLocation
import CryptoKit
import Foundation
import Security
import Network

private final class RejectRedirects: NSObject, URLSessionTaskDelegate {
 func urlSession(_ session:URLSession,task:URLSessionTask,willPerformHTTPRedirection response:HTTPURLResponse,newRequest request:URLRequest,completionHandler:@escaping(URLRequest?)->Void){completionHandler(nil)}
}

final class PathsLocationTracker: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let file = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("paths-location.queue")
    private var session: String?
    private var epoch = 0
    private var sequence = 0
    private var background = false
    private var foreground = true
    private var startedAt=Date.distantPast
    var emit: (([String: Any]) -> Void)?
    private var backgroundCompletion: ((Bool) -> Void)?
    private var endpoint: URL?
    private var testToken: String?
    private var expiresAtMs=Double.greatestFiniteMagnitude
    private var monitor:NWPathMonitor?
    private var retryWork:DispatchWorkItem?
    private var attempts=0
    private var retryAt=Date.distantPast
    private let transport:URLSession = {
        let config=URLSessionConfiguration.ephemeral;config.urlCache=nil;config.httpCookieStorage=nil;config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration:config,delegate:RejectRedirects(),delegateQueue:nil)
    }()
    func permissions()->[String:Bool] {let authorization=manager.authorizationStatus;return ["granted":authorization == .authorizedAlways || authorization == .authorizedWhenInUse,"precise":manager.accuracyAuthorization == .fullAccuracy,"backgroundAllowed":authorization == .authorizedAlways,"backgroundEnabled":background && session != nil,"servicesEnabled":CLLocationManager.locationServicesEnabled(),"canRequestForeground":authorization == .notDetermined]}
    func flush(_ reset:Bool=true){if reset {attempts=0;retryAt = .distantPast};sendPending()}
    private func watchNetwork(){let next=NWPathMonitor();next.pathUpdateHandler = { [weak self] path in if path.status == .satisfied {DispatchQueue.main.async {self?.flush()}}};monitor=next;next.start(queue:DispatchQueue(label:"com.paths.location.reachability"))}
    private func retryUpload(_ activeSession:String,_ activeEpoch:Int){
        guard session==activeSession,epoch==activeEpoch,attempts<5 else{return}
        attempts+=1;lastStatus="offline";emit?(["status":lastStatus])
        let delay=min(pow(2,Double(attempts-1)),60);retryAt=Date().addingTimeInterval(delay)
        let work=DispatchWorkItem {[weak self] in self?.flush(false)};retryWork?.cancel();retryWork=work;DispatchQueue.main.asyncAfter(deadline:.now()+delay,execute:work)
    }
    private var upload: URLSessionDataTask?
    private var lastStatus = "stopped"
    func status() -> String {
        if session != nil && !CLLocationManager.locationServicesEnabled() { stop(); lastStatus="permissionNeeded" }
        return lastStatus
    }
    private var permissionCompletion: ((Bool) -> Void)?
    override init() {
        super.init()
        manager.delegate = self
        clearFile() // No lease resurrection after a process restart.
    }
    private func encryptionKey() throws -> SymmetricKey {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.paths.mobile.location", kSecAttrAccount as String: "queue-key"]
        var value: CFTypeRef?
        let status = SecItemCopyMatching(query.merging([kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]) { _, new in new } as CFDictionary, &value)
        if status == errSecSuccess, let data = value as? Data { return SymmetricKey(data: data) }
        guard status == errSecItemNotFound else { throw TrackerError.storage }
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        let item = query.merging([kSecValueData as String: data, kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]) { _, new in new }
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw TrackerError.storage }
        return key
    }
    enum TrackerError: Error { case storage, permission, policy }
    private func clearFile() { if FileManager.default.fileExists(atPath: file.path) { do { try FileManager.default.removeItem(at: file) } catch { /* Remains encrypted; future reads require a current lease. */ } } }
    private func read() throws -> [[String: Any]] {
        guard FileManager.default.fileExists(atPath: file.path) else { return [] }
        let box = try AES.GCM.SealedBox(combined: Data(contentsOf: file))
        let data = try AES.GCM.open(box, using: encryptionKey())
        guard let list = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { throw TrackerError.storage }
        let now = Date().timeIntervalSince1970 * 1000
        let filtered = Array(list.filter { item in
            guard let at = item["capturedAt"] as? Double else { return false }
            return now - at >= -30_000 && now - at <= 900_000
        }.suffix(200))
        if filtered.isEmpty { clearFile() } else if filtered.count != list.count { try write(filtered) }
        return filtered
    }
    private func write(_ list: [[String: Any]]) throws {
        let data = try JSONSerialization.data(withJSONObject: Array(list.suffix(200)))
        guard let sealed = try AES.GCM.seal(data, using: encryptionKey()).combined else { throw TrackerError.storage }
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try sealed.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        var resource = file
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try resource.setResourceValues(values)
    }
    func requestForeground(_ completion: @escaping (Bool) -> Void) {
        guard permissionCompletion == nil else { completion(false); return }
        if manager.authorizationStatus != .notDetermined { completion(manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse); return }
        permissionCompletion = completion; manager.requestWhenInUseAuthorization()
    }
    func requestBackground(_ completion: @escaping (Bool) -> Void) {
        if manager.authorizationStatus == .authorizedAlways { completion(true); return }
        guard manager.authorizationStatus == .authorizedWhenInUse, backgroundCompletion == nil else { completion(false); return }
        backgroundCompletion=completion
        manager.requestAlwaysAuthorization()
        // The OS may defer its second prompt. Never leave the UI waiting indefinitely.
        DispatchQueue.main.asyncAfter(deadline: .now()+10) { [weak self] in
            guard let self else { return }
            self.backgroundCompletion?(self.manager.authorizationStatus == .authorizedAlways); self.backgroundCompletion=nil
        }
    }
    func start(_ policy: [String: Any]) throws {
        stop()
        guard let id = policy["deviceSessionId"] as? String, !id.isEmpty, let nextEpoch = policy["consentEpoch"] as? Int, nextEpoch > 0, policy["policyVersion"] as? String == "adaptive.v1" else { throw TrackerError.policy }
        guard manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways else { throw TrackerError.permission }
        background = policy["background"] as? Bool ?? false
        if background && manager.authorizationStatus != .authorizedAlways { throw TrackerError.permission }
        let configured=policy["endpoint"] as? String ?? ""
        let production=policy["uploadMode"] as? String == "production"
        if production {
            #if DEBUG
            let debug=true
            #else
            let debug=false
            #endif
            guard UploadEndpointPolicy.valid(configured,debug:debug),let token=policy["uploadToken"] as? String,token.range(of:"^[a-f0-9]{64}$",options:.regularExpression) != nil,let expires=policy["expiresAtMs"] as? NSNumber,expires.doubleValue>Date().timeIntervalSince1970*1000 else {throw TrackerError.policy}
            endpoint=URL(string:configured);testToken=token;expiresAtMs=expires.doubleValue
        } else {
            if !configured.isEmpty {guard let parsed=URL(string:configured),parsed.scheme=="https",parsed.host != nil else {throw TrackerError.policy};endpoint=parsed}
            testToken=(policy["testToken"] as? String).flatMap{$0.isEmpty ? nil : $0};expiresAtMs = .greatestFiniteMagnitude
        }
        guard (endpoint == nil) == (testToken == nil) else { throw TrackerError.policy }
        startedAt=Date()
        session = id; epoch = nextEpoch; lastStatus = background ? "background" : "active"
        emit?(["status":lastStatus])
        manager.allowsBackgroundLocationUpdates = background
        manager.showsBackgroundLocationIndicator = background
        manager.pausesLocationUpdatesAutomatically = true
        if endpoint != nil {watchNetwork()}
        configure()
    }
    func visibility(_ visible: Bool) {
        foreground = visible
        guard session != nil else { return }
        if !visible && !background { manager.stopUpdatingLocation() } else { configure() }
    }
    private func configure() {
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = foreground ? 25 : 50
        manager.activityType = .other
        manager.startUpdatingLocation()
    }
    func stop() {
        let previousEndpoint=endpoint, previousToken=testToken, previousSession=session, previousEpoch=epoch
        if let previousEndpoint, let previousToken, let previousSession {
            var request=URLRequest(url:previousEndpoint.appendingPathComponent("stop")); request.httpMethod="POST"; request.timeoutInterval=5
            request.setValue("Bearer \(previousToken)",forHTTPHeaderField:"Authorization"); request.setValue("application/json",forHTTPHeaderField:"Content-Type")
            do { request.httpBody=try JSONSerialization.data(withJSONObject:["deviceSessionId":previousSession,"consentEpoch":previousEpoch]); transport.dataTask(with:request).resume() }
            catch { lastStatus="unavailable" }
        }
        monitor?.cancel();monitor=nil;retryWork?.cancel();retryWork=nil;attempts=0;retryAt = .distantPast
        upload?.cancel(); upload = nil; endpoint = nil; testToken = nil; lastStatus = "stopped"; session = nil; epoch += 1; sequence = 0; manager.stopUpdatingLocation(); manager.stopMonitoringSignificantLocationChanges(); clearFile(); emit?(["status":lastStatus]) }
    func pending() throws -> [[String: Any]] {
        guard let current = session else { return [] }
        return try read().filter { ($0["deviceSessionId"] as? String) == current && ($0["consentEpoch"] as? Int) == epoch }
    }
    func acknowledge(_ ids: [String]) throws { let set = Set(ids); try write(read().filter { !set.contains($0["sampleId"] as? String ?? "") }) }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let granted = manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse
        permissionCompletion?(granted); permissionCompletion = nil
        if manager.authorizationStatus == .authorizedAlways { backgroundCompletion?(true); backgroundCompletion=nil }
        if !granted || (background && manager.authorizationStatus != .authorizedAlways) { stop() }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let current = session, foreground || background else { return }
        if Date().timeIntervalSince1970*1000 >= expiresAtMs {stop();return}
        do {
            var list = try read()
            for fix in locations {
                let age = Date().timeIntervalSince(fix.timestamp)
                guard fix.timestamp >= startedAt, age >= -30, age <= 900, fix.horizontalAccuracy >= 0, fix.sourceInformation?.isSimulatedBySoftware != true else { continue }
                sequence += 1
                var sample: [String: Any] = ["sampleId": UUID().uuidString, "deviceSessionId": current, "consentEpoch": epoch, "sequence": sequence, "capturedAt": Int64(fix.timestamp.timeIntervalSince1970 * 1000), "latitude": fix.coordinate.latitude, "longitude": fix.coordinate.longitude, "horizontalAccuracyM": fix.horizontalAccuracy, "appState": foreground ? "foreground" : "background", "precisionMode": manager.accuracyAuthorization == .fullAccuracy ? "precise" : "coarse", "policyVersion": "adaptive.v1"]
                if fix.speed >= 0 { sample["speedMps"] = fix.speed }
                list.append(sample)
                emit?(["sample":sample])
            }
            try write(list)
            lastStatus = (locations.last?.horizontalAccuracy ?? 100) > 25 ? "inaccurate" : (foreground ? "active" : "background")
            emit?(["status":lastStatus])
            sendPending()
        } catch { stop(); lastStatus="unavailable"; emit?(["status":lastStatus]) }
    }
    private func sendPending() {
        if Date().timeIntervalSince1970*1000 >= expiresAtMs {stop();return}
        if attempts>=5 && Date()>retryAt.addingTimeInterval(300) {attempts=0}
        guard attempts<5,Date()>=retryAt,upload == nil, let endpoint, let token = testToken, let activeSession = session else { return }
        let activeEpoch = epoch
        do {
            let batch = Array(try pending().prefix(50)); if batch.isEmpty { return }
            var request = URLRequest(url: endpoint.appendingPathComponent("batch")); request.httpMethod = "POST"; request.timeoutInterval = 5
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization"); request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["samples": batch])
            upload = transport.dataTask(with: request) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    guard let self, self.session == activeSession, self.epoch == activeEpoch else { return }
                    self.upload = nil
                    let status=(response as? HTTPURLResponse)?.statusCode ?? 0
                    if [400,401,403,409,413].contains(status){self.stop();self.lastStatus="unavailable";self.emit?(["status":self.lastStatus]);return}
                    guard error == nil,status == 200,let data,data.count<=65536 else {self.retryUpload(activeSession,activeEpoch);return}
                    do {
                        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        guard let ids=result?["acknowledged"] as? [String] else {self.retryUpload(activeSession,activeEpoch);return}
                        let sent=Set(batch.compactMap{$0["sampleId"] as? String});let accepted=ids.filter{sent.contains($0)};try self.acknowledge(accepted);if !accepted.isEmpty {self.emit?(["uploaded":true,"deviceSessionId":activeSession,"consentEpoch":activeEpoch])};self.attempts=0;self.retryAt = .distantPast
                        self.lastStatus = self.manager.accuracyAuthorization == .reducedAccuracy || ((batch.last?["horizontalAccuracyM"] as? NSNumber)?.doubleValue ?? 100)>25 ? "inaccurate" : (self.foreground ? "active" : "background");self.emit?(["status":self.lastStatus])
                        DispatchQueue.main.asyncAfter(deadline:.now()+0.25){[weak self] in self?.flush(false)}
                    } catch { self.stop() }
                }
            }
            upload?.resume()
        } catch { stop() }
    }
    #if DEBUG
    func runQueueProbe() throws -> [String: Bool] {
        stop()
        let now = Date().timeIntervalSince1970 * 1000
        try write((0...200).map { ["sampleId": "synthetic-\($0)", "capturedAt": now] })
        let capped = try read().count == 200
        try write([["sampleId": "expired", "capturedAt": now - 900_001]])
        let expired = try read().isEmpty
        stop()
        return ["capped": capped, "expired": expired, "purged": try read().isEmpty]
    }
    #endif
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if (error as? CLError)?.code == .denied { stop() }
    }
}
