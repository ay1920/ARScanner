//
//  ViewController.swift
//  ARScanner
//
//  Created by Amit Yadav on 15/06/21.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate,ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var qrRequests = [VNRequest]()
    var detectedDataAnchor: ARAnchor?
    var processing = false
    var width = 0.0
    var height = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate=self
        //self.addViewWithPosition(pos: SCNVector3(0.0, 0.0, 0.5))
        startQRCodeScanning()
    }
    
  
    
    func startQRCodeScanning() {
        // Create a Barcode Detection Request
        let request = VNDetectBarcodesRequest(completionHandler: self.qrDetectionRequestHandler)
        // Set it to recognize QR code only
        request.symbologies = [.EAN13,.QR]
        self.qrRequests = [request]
    }
    
    func qrDetectionRequestHandler(request: VNRequest, error: Error?) {
        // Get the first result out of the results, if there are any
        //print("Handler Called")
        if let results = request.results, let result = results.first as? VNBarcodeObservation {
            guard result.payloadStringValue != nil else {return}
            // Get the bounding box for the bar code and find the center
            print(result.payloadStringValue as Any)
            var rect = result.boundingBox
            
            
            
            // Flip coordinates
            rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
            rect = rect.applying(CGAffineTransform(translationX: 0, y: 1))
            
            
            // Get center
            let center = CGPoint(x: rect.midX, y: rect.midY)
            
            DispatchQueue.main.async {
               self.hitTestForQrCode(center: center)
                self.processing = false
            }
        } else {
            self.processing = false
        }
    }
    
    func hitTestForQrCode(center: CGPoint) {
        
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.3
        
        guard let currentFrame = self.sceneView.session.currentFrame
            else { return }
        
        let transform = currentFrame.camera.transform * translation
        
        if let detectedDataAnchor = self.detectedDataAnchor,
            let node = self.sceneView.node(for: detectedDataAnchor) {
            _ = node.position
            node.transform = SCNMatrix4(transform)
            
        } else {
            // Create an anchor. The node will be created in delegate methods
            self.detectedDataAnchor = ARAnchor(transform: transform)
            self.sceneView.session.add(anchor: self.detectedDataAnchor!)
        }
        
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

        // Pause the view's session
        sceneView.session.pause()
    }
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if self.processing {
                    return
                }
                self.processing = true
                
                // Create a request handler using the captured image from the ARFrame
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage,
                                                                options: [:])
                // Process the request
                try imageRequestHandler.perform(self.qrRequests)
            } catch {
                
            }
        }
    }

    // MARK: - ARSCNViewDelegate
    

    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {

        print("hello")
        if self.detectedDataAnchor?.identifier == anchor.identifier {
            
            let node = SCNNode()
            
            node.addChildNode(addView())
            //self.sceneView.session.pause()
            return node
        
        }
        
        
        
        return nil
    }
    
    func addView() ->SCNNode{

        
        
        let skScene = SKScene(size: CGSize(width: self.width > 1 ? self.width : 200, height: self.height > 1 ? self.height : 200))
        skScene.backgroundColor = UIColor.clear
        
        let rectangle = SKShapeNode(rect: CGRect(x: 0, y: 0, width: self.width > 1 ? self.width : 200, height: self.height > 1 ? self.height : 200), cornerRadius: 10)
        rectangle.fillColor = #colorLiteral(red: 0.807843148708344, green: 0.0274509806185961, blue: 0.333333343267441, alpha: 1.0)
        rectangle.strokeColor = #colorLiteral(red: 0.439215689897537, green: 0.0117647061124444, blue: 0.192156866192818, alpha: 1.0)
        rectangle.lineWidth = 5
        rectangle.alpha = 1.0
        let labelNode = SKLabelNode(text: "Hello World")
        labelNode.fontSize = 15
        labelNode.fontName = "Arial"
        labelNode.position = CGPoint(x:0,y:0)
        labelNode.color = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        skScene.addChild(rectangle)
        skScene.addChild(labelNode)
        
        let plane = SCNPlane(width: 0.20, height: 0.20)
        let material = SCNMaterial()
        material.isDoubleSided = true
        material.diffuse.contents = skScene
        plane.materials = [material]
        let planeNode = SCNNode(geometry: plane)
        

        return planeNode
    }
    
    func addViewWithPosition(pos:SCNVector3){

        guard let carScene = SCNScene(named: "ship.scn") else { return}
        let carNode = SCNNode()
        let carSceneChildNodes = carScene.rootNode.childNodes
                
        for childNode in carSceneChildNodes {
            carNode.addChildNode(childNode)
        }
                
        carNode.position = pos
        carNode.scale = SCNVector3(0.5, 0.5, 0.5)
        sceneView.scene.rootNode.addChildNode(carNode)
     }
}

