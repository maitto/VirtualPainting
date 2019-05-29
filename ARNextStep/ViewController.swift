//
//  ViewController.swift
//  ARNextStep
//
//  Created by Mortti Aittokoski on 10/08/2018.
//  Copyright © 2018 Mortti Aittokoski. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var paintingNode: SCNNode?
    var paintingAdjusterNode: SCNNode?
    var baseboardAnchor: ARAnchor?
    var baseboardLineNode: SCNNode?
    
    var guideLabel: UILabel! = nil
    
    var paintingState = PaintingState.noNodesSet
    var cameraTrackingState = ARCamera.TrackingState.notAvailable
    
    var nodeAndAnchorService = NodeAndAnchorService()
    
    enum PaintingState {
        case noNodesSet
        case baseboardNodeSet
        case paintingNodeSet
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/theScene.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.session.delegate = self
        
        initApp()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.debugOptions = [SCNDebugOptions.showFeaturePoints]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //// Init and reset app
    
    func initApp() {
        addGuideLabel()
        updateGuideText()
        addBaseboardLineNode()
    }
    
    func resetApp() {
        paintingState = PaintingState.noNodesSet
        removePaintingNode()
        removePaintingAdjusterNode()
        baseboardAnchor = nil
        
        if case .normal = cameraTrackingState {
            addBaseboardLineNode()
        } else {
            removeBaseboardLineNode()
        }
        
        updateGuideText()
    }
    
    
    //// Guide label
    
    func addGuideLabel() {
        guideLabel = UILabel()
        guideLabel.font = guideLabel.font.withSize(20)
        view.addSubview(guideLabel)
        guideLabel.translatesAutoresizingMaskIntoConstraints = false
        guideLabel.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor).isActive = true
        guideLabel.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        
        guideLabel.layer.masksToBounds = true
        guideLabel.layer.cornerRadius = 5
        
        guideLabel.numberOfLines = 0
        guideLabel.textAlignment = .center
        
        let views = ["guideLabel": guideLabel] as [String : Any]
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-40-[guideLabel]->=40-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views)
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|->=5-[guideLabel]->=5-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        NSLayoutConstraint.activate(constraints)
    }
    
    func setGuideText(_ text:String) {
        if text == "" {
            guideLabel.isHidden = true
        } else {
            guideLabel.isHidden = false
            guideLabel.text = " \(text) "
        }
    }
    
    
    //// Add and remove nodes
    
    func addPaintingAdjusterNode() {
        guard let camera = sceneView.session.currentFrame?.camera, let baseboardAnchor = baseboardAnchor else {
            print("NIL ERROR, addPaintingAdjusterNode")
            resetApp()
            return
        }
        
        let paintingAdjusterNode = nodeAndAnchorService.getPaintingAdjusterNode(camera: camera, baseboardAnchor: baseboardAnchor)
        
        sceneView.pointOfView?.addChildNode(paintingAdjusterNode)
        self.paintingAdjusterNode = paintingAdjusterNode
    }
    
    func removePaintingAdjusterNode() {
        paintingAdjusterNode?.removeFromParentNode()
        paintingAdjusterNode = nil
    }
    
    func addBaseboardLineNode() {
        let baseboardLineNode = nodeAndAnchorService.getBaseboardLineNode()
        
        sceneView.pointOfView?.addChildNode(baseboardLineNode)
        self.baseboardLineNode = baseboardLineNode
    }
    
    func addPaintingNode() {
        guard let baseboardAnchor = baseboardAnchor, let camera = sceneView.session.currentFrame?.camera else {
            print("NIL ERROR baseboardAnchor")
            resetApp()
            return
        }
        let paintingNode = nodeAndAnchorService.getPaintingNode(baseboardAnchor, camera)
        
        sceneView.scene.rootNode.addChildNode(paintingNode)
        self.paintingNode = paintingNode
    }
    
    func removePaintingNode() {
        paintingNode?.removeFromParentNode()
        paintingNode = nil
    }
    
    func removeBaseboardLineNode() {
        baseboardLineNode?.removeFromParentNode()
        baseboardLineNode = nil
    }
    
    func addBaseboardAnchor(atPoint point: CGPoint) {
        let hits = sceneView.hitTest(point, types: .estimatedHorizontalPlane)
        if hits.count > 0, let lastHit = hits.last {
            guard let camera = sceneView.session.currentFrame?.camera else {
                print("NIL ERROR, addBaseboardAnchor")
                resetApp()
                return
            }
            
            let baseboardAnchor = nodeAndAnchorService.getBaseboardAnchor(lastHit: lastHit, camera: camera)
            sceneView.session.add(anchor: baseboardAnchor)
            self.baseboardAnchor = baseboardAnchor
        } else {
            print("ERROR no hits from hitTest")
            resetApp()
        }
    }
    
    
    //// State Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if case .normal = cameraTrackingState {
            switch paintingState {
            case .noNodesSet:
                addBaseboardAnchor(atPoint: view.center)
                removeBaseboardLineNode()
                addPaintingAdjusterNode()
                setPaintingState(.baseboardNodeSet)
            case .baseboardNodeSet:
                addPaintingNode()
                removePaintingAdjusterNode()
                setPaintingState(.paintingNodeSet)
            default:
                removePaintingNode()
                baseboardAnchor = nil
                addBaseboardLineNode()
                setPaintingState(.noNodesSet)
            }
        } else {
            print("ERROR camera state not normal, touchesBegan")
            resetApp()
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        cameraTrackingState = camera.trackingState
        if case .normal = camera.trackingState {
            setNodesHidden(false)
        } else {
            setNodesHidden(true)
        }
        updateGuideText()
    }
    
    func updateGuideText() {
        if case .normal = cameraTrackingState {
            switch paintingState {
            case .noNodesSet:
                setGuideText("Align the white line with the baseboard \n and tap the screen")
            case .baseboardNodeSet:
                setGuideText("Lift the paingting on the wall \n and tap the screen")
            default:
                setGuideText("Remove the painting by tapping the screen")
            }
        } else {
            setGuideText("Point towards the floow and move the phone")
        }
    }
    
    func setPaintingState(_ state: PaintingState) {
        paintingState = state
        updateGuideText()
    }
    
    func setNodesHidden(_ hidden: Bool) {
        paintingNode?.isHidden = hidden
        paintingAdjusterNode?.isHidden = hidden
        baseboardLineNode?.isHidden = hidden
    }
}
