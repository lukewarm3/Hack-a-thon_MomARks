//
//  CloudAnchorManager.swift
//  ARMap
//
//  Created by Luke Cao on 3/21/25.
//

import ARCore
import ARKit
import RealityKit
import simd
import FirebaseFirestore

/// Model object for hosting and resolving Cloud Anchors.
class CloudAnchorManager: ObservableObject {
  private enum Constants {
    /// Fill in your own API Key here.
    static let apiKey = "AIzaSyAr5FGipo37nctOkLPoV2qXLK0rrKyHU74"
    /// User defaults key for storing anchor creation timestamps.
    static let timeDictionaryUserDefaultsKey = "NicknameTimeStampDictionary"
    /// User defaults key for storing anchor IDs.
    //static let anchorInfoDictionaryUserDefaultsKey = "NicknameanchorInfoDictionary"
    /// User defaults key for storing privacy notice acceptance.
    static let privacyNoticeUserDefaultsKey = "PrivacyNoticeAccepted"
    /// Average quality threshold for hosting an anchor.
    static let featureMapQualityThreshold: Float = 0.6
    /// Maximum distance from anchor (in meters) before displaying warning.
    static let maxDistance: Float = 10
    /// Minimum distance from anchor (in meters) before displaying warning.
    static let minDistance: Float = 0.2
  }

  /// Enum representing the child pages in the navigation stack.
  enum Page {
    case host
    case resolvePicker
    case resolve
  }

  @Published var navigationPath: [Page] = [] {
    willSet {
      if newValue.count < navigationPath.count {
        backButtonPressed() // clean up the resource if the current page is .host or .resolve
      }
    }
  }
  @Published var showPrivacyNotice = false
  @Published var showAnchorNameDialog = false
  @Published var anchorNameDialogField = ""
    @Published var anchorDescriptionDialogField = ""
  @Published var messageLabel = ""
  @Published var debugLabel = ""
    @Published var cloudToLocalAnchorMap = [String: UUID]()
    
    var anchorInfoDictionaryUserDefaultsKey = "NicknameanchorInfoDictionary"
  private var placedAnchor: Bool = false
  var isOnHorizontalPlane: Bool = false
  private var hostFuture: GARHostCloudAnchorFuture?

  private var resolvedAnchorIds: [String] = []
  private var resolveFutures: [GARResolveCloudAnchorFuture] = []

  var garSession: GARSession?
  private var arView: ARView?

  // GAR - Google AR, Specifically manages Google-specific AR features that aren't available in Apple's ARKit
  private func createGARSession() -> Bool {
    do {
      garSession = try GARSession(apiKey: Constants.apiKey, bundleIdentifier: nil)
    } catch {
      print("Failed to create GARSession: \(error)")
      return false
    }
    let configuration = GARSessionConfiguration()
    configuration.cloudAnchorMode = .enabled
    var error: NSError? = nil
    garSession?.setConfiguration(configuration, error: &error)
    if let error {
      print("Failed to configure GARSession: \(error)")
      return false
    }
    return true
  }

  // ARWorldTrackingConfiguration is a class from Apple's ARKit framework
  private func runSession(trackPlanes: Bool) {
    let configuration = ARWorldTrackingConfiguration()
    configuration.worldAlignment = .gravity
    if trackPlanes {
      configuration.planeDetection = [.horizontal, .vertical]
    }
    arView?.session.run(configuration, options: .removeExistingAnchors)
  }

  /// Start the `ARSession` when beginning to host or resolve.
  ///
  /// - Parameter arView: The `ARView` instance for this session.
  func startSession(arView: ARView) {
    self.arView = arView
    // Only show planes in hosting mode (when there is no resolved anchor id).
    runSession(trackPlanes: resolvedAnchorIds.isEmpty)
  }

  /// Called when the user taps the "Begin hosting" button. Proceeds to host after checking the
  /// privacy notice.
  func beginHostingButtonPressed() {
    resolvedAnchorIds = []
    checkPrivacyNotice()
  }

  /// Called when the user taps a point on the `ARView`. In the appropriate state, places an anchor
  /// by raycasting to hit a plane.
  ///
  /// - Parameter point: The point that was tapped within the `ARView`'s coordinate space.
  func tapPoint(_ point: CGPoint) {
    /* traditional syntax
      guard
          let arView != nil &&
          let frame = arView.session.currentFrame &&
          frame.camera.trackingState == .normal &&
          resolvedAnchorIds.isEmpty &&
          !placedAnchor
      else { return }
    */
    guard let arView, let frame = arView.session.currentFrame,
      frame.camera.trackingState == .normal, resolvedAnchorIds.isEmpty, !placedAnchor
    else { return }

    // Prefer existing planes to estimated ones.
    let results =
      arView.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .horizontal)
      + arView.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .vertical)
      + arView.raycast(from: point, allowing: .estimatedPlane, alignment: .horizontal)
      + arView.raycast(from: point, allowing: .estimatedPlane, alignment: .vertical)
    
    // If a user taps before any planes are detected, the raycast won't hit anything, and nothing will happen (silent failure).
    // This implicitly forces users to wait, but doesn't explicitly tell them to do so.
    guard let result = results.first else { return }

    isOnHorizontalPlane = (result.targetAlignment == .horizontal)
    let anchorTransform: simd_float4x4
    if isOnHorizontalPlane {
      // Rotate raycast result around y axis to face user.
      // Compute angle between camera position and raycast result's z axis.
      let anchorFromCamera = simd_mul(simd_inverse(result.worldTransform), frame.camera.transform)
      let x = anchorFromCamera.columns.3[0]
      let z = anchorFromCamera.columns.3[2]
      // Angle from the z axis, measured counterclockwise.
      let angle = atan2f(x, z)
      let rotation = simd_quatf(angle: angle, axis: simd_make_float3(0, 1, 0))
      anchorTransform = simd_mul(result.worldTransform, simd_matrix4x4(rotation))
    } else {
      anchorTransform = result.worldTransform
    }
    let anchor = ARAnchor(transform: anchorTransform)
    runSession(trackPlanes: false)  // run the session again. Disable planes when anchor is placed because it is no longer needed.
    arView.session.add(anchor: anchor) // Adds it to the AR session! in coordinate session, it will know this is a special anchor, so the cloud anchor can be placed
    placedAnchor = true
    messageLabel = "Save the object here by capturing it from all sides"
  }

  private static func string(from quality: GARFeatureMapQuality) -> String {
    switch quality {
    case .good:
      return "Good"
    case .sufficient:
      return "Sufficient"
    default:
      return "Insufficient"
    }
  }

  /// Called to process each tracking frame when an anchor is placed but not yet hosted.
  ///
  /// - Parameters:
  ///   - anchor: The current snapshot of the anchor to host.
  ///   - quality: The current feature map quality.
  ///   - averageQuality: The average of the mapping qualities displayed on the indicator.
  ///   - distance: The distance to the anchor.
  /// - Returns: `true` if the anchor was hosted, `false` otherwise.

  /// hostFuture is a property of type GARHostCloudAnchorFuture?,
  /// which represents an asynchronous operation to host (upload) an AR anchor to Google's cloud services.
  /// In simpler terms:
  func processFrame(
    anchor: ARAnchor, quality: GARFeatureMapQuality, averageQuality: Float, distance: Float
  ) -> Bool {
    guard let garSession, hostFuture == nil else { return false }
    debugLabel =
      "Current mapping quality: \(CloudAnchorManager.string(from: quality))"
    if distance > Constants.maxDistance {
      messageLabel = "You are too far; come closer"
    } else if distance < Constants.minDistance {
      messageLabel = "You are too close; move backward"
    } else {
      messageLabel = "Save the object here by capturing it from all sides"
    }

    if averageQuality > Constants.featureMapQualityThreshold {
      do {
        hostFuture = try garSession.hostCloudAnchor(anchor, ttlDays: 1) { // completion handler
          [weak self] anchorId, cloudState in
          guard let self else { return }
          if cloudState == .success {
            self.showAnchorNameDialog = true
            self.anchorNameDialogField = ""
          }
          self.messageLabel = "Finished: \(CloudAnchorManager.string(from: cloudState))"
          if let anchorId {
            self.debugLabel = "Anchor \(anchorId) created"
          } else {
            self.debugLabel = "Anchor failed to host"
          }
        }
        messageLabel = "Processing..."
        debugLabel = "Feature map quality is sufficient, triggering hosting"
      } catch {
        print("Failed to start hosting process: \(error)")
      }
      return true
    }

    return false
  }

  private func backButtonPressed() {
    guard let page = navigationPath.last else { return }
    if page == .host || page == .resolve {
      reset()
    }
  }

  /// Called when the user hits the "Begin resolving" button.
  func beginResolvingButtonPressed() {
    navigationPath.append(.resolvePicker)
  }

  /// Called when the user hits the "Resolve" button. Proceeds to resolve after checking the privacy
  /// notice.
  ///
  /// - Parameter anchorIds: The list of anchor IDs to resolve.
  func resolveButtonPressed(anchorIds: [String]) {
    resolvedAnchorIds = anchorIds
    checkPrivacyNotice()
  }

  /// Called when the user explicitly accepts the privacy notice.
  func acceptPrivacyNotice() {
    UserDefaults.standard.setValue(true, forKey: Constants.privacyNoticeUserDefaultsKey)
    // informs users about camera data processing by Google and requests their permission before using ARCore's Cloud Anchor features.
    // User consent is stored persistently in UserDefaults under the key "PrivacyNoticeAccepted" (defined in Constants.privacyNoticeUserDefaultsKey)
    privacyNoticeAccepted()
  }

  private func privacyNoticeAccepted() {
    // check if the user has resolved anchor ids
    if resolvedAnchorIds.isEmpty {
      hostAnchor() // initialize the variable before the host process
    } else {
      resolveAnchors() // initialize the variable before the resolve process
    } // if the user has resolved anchor ids, resolve the anchors
  }

  private func checkPrivacyNotice() {
    // check if the user has accepted the privacy notice
    if UserDefaults.standard.bool(forKey: Constants.privacyNoticeUserDefaultsKey) {
      privacyNoticeAccepted()
    } else {
      showPrivacyNotice = true
    }
  }

  /// Stores a newly hosted anchor's info after the user enters a name for it.
  func saveAnchor(latitude: Double, longitude: Double, imageData: Data?) {
    guard let anchorId = hostFuture?.resultCloudIdentifier, !anchorNameDialogField.isEmpty else {
      return
    }
//    var timeDictionary =
//      (UserDefaults.standard.dictionary(forKey: Constants.timeDictionaryUserDefaultsKey)
//        as? [String: Date]) ?? [:]
//    var anchorInfoDictionary =
//      (UserDefaults.standard.dictionary(forKey: anchorInfoDictionaryUserDefaultsKey)
//       as? [String: [String: Any]]) ?? [:]
//    timeDictionary[anchorId] = Date()
//    
//    let imageKey = CustomAnchorModelUtil.imageKeyForAnchor(anchorID: anchorId)
//
//      let info: [String: Any] = [
//        "name": anchorNameDialogField,
//        "description": anchorDescriptionDialogField,
//        "latitude": latitude,
//        "longitude": longitude,
//        "imageKey": imageKey
//      ]
//
//    // Save the image data to UserDefaults
//    CustomAnchorModelUtil.saveImageDataToUserDefaults(imageData: imageData, forKey: imageKey)
//      
//    anchorInfoDictionary[anchorId] = info
//    UserDefaults.standard.setValue(timeDictionary, forKey: Constants.timeDictionaryUserDefaultsKey)
//    UserDefaults.standard.setValue(
//      anchorInfoDictionary, forKey: anchorInfoDictionaryUserDefaultsKey)
      let db = Firestore.firestore()
      let imageKey = CustomAnchorModelUtil.imageKeyForAnchor(anchorID: anchorId)
      
      // save the image
      CustomAnchorModelUtil.saveImageDataToUserDefaults(imageData: imageData, forKey: imageKey)
      
      let data: [String: Any] = [
        "name": anchorNameDialogField,
        "description": anchorDescriptionDialogField,
        "latitude": latitude,
        "longitude": longitude,
        "imageKey": imageKey,
        "createdAt": Timestamp(date: Date())
      ]
      
      db.collection("anchors").document(anchorId).setData(data) {error in
          if let error = error {
              print("Error saving anchor: \(error.localizedDescription)")
          } else {
              print("Anchor saved successfully")
          }
      }
  }

  /// Gets the list of stored anchors, sorted by age, and removes any more than a day old and too far from me (1 km away from me).
    func fetchAndPruneAnchors(currentlatitude: Double, currentlongitude: Double, completion: @escaping ([Place]) -> Void){
//        var timeDictionary =
//          (UserDefaults.standard.dictionary(forKey: Constants.timeDictionaryUserDefaultsKey)
//            as? [String: Date]) ?? [:]
//        var anchorInfoDictionary =
//          (UserDefaults.standard.dictionary(forKey: anchorInfoDictionaryUserDefaultsKey)
//            as? [String: [String: Any]]) ?? [:]
//        
//        var infos: [Place] = []
//        let now = Date()
//        let currentLocation = CLLocation(latitude: currentlatitude, longitude: currentlongitude)
//
//        for (id, time) in timeDictionary.sorted(by: { $0.1.compare($1.1) == .orderedDescending }) {
//            let timeInterval = now.timeIntervalSince(time)
//
//            // Prune if over 1 day old
//            if timeInterval >= 86400 {
//                timeDictionary.removeValue(forKey: id)
//                anchorInfoDictionary.removeValue(forKey: id)
//                continue
//            }
//
//            guard let info = anchorInfoDictionary[id] else { continue }
//            guard let name = info["name"] as? String else { continue }
//            guard let description = info["description"] as? String else { continue }
//            guard let lat = info["latitude"] as? Double,
//                  let lon = info["longitude"] as? Double else { continue }
//
//            let anchorLocation = CLLocation(latitude: lat, longitude: lon)
//            let distance = currentLocation.distance(from: anchorLocation)
//
//            // 💡 Only include anchors within 1km (1000 meters)
//            guard distance <= 1000 else { continue }
//
//            let age = timeInterval >= 3600
//                ? "\(Int(floor(timeInterval / 3600)))h"
//                : "\(Int(floor(timeInterval / 60)))m"
//
//            infos.append(Place(id: id, name: name, age: age, description: description, latitude: lat, longitude: lon))
//        }
//
//        UserDefaults.standard.setValue(timeDictionary, forKey: Constants.timeDictionaryUserDefaultsKey)
//        UserDefaults.standard.setValue(anchorInfoDictionary, forKey: anchorInfoDictionaryUserDefaultsKey)
//        
//        return infos
        
        // refactor the code to firebase db
        let db = Firestore.firestore()
        let currentLocation = CLLocation(latitude: currentlatitude, longitude: currentlongitude)
        let now = Date()
        
        db.collection("anchors").getDocuments { snapshot, error in
                var infos: [Place] = []

                if let error = error {
                    print("Error fetching anchors: \(error.localizedDescription)")
                    completion([])
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let batch = db.batch()  // For pruning old/out-of-range anchors

                for document in documents {
                    let data = document.data()
                    guard let name = data["name"] as? String,
                          let description = data["description"] as? String,
                          let lat = data["latitude"] as? Double,
                          let lon = data["longitude"] as? Double,
                          let createdAt = data["createdAt"] as? Timestamp else {
                        continue
                    }

                    let timeInterval = now.timeIntervalSince(createdAt.dateValue())

                    // Prune if older than 3 days
                    if timeInterval >= 86400 * 3 {
                        batch.deleteDocument(document.reference)
                        continue
                    }

                    let anchorLocation = CLLocation(latitude: lat, longitude: lon)
                    let distance = currentLocation.distance(from: anchorLocation)

                    // Prune if farther than 1km
                    if distance > 1000 {
                        continue
                    }

                    let age = timeInterval >= 3600
                        ? "\(Int(floor(timeInterval / 3600)))h"
                        : "\(Int(floor(timeInterval / 60)))m"

                    infos.append(Place(id: document.documentID, name: name, age: age, description: description, latitude: lat, longitude: lon))
                }

                // Commit pruning changes
                batch.commit { err in
                    if let err = err {
                        print("Error pruning anchors: \(err.localizedDescription)")
                    }
                }

                completion(infos)
            }
    }

  private static func string(from cloudState: GARCloudAnchorState) -> String {
    switch cloudState {
    case .none:
      return "None"
    case .success:
      return "Success"
    case .errorInternal:
      return "ErrorInternal"
    case .errorNotAuthorized:
      return "ErrorNotAuthorized"
    case .errorResourceExhausted:
      return "ErrorResourceExhausted"
    case .errorHostingDatasetProcessingFailed:
      return "ErrorHostingDatasetProcessingFailed"
    case .errorCloudIdNotFound:
      return "ErrorCloudIdNotFound"
    case .errorResolvingSdkVersionTooNew:
      return "ErrorResolvingSdkVersionTooNew"
    case .errorResolvingSdkVersionTooOld:
      return "ErrorResolvingSdkVersionTooOld"
    case .errorHostingServiceUnavailable:
      return "ErrorHostingServiceUnavailable"
    default:
      // Not handling deprecated enum values that will never be returned.
      return "Unknown"
    }
  }

  private func resolveAnchors() {
    navigationPath.append(.resolve)
    guard createGARSession(), let garSession else {
      messageLabel = "Resolve failed"
      debugLabel = "Failed to init GARSession"
      return
    }
    messageLabel = "Resolving..."
    debugLabel = "Attempting to resolve \(resolvedAnchorIds.count) anchors"
    
    // Print out all the anchors we're attempting to resolve
    print("Attempting to resolve these cloud anchor IDs:")
    for (index, id) in resolvedAnchorIds.enumerated() {
        print("[\(index)] \(id)")
    }
    
    // Print out all the stored anchor IDs for comparison
    let anchorInfoDictionary = (UserDefaults.standard.dictionary(forKey: anchorInfoDictionaryUserDefaultsKey)
        as? [String: [String: Any]]) ?? [:]
    print("Currently stored anchor IDs in UserDefaults:")
    for (key, _) in anchorInfoDictionary {
        print("Stored: \(key)")
    }
    
    for anchorId in resolvedAnchorIds {
      do {
        resolveFutures.append(
          // Tells GARSession to "look for this anchor in upcoming frames"
          try garSession.resolveCloudAnchor(anchorId) { [weak self] anchor, cloudState in
            guard let self else { return }
            if cloudState == .success {
              self.debugLabel = "Resolved \(anchorId), continuing to refine pose"
              // Check if the resolved anchor has the expected cloud identifier
              if let anchor = anchor {
                print("Successfully resolved anchor with ID \(anchorId)")
                // Store mapping between cloud ID and local anchor ID
                self.cloudToLocalAnchorMap[anchorId] = anchor.identifier
                print("Mapped cloud ID \(anchorId) to local anchor ID \(anchor.identifier)")
              }
            } else {
              self.debugLabel =
                "Failed to resolve \(anchorId): "
                + CloudAnchorManager.string(from: cloudState)
            }
            if self.resolveFutures.allSatisfy({ $0.state == .done }) {
              self.messageLabel = "Resolve finished"
            }
          })
      } catch {
        debugLabel = "Failed to start resolving operation: \(error)"
        print("Error resolving anchor \(anchorId): \(error)")
      }
    }
  }

  private func hostAnchor() {
    placedAnchor = false
    navigationPath.append(.host)
    guard createGARSession() else {
      messageLabel = "Host failed"
      debugLabel = "Failed to init GARSession"
      return
    }
    messageLabel = "Tap to place an object."
    debugLabel = "Tap a vertical or horizontal plane..."
  }

  private func reset() {
    for resolveFuture in resolveFutures {
      resolveFuture.cancel()
    }
    resolveFutures.removeAll()
    hostFuture?.cancel()
    hostFuture = nil
    arView?.session.pause()
    arView = nil
    garSession = nil
  }

  // Method to find cloud ID for local anchor ID
  func findCloudIdentifier(for localAnchorId: UUID) -> String? {
      return cloudToLocalAnchorMap.first(where: { $0.value == localAnchorId })?.key
  }
  
  // Expose a read-only copy of the map for debugging
  var cloudAnchorMapping: [String: UUID] {
      return cloudToLocalAnchorMap
  }
}
