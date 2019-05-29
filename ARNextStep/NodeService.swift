//
//  NodeService.swift
//  ARNextStep
//
//  Created by Mortti Aittokoski on 23/09/2018.
//  Copyright © 2018 Mortti Aittokoski. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class NodeAndAnchorService {
    fileprivate func getPaintingNode(transparency: CGFloat) -> SCNNode {
        let pictureMaterial = SCNMaterial()
        pictureMaterial.diffuse.contents = UIImage(named: "art.scnassets/Mona_Lisa-restored.jpg")!
        pictureMaterial.transparency = transparency
        let whiteMaterial = SCNMaterial()
        whiteMaterial.diffuse.contents = UIColor.white.withAlphaComponent(0.8)
        
        let paintingGeometry = SCNBox(width: 0.53, height: 0.77, length: 0.03, chamferRadius: 0.0)
        paintingGeometry.materials.insert(pictureMaterial, at: 0)
        paintingGeometry.materials.insert(whiteMaterial, at: 1)
        paintingGeometry.materials.insert(whiteMaterial, at: 2)
        paintingGeometry.materials.insert(whiteMaterial, at: 3)
        paintingGeometry.materials.insert(whiteMaterial, at: 4)
        paintingGeometry.materials.insert(whiteMaterial, at: 5)
        
        let paitingNode = SCNNode(geometry: paintingGeometry)
        
        return paitingNode
    }
    
    func getPaintingNode(_ baseboardAnchor: ARAnchor,_ camera: ARCamera) -> SCNNode {
        let anchorMat = SCNMatrix4(baseboardAnchor.transform)
        let anchorPosition = SCNVector3(anchorMat.m41, anchorMat.m42, anchorMat.m43)
        let cameraMat = SCNMatrix4(camera.transform)
        let cameraPosition = SCNVector3(cameraMat.m41, cameraMat.m42, cameraMat.m43)
        
        // y-axis distance between camera and floor
        let cameraHeight = cameraPosition.y - anchorPosition.y
        
        let paintingNode = getPaintingNode(transparency: 1.0)
        //set paintingNode transform from baseboardAnchor
        paintingNode.transform = SCNMatrix4(baseboardAnchor.transform)
        //set the y position to match the cameras
        paintingNode.position.y = cameraPosition.y
        
        let distanceFromWall = Utils.distanceFrom(vector: cameraPosition, toVector: paintingNode.position)
        let cameraAngle = camera.eulerAngles.x
        //calculate height from floor to point where camera is facing based on the phone tilt
        let paintingHeightFromFloor = cameraHeight + distanceFromWall * tan(cameraAngle)
        
        paintingNode.position.y = anchorPosition.y + paintingHeightFromFloor
        
        return paintingNode
    }
    
    func getBaseboardAnchor(lastHit: ARHitTestResult, camera: ARCamera) -> ARAnchor {
        let rotate = simd_float4x4(SCNMatrix4MakeRotation(camera.eulerAngles.y, 0, 1, 0))
        let rotateTransform = simd_mul(lastHit.worldTransform, rotate)

        let wallboardAnchor = ARAnchor(transform: rotateTransform)
        
        return wallboardAnchor
    }
    
    func getBaseboardLineNode() -> SCNNode {
        let lineGeometry = SCNPlane(width: 0.1, height: 0.002)
        lineGeometry.cornerRadius = 2.0
        
        let whiteMaterial = SCNMaterial()
        whiteMaterial.diffuse.contents = UIColor.white
        lineGeometry.firstMaterial = whiteMaterial
        
        let baseboardNode = SCNNode(geometry: lineGeometry)
        baseboardNode.position = SCNVector3Make(0, 0, -0.2)
        
        return baseboardNode
    }
    
    func getPaintingAdjusterNode(camera: ARCamera, baseboardAnchor: ARAnchor) -> SCNNode {
        var helperTransform = baseboardAnchor.transform
        helperTransform.columns.3.y = camera.transform.columns.3.y
        let helperAnchor = ARAnchor(transform: helperTransform)
        
        let cameraMat = SCNMatrix4(camera.transform)
        let cameraPosition = SCNVector3(cameraMat.m41, cameraMat.m42, cameraMat.m43)
        
        let anchorMat = SCNMatrix4(helperAnchor.transform)
        let anchorPosition = SCNVector3(anchorMat.m41, anchorMat.m42, anchorMat.m43)

        let distanceFromWall = Utils.distanceFrom(vector: cameraPosition, toVector: anchorPosition)
        
        let paintingAdjusterNode = getPaintingNode(transparency: 0.5)
        paintingAdjusterNode.position = SCNVector3Make(0, 0, -distanceFromWall)
        
        return paintingAdjusterNode
    }
}
