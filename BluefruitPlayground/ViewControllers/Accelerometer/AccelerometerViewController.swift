//
//  AccelerometerViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import SceneKit
import ReplayKit
import AVFoundation

struct LowPassFilterSignal {
    /// Current signal value
    var value: Float
    
    /// A scaling factor in the range 0.0..<1.0 that determines
    /// how resistant the value is to change
    let filterFactor: Float

    /// Update the value, using filterFactor to attenuate changes
    mutating func update(newValue: Float) {
        value = filterFactor * value + (1.0 - filterFactor) * newValue
    }
}

class AccelerometerViewController: ModuleViewController {
    // Constants
    static let kIdentifier = "AccelerometerViewController"
    
    
    //For Recording Function
    var recordButtonWasSelected: Bool = false
    var preferStatusBarHidden: Bool!
    
    
    // UI
    @IBOutlet weak var sceneView: SCNView!
    
    
    @IBOutlet var mainCamera: UIView!
    
    @IBOutlet var rotateCameraRef: UIButton!
    
    @IBOutlet var backgroundSwapRef: UIButton!
   
    @IBOutlet var recordButton: UIButton!
    
    let recorder = RPScreenRecorder.shared()
    
    @IBAction func backgroundSwapAction(_ sender: Any) {
    
        backgroundCameraIsActive.toggle()
    
        if backgroundCameraIsActive{
            mainCamera.alpha = 0
        }else{
            mainCamera.alpha = 1
        }
        
    }
    

        
    @IBAction func rotateCamAction(_ sender: Any) {
    
        print("Button Rotation Pressed")
    guard let currentCameraInput : AVCaptureInput = captureSession?.inputs.first else {
               return
           }
       if let input = currentCameraInput as? AVCaptureDeviceInput
       {
           if input.device.position == .back{
           
               switchToFrontCamera()
           }
           
           if input.device.position == .front{
           
               switchToBackCamera()
               
           }
           
           }
        
    }
    
    @IBAction func recordAction(_ sender: Any) {
    print("Is Recording...")
    recordButtonWasSelected = !recordButtonWasSelected
     recordUpdater()
    }
    
    
    
    //Recording Functions
    func recordUpdater() {
         
         if recordButtonWasSelected {
           print("Currently Recording...")
           recording()
          // recordButton.backgroundColor = UIColor.red
           
         } else {
          // recordButton.backgroundColor = UIColor.white
           print("Stopped/Not Recording.")
           stopRecording()
         }
       
    }
    
    func recording() {
      
     
      
      RPScreenRecorder.shared().isMicrophoneEnabled = true;
    
      recordButton.isUserInteractionEnabled = true
      recordButton.isEnabled = true
      
      let pulse1 = CASpringAnimation(keyPath: "transform.scale")
      pulse1.duration = 0.6
      pulse1.fromValue = 1.0
      pulse1.toValue = 1.20
      pulse1.autoreverses = true
      pulse1.repeatCount = 1
      pulse1.initialVelocity = 0.8
      pulse1.damping = 0.8
      
      let animationGroup = CAAnimationGroup()
      animationGroup.duration = 2.7
      animationGroup.repeatCount = 1000
      animationGroup.animations = [pulse1]
      
      recordButton.layer.add(animationGroup, forKey: "pulse")
      
      
      recorder.startRecording { (error) in
        if let error = error {
          print(error)
        }
      }
    }
    
    
    
    
    //Works for iPhone
    func stopRecording() {

        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone {
        recordButton.layer.removeAllAnimations()
        
        recorder.stopRecording { (previewVC, error) in

            if let previewVC = previewVC{
                previewVC.previewControllerDelegate = self
                self.present(previewVC, animated: true, completion: nil)
            
        }
        if let error = error {
          print(error)
        }
      }
    
    
        }
        
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
            
            recordButton.layer.removeAllAnimations()
            
            let recorder = RPScreenRecorder.shared()
            
            recorder.stopRecording { (previewVC, error) in
              
              if let previewVC = previewVC {
                
                previewVC.previewControllerDelegate = self as RPPreviewViewControllerDelegate
                
                if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
                  previewVC.modalPresentationStyle = UIModalPresentationStyle.popover
                  previewVC.popoverPresentationController?.sourceRect = self.recordButton.frame //position popover relative to record button - NEEDS TESTING
                  previewVC.popoverPresentationController?.sourceView = self.view
                  //Show Preview
                  self.present(previewVC, animated: true)
                }
                  
                else {
                  //Set boundaries safe for iPhone X - NEEDS TESTING
                  let safeArea = self.view.safeAreaInsets
                  let safeAreaHeight = self.view.frame.height - safeArea.top
                  let safeAreaWidth = self.view.frame.width - (safeArea.left + safeArea.right)
                  let scaleX = safeAreaWidth / self.view.frame.width
                  let scaleY = safeAreaHeight / self.view.frame.height
                  let scale = min(scaleX, scaleY)
                  previewVC.view.transform = CGAffineTransform(scaleX: scale, y: scale)
                  //Show Preview
                  self.present(previewVC, animated: true) {
                    previewVC.view.frame.origin.x += safeArea.left
                    previewVC.view.frame.origin.y += safeArea.top
                  }
                }
              }
              
              if let error = error {
                print(error)
              }
            }
            
        }
        
        
        
        
    }
    

    
    
    
    
    //Background
    var backgroundCameraIsActive = false
    
    // Camera Data
    var captureSession: AVCaptureSession?
    
    var videoPreviewLayer : AVCaptureVideoPreviewLayer?
    
    var frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    
    var backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    

    
    
    
    
    func switchToFrontCamera(){
      
        print("Front Cam")
       
        if frontCamera?.isConnected == true {
            captureSession?.stopRunning()
            let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice!)
                captureSession = AVCaptureSession()
                   captureSession?.addInput(input)
                   videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                videoPreviewLayer?.frame = view.layer.bounds
                   mainCamera.layer.addSublayer(videoPreviewLayer!)
                   captureSession?.startRunning()
            }
            catch{
                print("Error.")
            }
        }
        
    }
    
    func switchToBackCamera(){
        print("Back Cam")
        if backCamera?.isConnected == true {
            captureSession?.stopRunning()
            let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice!)
                captureSession = AVCaptureSession()
                   captureSession?.addInput(input)
                   videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                videoPreviewLayer?.frame = view.layer.bounds
                   mainCamera.layer.addSublayer(videoPreviewLayer!)
                   captureSession?.startRunning()
            }
            catch{
                print("Error.")
            }
        }
        
    }
    
    
    
    // Data
    private var jawNode: SCNNode!

    private var headNode: SCNNode!
    
    private var sparkyFaceNode: SCNNode!
    
    private var valuesPanelViewController: AccelerometerPanelViewController!
   
    private var acceleration = BlePeripheral.AccelerometerValue(x: 0, y: 0, z: 0)
    
    var accelerometerX = LowPassFilterSignal(value: 0, filterFactor: 0.6)
    
    var accelerometerY = LowPassFilterSignal(value: 0, filterFactor: 0.7)
    
    private var playIntroAnimation = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
       
        super.viewDidLoad()
        
        // Add panels
        valuesPanelViewController = (addPanelViewController(storyboardIdentifier: AccelerometerPanelViewController.kIdentifier) as! AccelerometerPanelViewController)
        
        // Load base
        let scene = SCNScene(named: "Sparky_Gold1.dae")!
        scene.background.contents = UIColor.clear
        
        jawNode = scene.rootNode.childNode(withName: "jaw", recursively: true)!
        headNode = scene.rootNode.childNode(withName: "SparkyHead", recursively: true)!
        sparkyFaceNode = scene.rootNode.childNode(withName: "Face", recursively: true)!
        
        // Setup scene
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.isUserInteractionEnabled = true // false
        
        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("Puppets")
        moduleHelpMessage = localizationManager.localizedString("accelerometer_help")
        
        
        
               //--- Camera Function ----
                
                if #available(iOS 10.2, *){
        
                    let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                    do
                    {
                         let input = try AVCaptureDeviceInput(device: captureDevice!)
                                              captureSession = AVCaptureSession()
                                              captureSession?.addInput(input)
                                              videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                                           videoPreviewLayer?.frame = view.layer.bounds
                                              mainCamera.layer.addSublayer(videoPreviewLayer!)
                                              captureSession?.startRunning()
                    }
                    catch
                    {
                        print("Error.")
                    }
        
                }
        

    
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
         switchToFrontCamera()
        
        // Initial value
        if let acceleration = CPBBle.shared.accelerometerLastValue() {
            self.acceleration = acceleration
        }
        updateValueUI()
        
        // Set delegate
        CPBBle.shared.accelerometerDelegate = self
        
        //Subscribe to command notifications
        notificatonsForEmoteUse()
        
        //Sparky's Intro Animation
        sparkyIntroAnimation()
    }
    
    func notificatonsForEmoteUse (){
        NotificationCenter.default.addObserver(self, selector: #selector(animationOne),name:NSNotification.Name(rawValue: "EmoteOne"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(animationTwo),name:NSNotification.Name(rawValue: "EmoteTwo"), object: nil)
    
//    NotificationCenter.default.addObserver(self, selector: #selector(switchOne),name:NSNotification.Name(rawValue: "EmoteThree"), object: nil)
//    
//    NotificationCenter.default.addObserver(self, selector: #selector(switchTwo),name:NSNotification.Name(rawValue: "EmoteFour"), object: nil)
        
    }
    
    func sparkyIntroAnimation(){
        let scale: Float = 0.0005
                
                headNode.scale = SCNVector3(x: scale, y: scale, z: scale)
                let scaleAnimation = SCNAction.scale(to: CGFloat(1), duration: 1.3)
                let rotationAction = SCNAction.rotateBy(x: 0, y: 12.57, z: 0, duration: 1.4)
              //  let transformAnimation = SCNAction.moveBy(x: 0, y: 0, z: 0, duration: 1.4)

                rotationAction.timingMode = .easeOut
                
//                        rotationAction.timingFunction = { (p: Float) in
//                          return self.easeOutElastic(p)
//                    }
                
                headNode.runAction(scaleAnimation)
                headNode.runAction(rotationAction)
               // headNode.runAction(transformAnimation)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1401)) {
                    self.playIntroAnimation = true
                    
                }

    }
    
    @objc func switchOne(){

        backgroundCameraIsActive.toggle()
           
        if backgroundCameraIsActive{
            DispatchQueue.main.async {
                self.mainCamera.alpha = 0
        }
    }else{
        DispatchQueue.main.async {
            self.mainCamera.alpha = 1
    }

        }

    }
    
    
    @objc func switchTwo(){
     print("Switched 2")
        backgroundCameraIsActive.toggle()
               
            if backgroundCameraIsActive{
                DispatchQueue.main.async {
                    self.mainCamera.alpha = 0
            }
        }else{
            DispatchQueue.main.async {
                self.mainCamera.alpha = 1
        }

            }

}
    
    
    @objc func animationOne(){
        //Uses a bounce in and out animation for Sparky's eyes.
        let scale: Float = 0.0005

        sparkyFaceNode.scale = SCNVector3(x: scale, y: scale, z: scale)

        let bounceAction = SCNAction.scale(to: CGFloat(1), duration: 1)

        bounceAction.timingMode = .linear

        // Use a custom timing function
        bounceAction.timingFunction = { (p: Float) in
          return self.easeOutElastic(p)
        }
        sparkyFaceNode.runAction(bounceAction)

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) {
            self.sparkyFaceNode.removeAllActions()
            
            
        }
        
    }
    
    @objc func animationTwo(){
        playIntroAnimation = false
        
        
        let rotateAnimation = SCNAction.rotateTo(x: 0, y: 0, z: -0.3, duration: 0.1)
        
        let rotateAnimationback = SCNAction.rotateTo(x: 0, y: 0, z: 0.3, duration: 0.1)
        
        let headReset = SCNAction.rotateTo(x: -0.01, y: 0, z: -0.0, duration: 0.1)
        
        let sequence = SCNAction.sequence([rotateAnimation, rotateAnimationback,rotateAnimation, rotateAnimationback,rotateAnimation, rotateAnimationback, headReset])
        
        rotateAnimation.timingMode = .linear
        
        rotateAnimationback.timingMode = .linear
        
       

        
        headNode.runAction(sequence)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
            self.playIntroAnimation = true
            self.headNode.removeAllActions()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove delegate
        CPBBle.shared.accelerometerDelegate = nil
    }
    
    // MARK: - UI
    private func updateValueUI() {
        
        if playIntroAnimation == true {
        
        // Calculate Euler Angles
        let eulerAngles = eulerAnglesFromAcceleration()
        
        let eulerAnglesForHead = eulerAnglesFromAccelerationForHead()
        //DLog("Euler: pitch: \(eulerAngles.x) yaw: \(eulerAngles.y) roll: \(eulerAngles.z)")
        
        // Update circuit model orientation
        SCNTransaction.animationDuration = BlePeripheral.kCPBAcceleromterDefaultPeriod

        jawNode.eulerAngles = eulerAngles
        headNode.eulerAngles = eulerAnglesForHead
        
        
        // Update panel
        valuesPanelViewController.accelerationReceived(acceleration: self.acceleration, eulerAngles: eulerAngles)
   
        }
    }

    private func eulerAnglesFromAcceleration() -> SCNVector3 {
        // https://robotics.stackexchange.com/questions/6953/how-to-calculate-euler-angles-from-gyroscope-output
        let accelAngleX = atan2(acceleration.y, acceleration.z)
      //  let accelAngleY = atan2(-acceleration.x, sqrt(acceleration.y*acceleration.y + acceleration.z*acceleration.z))

        accelerometerX.update(newValue: accelAngleX)

        return SCNVector3(accelerometerX.value.clamped(min: 0.13, max: 0.8), 0, 0)
    }
   
    
    private func eulerAnglesFromAccelerationForHead() -> SCNVector3 {
        // https://robotics.stackexchange.com/questions/6953/how-to-calculate-euler-angles-from-gyroscope-output
        let accelAngleX = atan2(acceleration.y, acceleration.z)
        let accelAngleY = atan2(-acceleration.x, sqrt(acceleration.y*acceleration.y + acceleration.z*acceleration.z))
        
        let accelAngleYALT = atan2(-acceleration.x, sqrt(acceleration.y*acceleration.y) + acceleration.z*acceleration.z)
        
        accelerometerX.update(newValue: accelAngleX)
        accelerometerY.update(newValue: accelAngleYALT)
        
        
       return SCNVector3(-accelerometerX.value.clamped(min: 0.1, max: 0.7), -accelerometerY.value, accelerometerY.value)
    }
    
    // Timing function that has a "bounce in" effect
       
    func easeOutElastic(_ t: Float) -> Float {
        let p: Float = 0.3
        let result = pow(2.0, -5.0 * t) * sin((t - p / 4.0) * (2.0 * Float.pi) / p) + 1.0
        return result
    }

}

// MARK: - CPBBleAccelerometerDelegate
extension AccelerometerViewController: CPBBleAccelerometerDelegate {
    
    func cpbleAccelerationReceived(_ acceleration: BlePeripheral.AccelerometerValue) {
        self.acceleration = acceleration
        updateValueUI()
    }
    
}


extension Float {
    func clamped(min min: Float, max: Float) -> Float {
        if self < min {
            return min
        }
        
        if self > max {
            return max
        }
        
        return self
    }
}


extension AccelerometerViewController : RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true, completion: nil)
    }
    
}


extension UIView {
  @IBInspectable
  var newCornerRadius: CGFloat {
    get {
      return layer.cornerRadius
    }
    set {
      layer.cornerRadius = newValue
    }
  }
}


extension Int {
  var degreesToRadians: Double { return Double(self) * .pi/180}
}



