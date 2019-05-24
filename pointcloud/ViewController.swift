//
//  ViewController.swift
//  pointcloud
//
//  Created by Zach Eriksen on 8/29/18.
//  Copyright © 2018 oneleif. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum Element: String {
    case a
    case b
    case c
    case d
    case e
    case f
    case g
    
    static var all: [Element] {
        return [.a, .b, .c, .d, .e, .f, .g]
    }
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var points: [SCNVector3] = []
    var isCapturing = false
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the scene to the view
        sceneView.scene = SCNScene()
        
        timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(capture), userInfo: nil, repeats: true)
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
    
    @objc
    func capture() {
        if isCapturing {
            guard let pointCloud = sceneView.session.currentFrame?.rawFeaturePoints else {
                return
            }
            pointCloud.points.forEach { (p) in
                let point = SCNVector3(p)
                if !points.contains(where: { point.x  == $0.x &&
                                            point.y == $0.y &&
                                            point.z == $0.z }) {
                    points.append(point)
                }
            }
            if points.count >= 8000 {
                log()
                points = []
            }
//            draw()
        }
    }
    var count = 0
    var data = ""
    func log() {
        data += "\(points.count)\n\n"
        points.forEach { (p) in
            let tag = Element.all[count % Element.all.count]
            data += "\(tag)        \(p.x * 10)        \(p.y * 10)        \(p.z * 10)\n"
            count += 1
        }
    }
    
    func save(text: String) {
        let file = "points.xyz"
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(file)
            
            //writing
            do {
                try text.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {
                print(error.localizedDescription)
            }
            
            do {
                let text2 = try String(contentsOf: fileURL, encoding: .utf8)
                print("+")
                print(text2.split(separator: "\n").map { "\($0)\n" }.reduce("",+))
            }
            catch {/* error handling here */}
        }
    }
        
    
    func draw() {
        func drawMesh() {
            
            let vertexSource = SCNGeometrySource(vertices: points)
            let normalSource = SCNGeometrySource(normals: points.map { _ in SCNVector3(0, 0, 1) })
            let indices: [Int32] = (0 ... points.count).map { Int32($0) }
            
            let pointer = UnsafeRawPointer(indices)
            let indexData = NSData(bytes: pointer, length: MemoryLayout<Int32>.size * indices.count)
            
            let element = SCNGeometryElement(data: indexData as Data, primitiveType: .triangles, primitiveCount: indices.count / 3, bytesPerIndex: MemoryLayout<Int32>.size)
            
            let geometry = SCNGeometry(sources: [vertexSource, normalSource], elements: [element])
            
            let node = SCNNode()
            geometry.firstMaterial?.diffuse.contents = UIColor.init(white: 1, alpha: 0.3)
            node.geometry = geometry
            
            sceneView.scene.rootNode.addChildNode(node)
            points = []
        }
        func drawPlanes() {
            points.forEach { (point) in
                let plane = SCNPlane(width: 0.001, height: 0.001)
                
                let node = SCNNode(geometry: plane)
                node.position = point
                node.constraints = [SCNBillboardConstraint()]
                sceneView.scene.rootNode.addChildNode(node)
            }
            points = []
        }
        drawMesh()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isCapturing = false
        log()
        save(text: data)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isCapturing = true
    }
    
    func addLineBetween(start: SCNVector3, end: SCNVector3) {
        let lineGeometry = SCNGeometry.lineFrom(vector: start, toVector: end)
        let lineNode = SCNNode(geometry: lineGeometry)
        
        sceneView.scene.rootNode.addChildNode(lineNode)
    }
    
}

extension SCNVector3 {
    static func distanceFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> Float {
        let x0 = vector1.x
        let x1 = vector2.x
        let y0 = vector1.y
        let y1 = vector2.y
        let z0 = vector1.z
        let z1 = vector2.z
        
        return sqrtf(powf(x1-x0, 2) + powf(y1-y0, 2) + powf(z1-z0, 2))
    }
}

extension SCNGeometry {
    class func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])
    }
}

