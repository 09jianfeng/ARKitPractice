//
//  ViewController.swift
//  ARKitHorizontalPlaneDemo
//
//  Created by Jayven Nhan on 11/14/17.
//  Copyright © 2017 Jayven Nhan. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment to configure lighting
         configureLighting()
        
        addTapGestureToSceneView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func setUpSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.addShipToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func addShipToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        guard let hitTestResult = hitTestResults.first else { return }
        let translation = hitTestResult.worldTransform.translation
        let x = translation.x
        let y = translation.y
        let z = translation.z
        
        guard let shipScene = SCNScene(named: "ship.scn"),
            let shipNode = shipScene.rootNode.childNode(withName: "ship", recursively: false)
            else { return }
        
        
        shipNode.position = SCNVector3(x,y,z)
        sceneView.scene.rootNode.addChildNode(shipNode)
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension UIColor {
    open class var transparentLightBlue: UIColor {
        return UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.50)
    }
}

extension ViewController: ARSCNViewDelegate {
    /*
     If you’d like, you can also set sceneView’s debug options to show feature points in the world. This could help you find a place with enough feature points to detect a horizontal plane. A horizontal plane is made up of many feature points. Once enough feature points has been detected to recognize a horizontal surface, renderer(_:didAdd:for:) will be called.
     
     This protocol method gets called every time the scene view’s session has a new ARAnchor added.An ARAnchor is an object that represents a physical location and orientation in 3D space.We will use the ARAnchor later for detecting a horizontal plane.
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // We safely unwrap the anchor argument as an ARPlaneAnchor to make sure that we have information about a detected real world flat surface at hand.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Here, we create an SCNPlane to visualize the ARPlaneAnchor. A SCNPlane is a rectangular “one-sided” plane geometry. We take the unwrapped ARPlaneAnchor extent’s x and z properties and use them to create an SCNPlane. An ARPlaneAnchor extent is the estimated size of the detected plane in the world. We extract the extent’s x and z for the height and width of our SCNPlane. Then we give the plane a transparent light blue color to simulate a body of water.
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        plane.materials.first?.diffuse.contents = UIColor.transparentLightBlue
        
        // We initialize a SCNNode with the SCNPlane geometry we just created.
        let planeNode = SCNNode(geometry: plane)
        
        //We initialize x, y, and z constants to represent the planeAnchor’s center x, y, and z position. This is for our planeNode’s position. We rotate the planeNode’s x euler angle by 90 degrees in the counter-clockerwise direction, else the planeNode will sit up perpendicular to the table. And if you rotate it clockwise, David Blaine will perform a magic illusion because SceneKit renders the SCNPlane surface using the material from one side by default.
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        //Finally, we add the planeNode as the child node onto the newly added SceneKit node.
        node.addChildNode(planeNode)
    }
    
    //This method gets called every time a SceneKit node’s properties have been updated to match its corresponding anchor. This is where ARKit refines(精确) its estimation of the horizontal plane’s position and extent.
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        // 3
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
    
    
}
