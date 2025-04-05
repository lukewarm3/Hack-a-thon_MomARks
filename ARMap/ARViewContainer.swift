//
//  ARViewContainer.swift
//  ARMap
//
//  Created by Luke Cao on 3/21/25.
//

import ARCore
import ARKit
import RealityKit
import SwiftUI
import simd

/// SwiftUI wrapper for an `ARView` and all rendering code.
struct ARViewContainer: UIViewRepresentable {
  @EnvironmentObject var manager: CloudAnchorManager

  /// Coordinator to act as `ARSessionDelegate` for `ARView`.
  class Coordinator: NSObject, ARSessionDelegate {
    private enum Constants {
      /// Name of USDZ file to load cloud anchor model from.
      static let cloudAnchorName = "cloud_anchor"
      /// Material for rendered planes.
      static let planeMaterial = UnlitMaterial(
        color: UIColor(red: 0, green: 0, blue: 1, alpha: 0.7))
    }

    private let manager: CloudAnchorManager
    fileprivate let arView = ARView(
      frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
    private let worldOrigin = AnchorEntity(world: matrix_identity_float4x4)

    /*
      This dictionary is the key evidence.
      It maps plane anchor IDs to their corresponding model entities. Each detected plane gets its own entry in this dictionary.
      Therefore, there will be a lot of mesh plane that together forms the large mesh
    */
    private var planeModels: [UUID: ModelEntity] = [:]

    private var resolvedModels: [UUID: Entity] = [:]
    private var hostedAnchorId: UUID?
    private var hostedModel: Entity?
    private var qualityIndicator: QualityIndicator?
    private var startedHosting: Bool = false

    fileprivate init(manager: CloudAnchorManager) {
      self.manager = manager
      super.init()
      // The worldOrigin provides a stable, consistent coordinate system reference point in the AR scene
      // Even as the device moves, this origin remains fixed in the virtual world
      arView.scene.addAnchor(worldOrigin)
      arView.session.delegate = self
      manager.startSession(arView: arView)
    }

    private static func createCloudAnchorModel() -> Entity? {
      //
      return try? Entity.load(named: Constants.cloudAnchorName)
    }

    private static func createPlaneMesh(for planeAnchor: ARPlaneAnchor) -> MeshResource? {
      var descriptor = MeshDescriptor()
      // takes the raw vertex data from ARKit's plane detection and converts it to RealityKit's format.
      descriptor.positions = MeshBuffers.Positions(planeAnchor.geometry.vertices)
      descriptor.primitives = .triangles(planeAnchor.geometry.triangleIndices.map { UInt32($0) })
      return try? MeshResource.generate(from: [descriptor])
    }

    private static func createPlaneModel(for planeAnchor: ARPlaneAnchor) -> ModelEntity? {
      guard let mesh = createPlaneMesh(for: planeAnchor) else {
        return nil
      }
      return ModelEntity(mesh: mesh, materials: [Constants.planeMaterial])
    }

    private static func updatePlaneModel(_ model: ModelEntity, planeAnchor: ARPlaneAnchor) {
      guard let planeMesh = createPlaneMesh(for: planeAnchor) else {
        return
      }
      /*
          ModelEntity is an entity (node in the scene graph)
          ModelEntity has a ModelComponent accessible through the .model property
          ModelComponent has a MeshResource accessible through the .mesh property

          The app doesn't merge all planes into a single mesh.
          Instead, it maintains separate plane visualizations for each detected plane.
      */
      model.model?.mesh = planeMesh
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
      for anchor in anchors {
        if anchor is AREnvironmentProbeAnchor { continue }
          // the ARPlaneAnchor will be added to the ARSession if ARSession has plane detection (configuration.planeDetection = [.horizontal, .vertical])
        if let planeAnchor = (anchor as? ARPlaneAnchor) {
          guard let model = Coordinator.createPlaneModel(for: planeAnchor) else { continue }
          planeModels[planeAnchor.identifier] = model
          let anchorEntity = AnchorEntity(.anchor(identifier: anchor.identifier)) // anchor.identifier == planeAnchor.identifier
          anchorEntity.addChild(model)
          arView.scene.addAnchor(anchorEntity)
          continue
        }
        //guard let model = Coordinator.createCloudAnchorModel() else { continue }
          guard let model = CustomAnchorModelUtil.createPaperModel(title:"Enter Your Title Later", description: "Enter Your Description Later") else {continue}
        hostedModel = model
        hostedAnchorId = anchor.identifier
        let anchorEntity = AnchorEntity(.anchor(identifier: anchor.identifier))
        anchorEntity.addChild(model)
        qualityIndicator = QualityIndicator(
          parent: model, isOnHorizontalPlane: manager.isOnHorizontalPlane)
        arView.scene.addAnchor(anchorEntity)
      }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
      for anchor in anchors {
        guard let planeAnchor = (anchor as? ARPlaneAnchor) else { continue }
        guard let model = planeModels[planeAnchor.identifier] else { continue }
        Coordinator.updatePlaneModel(model, planeAnchor: planeAnchor) // update the plane model of the same identifier
      }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
      for anchor in anchors {
        guard let planeAnchor = (anchor as? ARPlaneAnchor) else { continue }
        let model = planeModels.removeValue(forKey: planeAnchor.identifier)
        model?.parent?.removeFromParent()
      }
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
      /*
        GARSession needs the frame to be updated because:
            Extract visual features for creating stable anchors
            Evaluate the environment's suitability for hosting
            Calculate a quality score for the current view
      */

      // This part is used for resolving cloud anchor
      //Returns a garFrame containing any resolved anchors it found
      guard let garSession = manager.garSession, let garFrame = try? garSession.update(frame) else {
        return
      }
      for garAnchor in garFrame.anchors {
        // Use the same resolved anchor if we already have it
        if let model = resolvedModels[garAnchor.identifier] {
          model.transform = Transform(matrix: garAnchor.transform)
          continue
        }
        
        // Find the cloud identifier using our mapping
        guard let cloudIdentifier = manager.findCloudIdentifier(for: garAnchor.identifier) else {
          print("Cannot find cloud ID for local anchor ID: \(garAnchor.identifier)")
          continue
        }
        
        print("Found GARAnchor with local ID: \(garAnchor.identifier), mapped to cloud ID: \(cloudIdentifier)")
        
        // Get anchor info from UserDefaults
        var anchorInfoDictionary =
          (UserDefaults.standard.dictionary(forKey: manager.anchorInfoDictionaryUserDefaultsKey)
             as? [String: [String: Any]]) ?? [:]

        // Debug: list all stored anchor IDs
        if !anchorInfoDictionary.isEmpty {
            print("Anchor IDs in UserDefaults:")
            for (key, _) in anchorInfoDictionary {
                print("  - \(key)")
            }
        }
        
          guard let info = anchorInfoDictionary[cloudIdentifier] else {
              print("Cannot find anchor with cloud ID \(cloudIdentifier) in UserDefaults")
              continue
          }
          
          print("Found anchor info for cloud ID: \(cloudIdentifier)")
          
          //guard let info = anchorInfoDictionary[garidentifier.uuidString] else { print("Cannot find the anchor id in UserDefaults"); continue }
          guard let name = info["name"] as? String else { continue }
          guard let description = info["description"] as? String else { continue }
          guard let imageKey = info["imageKey"] as? String else { continue }

          guard let model = CustomAnchorModelUtil.createPaperModelWithImageFromUserDefaults(title:name, description: description, imageKey: imageKey) else {continue}
          resolvedModels[garAnchor.identifier] = model
          model.transform = Transform(matrix: garAnchor.transform)
          worldOrigin.addChild(model)
      }

        // this part is used to host cloud anchor
      guard !startedHosting, frame.camera.trackingState == .normal, let hostedAnchorId, // the hostedAnchorId is added by the ARKit session
        let qualityIndicator,
        let anchor = frame.anchors.first(where: { $0.identifier == hostedAnchorId })
      else { return }
      let quality =
        (try? garSession.estimateFeatureMapQualityForHosting(frame.camera.transform))
        ?? .insufficient
      let anchorFromCamera = simd_mul(simd_inverse(anchor.transform), frame.camera.transform)
      let (averageQuality, distance) = qualityIndicator.update(
        quality: quality, anchorFromCamera: anchorFromCamera)
      let didHost = manager.processFrame(
        anchor: anchor, quality: quality, averageQuality: averageQuality, distance: distance)
      if didHost {
        startedHosting = true
      }
    }
  }

  func makeUIView(context: Context) -> ARView {
    return context.coordinator.arView
  }

  func updateUIView(_ uiView: ARView, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(manager: manager)
  }
}
