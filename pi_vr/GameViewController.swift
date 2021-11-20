import QuartzCore
import SceneKit
import GameplayKit
import simd
import SwiftUI
import Cocoa

typealias float=Float
typealias double=Double
typealias int=Int
typealias bool=Bool
typealias quat=simd_quatf
typealias vec2=SIMD2<float>
typealias vec3=SIMD3<float>
typealias vec4=SIMD4<float>


let sc_width=800
let sc_height=480

extension SCNVector3{
    init(_ v:vec3){
        self.init(v.x,v.y,v.z)
    }
}
extension SCNQuaternion{
    init(_ q:quat){
        self.init(q.imag.x,q.imag.y,q.imag.z,q.real)
    }
}
extension quat{
    func toSCNQ()->SCNQuaternion{
        return SCNQuaternion(imag.x,imag.y,imag.z,real)
    }
}
func qrotate(_ v:vec3,_ q:quat)->vec3{
    let p=quat(ix:v.x,iy:v.y,iz:v.z,r:0)
    let r=q*p*q.conjugate
    return r.imag
}

var PI=float.pi

var quatblock=stabilizedNode()
var world=worldNode()
let scene=SCNScene()

final class GameViewController:NSViewController,SCNSceneRendererDelegate,NSViewControllerRepresentable{
    let cameraNode=VRCamera()
    var pt:double=0
    static var static_left:bool=true
    var left:bool=false
    var frameCount:int=0
    override func loadView(){
        print("loadView")
        view=SCNView(frame:NSMakeRect(0,0,CGFloat(sc_width/2),CGFloat(sc_height)))
    }
    func makeNSViewController(context: Context) -> some NSViewController {
        print("makeNSViewController")
        return self
    }
    func updateNSViewController(_ nsViewController: NSViewControllerType, context: Context) {
        print("updateNSViewController")
    }
    override func viewDidLoad() {
        print("viewDidLoad")
        super.viewDidLoad()
        
        scene.rootNode.addChildNode(cameraNode)
        left=GameViewController.static_left
        GameViewController.static_left = !left
        print("left:",left)
        cameraNode.set(left)
        
        if left{
            let ambientLightNode=SCNNode()
            ambientLightNode.light=SCNLight()
            ambientLightNode.light!.type = .ambient
            ambientLightNode.light!.color = NSColor.darkGray
            scene.rootNode.addChildNode(ambientLightNode)
            
            let lightNode=SCNNode()
            lightNode.light=SCNLight()
            lightNode.light!.type = .omni
            lightNode.position=SCNVector3(-10,10,10)
            lightNode.look(at:SCNVector3(0,0,0))
            lightNode.light?.castsShadow=true
            
            quatblock.set(gravity: getGravity())
            scene.rootNode.addChildNode(quatblock)
            world.addChildNode(lightNode)
            quatblock.addChildNode(world)
        }
        let scnView=self.view as! SCNView
        scnView.delegate=self
        scnView.scene=scene
        scnView.allowsCameraControl=false
        scnView.showsStatistics=true
        scnView.backgroundColor=NSColor.black
        scnView.pointOfView=cameraNode
    }
    func getGravity()->vec3{
        return pi_acc
    }
    func getAcc()->vec3{
        return pi_acc
    }
    func getGyro()->vec3{
        return pi_gyro
    }
    func getMag()->vec3{
        return vec3(0,0,0)
    }
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval){
        let dt:float=float(time-pt)
        pt=time
        let dthetadt=getGyro()
        let a=getAcc()
        if left && frameCount%60==0{
            print("gyro: ",dthetadt.x," ",dthetadt.y," ",dthetadt.z," dt = ",pi_dt)
            print("accl: ",a.x," ",a.y," ",a.z," dt = ",pi_dt)
        }
        if left && frameCount>0{
            quatblock.update(dthetadt,a*9.81*0,dt)
        }
        frameCount+=1
    }
}


class VRCamera:SCNNode{
    let eyedist:float=1
    var thetaEye:float=0
    let focalpoint:float=10
    override init(){
        super.init()
        position=SCNVector3(0,0,0)
        camera=SCNCamera()
        camera?.zFar*=2
        position=SCNVector3(0,0,0)
        thetaEye=atan2(float(eyedist/2),focalpoint)
    }
    func set(_ left:bool){
        if(left){
            position=SCNVector3(-float(eyedist/2),0,0)
            localRotate(by:quat(angle:-thetaEye,axis:vec3(0,1,0)).toSCNQ())
        }else{
            position=SCNVector3(float(eyedist/2),0,0)
            localRotate(by:quat(angle:thetaEye,axis:vec3(0,1,0)).toSCNQ())
        }
    }
    required init?(coder: NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
}



class stabilizedNode:SCNNode{
    var q=quat(angle:0,axis:vec3(0,0,1))
    var p=vec3(0,0,0)
    var v=vec3(0,0,0)
    var orient=SCNNode()
    override init(){
        super.init()
        position=SCNVector3(0,0,0)
        orient.position=SCNVector3(p)
        super.addChildNode(orient)
        runAction(SCNAction.repeatForever(SCNAction.rotateBy(x:0,y:0,z:0,duration: 1)))
    }
    func set(gravity grav:vec3){
        q=quat(from:vec3(0,0,-1),to:grav)
        orientation=q.toSCNQ()
    }
    func update(_ dthetadt:vec3,_ a:vec3,_ dt:float){
        let qx=quat(angle:-dthetadt.x*dt,axis:vec3(1,0,0))
        let qy=quat(angle:-dthetadt.y*dt,axis:vec3(0,1,0))
        let qz=quat(angle:-dthetadt.z*dt,axis:vec3(0,0,1))
        q=qx*qy*qz*q
        orientation=SCNQuaternion(q)
        let ar=qrotate(a,q)
        v+=ar*dt
        p+=v*dt
        orient.position=SCNVector3(p)
        
    }
    override func addChildNode(_ child: SCNNode){
        orient.addChildNode(child)
    }
    required init?(coder: NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
}


class worldNode:SCNNode{
    override init(){
        super.init()
        let gridSize=40
        self.localRotate(by:quat(angle:PI/2,axis:vec3(0,0,1)).toSCNQ())
        self.position=SCNVector3(0,0,0)
        let nm=GKNoiseMap(GKNoise(GKPerlinNoiseSource()))
        for i in 0..<gridSize{
            for j in 0..<gridSize{
                let k=int(15*nm.value(at:SIMD2<Int32>(Int32(i),Int32(j))))
                let block=SCNNode()
                block.geometry=SCNBox(width:3,height:3,length:3,chamferRadius:0)
                
                block.position=SCNVector3(
                    x: CGFloat(3.0*float(i-gridSize/2)),
                    y: CGFloat(3.0*float(-6+k)),
                    z: CGFloat(3.0*float(j-gridSize/2)))
                self.addChildNode(block)
            }
        }
    }
    required init?(coder: NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
}



