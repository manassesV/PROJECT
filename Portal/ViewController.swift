//
//  ViewController.swift
//  Portal
//
//  Created by perfil on 26/06/19.
//  Copyright © 2019 perfil. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    var portalNode: SCNNode?
    var isPortalPlaced = false
    var debugPlanes: [SCNNode] = []
    
    
    let positionY: CGFloat = -0.25
    let positionZ: CGFloat = -0
    let doorWidth:CGFloat = 1.0
    let doorHeight:CGFloat = 2.4
    
    let wallWidth: CGFloat = 0.1
    let wallHeight: CGFloat = 3.0
    let wallLength: CGFloat = 3.0
    
    let floorCeilingLength: CGFloat = 3.0
    let floorCeilingHeight: CGFloat = 0.1
    let floorCeilingWidth: CGFloat = 3.0
    

    
    
    @IBOutlet weak var viCross: UIView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad() 
        
        runSession()
    }
    
    
    func runSession(){
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [ARSession.RunOptions.removeExistingAnchors])
        
        
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.delegate = self
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let hitTest = self.sceneView.hitTest(self.view.center, types:ARHitTestResult.ResultType.existingPlaneUsingExtent).first{
         
            sceneView.session.add(anchor: ARAnchor(transform: hitTest.worldTransform))
            
            
        }
    }
    
    func createPlaneNode(center: vector_float3, extent: vector_float3) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
        
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents =
           UIColor.yellow.withAlphaComponent(0.3)
        plane.materials = [planeMaterial]
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(center.x, 0, center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        return planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            if let _ = self.sceneView.hitTest(self.view.center, types:ARHitTestResult.ResultType.existingPlaneUsingExtent).first{
                self.viCross.backgroundColor = .green
            }else{
                self.viCross.backgroundColor = .white
            }
        }
        
  
    }

    func makePortal() -> SCNNode {
        let portal = SCNNode()
        
        let floorNode = makeFloorNode()
        floorNode.position = SCNVector3(0, positionY, positionZ)
        portal.addChildNode(floorNode)
        
        let ceilingNode = makeCeilingNode()
        ceilingNode.position = SCNVector3(0, positionY + wallHeight, positionZ)
        portal.addChildNode(ceilingNode)
        
        let farWallNode = makeWallNode()
        farWallNode.eulerAngles = SCNVector3(0, 90.0.degreesToRadians, 0)
        farWallNode.position = SCNVector3(0, positionY + wallHeight * 0.5, positionZ - floorCeilingLength * 0.5)
        portal.addChildNode(farWallNode)
        
        let rightSideWallNode = makeWallNode(maskLowerSide: true)
        rightSideWallNode.eulerAngles = SCNVector3(0, 180.0.degreesToRadians, 0)
        rightSideWallNode.position = SCNVector3(wallLength*0.5, positionY+wallHeight*0.5, positionZ)
        portal.addChildNode(rightSideWallNode)
        
        let leftSideWallNode = makeWallNode(maskLowerSide: true)
        leftSideWallNode.position = SCNVector3(-wallLength*0.5, positionY+wallHeight*0.5, positionZ)
        portal.addChildNode(leftSideWallNode)
        
        addDoorway(node: portal)
        placeLightSource(rootNode: portal)
        return portal
    }
    
    func removeDebugPlanes() {
        for debugPlane in debugPlanes {
            debugPlane.removeFromParentNode()
        }
        debugPlanes = []
        
    }
    
    func makeFloorNode() -> SCNNode {
        let outerFloorNode = makeOuterSurfaceNode(width: floorCeilingWidth, height: floorCeilingHeight, length: floorCeilingLength)
        outerFloorNode.position = SCNVector3(0, -floorCeilingHeight, 0)
        let floorNode = SCNNode()
        floorNode.addChildNode(outerFloorNode)
        
        let innerFloor = SCNBox(width: floorCeilingWidth, height: floorCeilingHeight, length: floorCeilingLength, chamferRadius: 0)
        innerFloor.firstMaterial?.lightingModel = .physicallyBased
        innerFloor.firstMaterial?.diffuse.contents = UIImage(named: "Assets.Portal/floor/textures/Floor_Diffuse.png")
        innerFloor.firstMaterial?.normal.contents = UIImage(named: "Assets.Portal/floor/textures/Floor_Normal.png")
        innerFloor.firstMaterial?.roughness.contents = UIImage(named: "Assets.Portal/floor/textures/Floor_Roughness.png")
        innerFloor.firstMaterial?.specular.contents = UIImage(named: "Assets.Portal/floor/textures/Floor_Specular.png")
        innerFloor.firstMaterial?.selfIllumination.contents =  UIImage(named: "Assets.Portal/floor/textures/Floor_Gloss.png")
        let innerFloorNode = SCNNode(geometry: innerFloor)
        innerFloorNode.renderingOrder = 100
        innerFloorNode.position = SCNVector3(0, 0, 0)
        floorNode.addChildNode(innerFloorNode)
        return floorNode
    }
    
    func makeOuterSurfaceNode(width: CGFloat, height: CGFloat, length: CGFloat) -> SCNNode {
        let outerSurface = SCNBox(width: floorCeilingWidth, height: floorCeilingHeight, length: floorCeilingLength, chamferRadius: 0)
        outerSurface.firstMaterial?.diffuse.contents = UIColor.white
        outerSurface.firstMaterial?.transparency = 0.000001
        let outerSurfaceNode = SCNNode(geometry: outerSurface)
        outerSurfaceNode.renderingOrder = 10
        return outerSurfaceNode
    }
    
    func makeCeilingNode() -> SCNNode {
        let outerCeilingNode = makeOuterSurfaceNode(width: floorCeilingWidth, height: floorCeilingHeight, length: floorCeilingLength)
        outerCeilingNode.position = SCNVector3(0, floorCeilingHeight, 0)
        
        let ceilingNode = SCNNode()
        ceilingNode.addChildNode(outerCeilingNode)
        
        let innerCeiling = SCNBox(width: floorCeilingWidth, height: floorCeilingHeight, length: floorCeilingLength, chamferRadius: 0)
        innerCeiling.firstMaterial?.lightingModel = .physicallyBased
        innerCeiling.firstMaterial?.diffuse.contents = UIImage(named: "Assets.Portal/ceiling/textures/Ceiling_Diffuse.png")
        innerCeiling.firstMaterial?.emission.contents = UIImage(named: "Assets.Portal/ceiling/textures/Ceiling_Emis.png")
        innerCeiling.firstMaterial?.normal.contents = UIImage(named: "Assets.Portal/ceiling/textures/Ceiling_Normal.png")
        innerCeiling.firstMaterial?.specular.contents = UIImage(named: "Assets.Portal/ceiling/textures/Ceiling_Specular.png")
        innerCeiling.firstMaterial?.selfIllumination.contents = UIImage(named: "Assets.Portal/ceiling/textures/Ceiling_Gloss.png")
        let innerCeilingNode = SCNNode(geometry: innerCeiling)
        innerCeilingNode.renderingOrder = 100
        innerCeilingNode.position = SCNVector3(0, 0, 0)
        ceilingNode.addChildNode(innerCeilingNode)
        return ceilingNode
    }
    
    func makeWallNode(length: CGFloat = 3.0, height: CGFloat = 3.0, maskLowerSide:Bool = false) -> SCNNode {
        let outerWall = SCNBox(width: wallWidth, height: height, length: length, chamferRadius: 0)
        outerWall.firstMaterial?.diffuse.contents = UIColor.white
        outerWall.firstMaterial?.transparency = 0.000001
        let outerWallNode = SCNNode(geometry: outerWall)
        let multiplier: CGFloat = maskLowerSide ? -1 : 1
        outerWallNode.position = SCNVector3(wallWidth*multiplier,0,0)
        outerWallNode.renderingOrder = 10
        let wallNode = SCNNode()
        wallNode.addChildNode(outerWallNode)
        
        let innerWall = SCNBox(width: wallWidth, height: height, length: length, chamferRadius: 0)
        innerWall.firstMaterial?.lightingModel = .physicallyBased
        innerWall.firstMaterial?.diffuse.contents = UIImage(named: "Assets.Portal/wall/textures/Walls_Diffuse.png")
        innerWall.firstMaterial?.metalness.contents = UIImage(named: "Assets.Portal/wall/textures/Walls_Metalness.png")
        innerWall.firstMaterial?.roughness.contents = UIImage(named: "Assets.Portal/wall/textures/Walls_Roughness.png")
        innerWall.firstMaterial?.normal.contents = UIImage(named: "Assets.Portal/wall/textures/Walls_Normal.png")
        innerWall.firstMaterial?.specular.contents = UIImage(named: "Assets.Portal/wall/textures/Walls_Spec.png")
        innerWall.firstMaterial?.selfIllumination.contents = UIImage(named: "Assets.Portal/wall/textures/Walls_Gloss.png")
        
        let innerWallNode = SCNNode(geometry: innerWall)
        innerWallNode.renderingOrder = 100
        wallNode.addChildNode(innerWallNode)
        
        return wallNode
    }
    
    func addDoorway(node: SCNNode) {
        let halfWallLength: CGFloat = wallLength * 0.5
        let frontHalfWallLength: CGFloat = (wallLength - doorWidth) * 0.5
        
        let rightDoorSideNode = makeWallNode(length: frontHalfWallLength)
        rightDoorSideNode.eulerAngles = SCNVector3(0, 270.0.degreesToRadians, 0)
        rightDoorSideNode.position = SCNVector3(halfWallLength - 0.5 * doorWidth, positionY+wallHeight*0.5, positionZ+floorCeilingLength*0.5)
        node.addChildNode(rightDoorSideNode)
        
        let leftDoorSideNode = makeWallNode(length: frontHalfWallLength)
        leftDoorSideNode.eulerAngles = SCNVector3(0, 270.0.degreesToRadians, 0)
        leftDoorSideNode.position = SCNVector3(-halfWallLength + 0.5 * frontHalfWallLength, positionY+wallHeight*0.5, positionZ+floorCeilingLength*0.5)
        node.addChildNode(leftDoorSideNode)
        
        let aboveDoorNode = makeWallNode(length: doorWidth, height: wallHeight - doorHeight)
        aboveDoorNode.eulerAngles = SCNVector3(0, 270.0.degreesToRadians, 0)
        aboveDoorNode.position = SCNVector3(0, positionY+(wallHeight-doorHeight)*0.5+doorHeight, positionZ+floorCeilingLength*0.5)
        node.addChildNode(aboveDoorNode)
    }
    
    func placeLightSource(rootNode: SCNNode) {
        let light = SCNLight()
        light.intensity = 10
        light.type = .omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(0, positionY+wallHeight, positionZ)
        rootNode.addChildNode(lightNode)
    }

}





extension ViewController: ARSCNViewDelegate{
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if let planeAnchor = anchor as? ARPlaneAnchor,  !isPortalPlaced {
            let debugPlane = createPlaneNode(center: planeAnchor.center, extent: planeAnchor.extent)
            node.addChildNode(debugPlane)
            debugPlanes.append(debugPlane)
            
        }else if !isPortalPlaced{
           portalNode = makePortal()
           if let portalNode = portalNode{
                node.addChildNode(portalNode)
                isPortalPlaced = true
                sceneView.debugOptions = []
            }
        }
        
        
        func updatePlaneNode(_ node: SCNNode, center: vector_float3, extent: vector_float3){
            
            let geometry = node.geometry as? SCNPlane
            geometry?.width = CGFloat(extent.x)
            geometry?.height = CGFloat(extent.y)
            node.position = SCNVector3Make(center.x, 0, center.z)
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor){
            if let planeAnchor = anchor as? ARPlaneAnchor, !isPortalPlaced, !node.childNodes.isEmpty{
                updatePlaneNode(node.childNodes[0], center: planeAnchor.center, extent: planeAnchor.extent)
            }
        }
    }
    
    
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

