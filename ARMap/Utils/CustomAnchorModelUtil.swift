//
//  CustomAnchorModels.swift
//  ARMap
//
//  Created by Luke Cao on 3/22/25.
//

import RealityKit
import SwiftUI
import CoreGraphics

struct CustomAnchorModelUtil {
    
    static func createPaperModel(title: String, description: String) -> ModelEntity? {
        // 1) Create a plane to serve as the "paper"
        let planeWidth: Float = 0.4
        let planeHeight: Float = 0.4
        let planeMesh = MeshResource.generatePlane(width: planeWidth, height: planeHeight)
        
        // White material
        var paperMaterial = SimpleMaterial()
        paperMaterial.color = .init(tint: .white, texture: nil)
        
        // The main paper entity
        let paperEntity = ModelEntity(mesh: planeMesh, materials: [paperMaterial])
        
        paperEntity.position.y = 0.2
        
        // 2) Create the title text entity, add it to the plane
        let titleEntity = makeTextEntity(
            text: title,
            fontSize: 24,          // Larger font
            containerWidth: 300,   // Wrap width in 'points'
            containerHeight: 100  
        )
        paperEntity.addChild(titleEntity)
//        print("paper entity position x y z:", paperEntity.position.x, paperEntity.position.y, paperEntity.position.z)
//        print("title entity position x y z:", titleEntity.position.x, titleEntity.position.y, titleEntity.position.z) // 0.0 0.0 0.0
        
//        // Re-center its pivot so bounding box is at (0,0)
        recenterPivot(for: titleEntity, relativeTo: paperEntity)
//        print("after center pivot")
//        print("paper entity position x y z:", paperEntity.position.x, paperEntity.position.y, paperEntity.position.z)
        
        /*
         title is "Hello"
         -0.14996485 -0.04586133 0.0
         
         title is "HelloHello..."
         -0.14951953 -0.031541016 0.0
         
         */
//        print("title entity position x y z:", titleEntity.position.x, titleEntity.position.y, titleEntity.position.z)
//        // Now measure the bounding box again, after pivot is centered
        let titleBounds = titleEntity.visualBounds(relativeTo: paperEntity)
//        
//        // Place the title near the top of the plane
//        // planeHeight/2 is the top edge; subtract a top margin
//        // If the text is centered around its pivot, then half its height extends above pivot
        
        /*
         let titleBounds = titleEntity.visualBounds(relativeTo: paperEntity)
            titleBounds.center is the center coordinate of the titleEntity in the parent space
            titleBounds.extents is the bounding box (width, height, depth) of the titleEntity in the parent space
         */
        let topMargin: Float = 0.1
        titleEntity.position.y = (planeHeight / 2) - topMargin - (titleBounds.extents.y / 2)
        titleEntity.position.z = 0.001
//        print("after some adjustment of title entity")
        /*
         title is "Hello"
         titleEntity.position: -0.14996485 0.09106445 0.001, titleBounds.extents: 0.058265634 0.017871097 1.0000001e-06
         
         title is "HelloHello..."
         titleEntity.position: -0.14963965 0.0825581 0.001, titleBounds.extents: 0.29204297 0.034883797 1.0000001e-06, y is larger because the text is wrapped
         
         */
//        print("title entity position x y z:", titleEntity.position.x, titleEntity.position.y, titleEntity.position.z)
//        print("title bounds extent x y z:", titleBounds.extents.x, titleBounds.extents.y, titleBounds.extents.z)
        
        // 3) Create the description text entity, add it below the title
        let descEntity = makeTextEntity(
            text: description,
            fontSize: 18,
            containerWidth: 300,
            containerHeight: 100
        )
        paperEntity.addChild(descEntity)
//        
        recenterPivot(for: descEntity, relativeTo: paperEntity)
//        print("--------------------------------------------------")
//        print("descEntity position x y z:", descEntity.position.x, descEntity.position.y, descEntity.position.z)
        // -0.14957812 -0.1894839 0.0
        
        let descBounds = descEntity.visualBounds(relativeTo: paperEntity)
        
//        let deltaY = titleEntity.position.y - descEntity.position.y
//        print("title bounds center y is \(titleEntity.position.y), desc bounds center y is \(descEntity.position.y)")
//        print("delta Y is", deltaY)
//        descEntity.position.y += deltaY
//        print("--------------------------------------------------")
//        print("titleEntity position x y z:", titleEntity.position.x, titleEntity.position.y, titleEntity.position.z)
//        print("descEntity position x y z:", descEntity.position.x, descEntity.position.y, descEntity.position.z)
        let spacing: Float = 0.02
        descEntity.position.y = (titleEntity.position.y
                                 - (titleBounds.extents.y / 2)
                                 - spacing
                                 - (descBounds.extents.y / 2))
        descEntity.position.z = 0.001
        /*
         title is "This is descriptionThis is descriptionThis is description"
         descEntity.position: -0.1494375 0.005424794 0.001 , descBounds.extents: 0.27165234 0.07938282 1.0000001e-06
         
         */
//        print("after the adjust")
//        print("descEntity position x y z:", descEntity.position.x, descEntity.position.y, descEntity.position.z)
//        print("descEntity bounds extent x y z:", descBounds.extents.x, descBounds.extents.y, descBounds.extents.z)
        
        
        return paperEntity
    }
    
    /// Creates a paper model with image data stored in UserDefaults
    static func createPaperModelWithImageFromUserDefaults(title: String, description: String, imageKey: String) -> ModelEntity? {
        // Try to retrieve the image data from UserDefaults
        guard let imageData = UserDefaults.standard.data(forKey: imageKey) else {
            print("No image data found in UserDefaults for key: \(imageKey)")
            // Fall back to the basic model without an image
            return createPaperModel(title: title, description: description)
        }
        
        // Create the basic paper model with title and description
        guard let paperEntity = createPaperModel(title: title, description: description) else {
            return nil
        }
        
        // Find the description entity to position the image relative to it
        guard let descEntity = paperEntity.children.first(where: { $0 != paperEntity.children.first }) as? ModelEntity else {
            // If we can't find the description entity, return the basic paper model
            return paperEntity
        }
        
        // Get the bounds of the description entity to position the image below it
        let descBounds = descEntity.visualBounds(relativeTo: paperEntity)
        
        // Create a plane for the image
        let imageWidth: Float = 0.3  // Slightly smaller than the paper width
        let imageHeight: Float = 0.2
        let imagePlane = MeshResource.generatePlane(width: imageWidth, height: imageHeight)
        
        // Create material with the image texture
        var imageMaterial = SimpleMaterial()
        
        // Try to create a temporary file and load it as a texture
        do {
            // Create a temporary file
            let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
            
            // Write the image data to the temporary file
            try imageData.write(to: temporaryFileURL)
            
            // Load the texture from the file URL
            let texture = try TextureResource.load(contentsOf: temporaryFileURL)
            imageMaterial.color = .init(tint: .white, texture: .init(texture))
            
            // Clean up the temporary file
            try? FileManager.default.removeItem(at: temporaryFileURL)
            
        } catch {
            // Fallback if image can't be processed
            imageMaterial.color = .init(tint: .gray, texture: nil)
            print("Couldn't process image from UserDefaults: \(error.localizedDescription)")
        }
        
        // Create the image entity
        let imageEntity = ModelEntity(mesh: imagePlane, materials: [imageMaterial])
        paperEntity.addChild(imageEntity)
        
        // Position the image below the description with spacing
        let imageSpacing: Float = 0.03
        imageEntity.position.y = descEntity.position.y - (descBounds.extents.y / 2) - imageSpacing - (imageHeight / 2)
        imageEntity.position.z = 0.001  // Slightly in front of the paper
        
        return paperEntity
    }
    
    /// Utility function to save image data to UserDefaults
    static func saveImageDataToUserDefaults(imageData: Data?, forKey key: String) {
        guard let imageData else {
            print("No image data to save")
            return
        }
        UserDefaults.standard.set(imageData, forKey: key)
    }
    
    /// Utility function to retrieve image data from UserDefaults
    static func getImageDataFromUserDefaults(forKey key: String) -> Data? {
        return UserDefaults.standard.data(forKey: key)
    }
    
    /// Generates a consistent image key for a given anchor ID
    static func imageKeyForAnchor(anchorID: String) -> String {
        return "anchor_image_\(anchorID)"
    }

    /// Generates a ModelEntity for text, with wrapping & uniform scaling.
    private static func makeTextEntity(
        text: String,
        fontSize: CGFloat,
        containerWidth: CGFloat,
        containerHeight: CGFloat
    ) -> ModelEntity {
        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: fontSize),
            containerFrame: CGRect(x: 0, y: 0, width: containerWidth, height: containerHeight),
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        
        var material = SimpleMaterial()
        material.color = .init(tint: .black, texture: nil)
        
        let textEntity = ModelEntity(mesh: mesh, materials: [material])
        
        // Scale: 300 "points" -> ~0.3 meters if scale is 0.001
        textEntity.scale = SIMD3<Float>(repeating: 0.001)
        
        return textEntity
    }
    
    /// Adjust the entity's position so that its bounding box is centered at (0,0,0).
    private static func recenterPivot(for entity: ModelEntity, relativeTo parent: Entity) {
        // Measure the bounding box in parent's coordinate space
        let bounds = entity.visualBounds(relativeTo: parent)
        print("Bounds: ", bounds.center)
        // SIMD3<Float>(0.14951953, 0.045603517, 0.0) when title = "H" or "HelloHelloHelloHello"
        
        // Shift the entity so that the bounding box center is at (0,0,0)
        entity.position.x -= bounds.center.x
        entity.position.y -= bounds.center.y
        entity.position.z -= bounds.center.z
    }
}
