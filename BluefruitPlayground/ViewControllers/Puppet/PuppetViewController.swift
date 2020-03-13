//
//  PuppetViewController.swift
//  BluefruitPlayground
//
//  Created by Trevor Beaton & Antonio García on 03/02/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import UIKit
import SceneKit
import ReplayKit
import AVFoundation

class PuppetViewController: UIViewController {
    // Constants
    static let kIdentifier = "PuppetViewController"

    // UI
    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var cameraView: PreviewView!
    @IBOutlet weak var cameraButtonsContainerView: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var fullscreenButton: UIButton!

    // Data
    private var acceleration = BlePeripheral.AccelerometerValue(x: 0, y: 0, z: 0)
    private var buttonsState: BlePeripheral.ButtonsState?

    private var jawNode: SCNNode?
    private var headNode: SCNNode?
    private var sparkyFaceNode: SCNNode?

    private var isPlayingIntroAnimation = true

    private var filteredAccelAngleX = LowPassFilterSignal(value: 0, filterFactor: 0.6)
    private var filteredAccelAngleY = LowPassFilterSignal(value: 0, filterFactor: 0.7)

    // Camera Data
    private let captureSession = AVCaptureSession()
    private var isUsingFrontCamera = true
    private var isFullScreen = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Load base
        let scene = SCNScene(named: "Sparky_Gold1.scn")!
        scene.background.contents = UIColor.clear

        jawNode = scene.rootNode.childNode(withName: "jaw", recursively: true)!
        headNode = scene.rootNode.childNode(withName: "SparkyHead", recursively: true)!
        sparkyFaceNode = scene.rootNode.childNode(withName: "Face", recursively: true)!

        // Setup scene
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.isUserInteractionEnabled = true

        // Setup camera
        self.cameraView.videoPreviewLayer.videoGravity = .resizeAspectFill

        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("puppet_title")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Initial value
        let board = AdafruitBoardsManager.shared.currentBoard
        if let acceleration = board?.accelerometerLastValue() {
            self.acceleration = acceleration
        }

        updateValueUI()
        updateRecordButtonUI()

        // Setup UI for not fullscreen
        showFullScreen(enabled: false, animated: false)

        // Navigationbar setup
        if let customNavigationBar = navigationController?.navigationBar as? NavigationBarWithScrollAwareRightButton {
            customNavigationBar.setRightButton(topViewController: self, image: UIImage(named: "help"), target: self, action: #selector(help(_:)))
        }

        // Set delegates
        board?.accelerometerDelegate = self
        board?.buttonsDelegate = self
        RPScreenRecorder.shared().delegate = self

        // Start camera
        enableCamera(isFrontCamera: isUsingFrontCamera, animated: false)

        // Intro Animation
        startSparkyIntroAnimation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove delegates
        let board = AdafruitBoardsManager.shared.currentBoard
        board?.accelerometerDelegate = nil
        board?.buttonsDelegate = nil
        RPScreenRecorder.shared().delegate = nil
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Stop camera
        disableCamera(animated: false)
    }

    // MARK: - Camera
    @discardableResult
    private func enableCamera(isFrontCamera: Bool, animated: Bool) -> Bool {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: isFrontCamera ? .front: .back) else { return false }
        let enabled = enableCameraCaptureSession(captureInput: camera)

        if enabled {
            // Show the cameraView
            if animated {
                UIView.animate(withDuration: 0.3) {
                    self.cameraView.alpha = 1
                }
            } else {
                self.cameraView.alpha = 1
            }
        }

        return enabled
    }

    private func enableCameraCaptureSession(captureInput: AVCaptureDevice) -> Bool {
        guard let input = try? AVCaptureDeviceInput(device: captureInput) else { return false }

        var isEnabled = true

        // Disable current camera session
        captureSession.stopRunning()

        // Configure
        captureSession.beginConfiguration()

        let previousInput = captureSession.inputs.first
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            DLog("Error adding input to capture session")
            isEnabled = false

            // Revert to previous input
            if let previousInput = previousInput, captureSession.canAddInput(previousInput) {
                captureSession.addInput(previousInput)
            }
        }

        captureSession.commitConfiguration()

        self.cameraView.videoPreviewLayer.session = captureSession
        captureSession.startRunning()
        return isEnabled
    }

    private func disableCamera(animated: Bool) {
        captureSession.stopRunning()

        // Hide the cameraView
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.cameraView.alpha = 0
            }
        } else {
            self.cameraView.alpha = 0
        }
    }

    private func switchCamera() {
        isUsingFrontCamera.toggle()
        enableCamera(isFrontCamera: isUsingFrontCamera, animated: true)
    }

    private func switchScreenMode() {
        if captureSession.isRunning {
            disableCamera(animated: true)
        } else {
            enableCamera(isFrontCamera: isUsingFrontCamera, animated: true)
        }
    }

    // MARK: - Recording
    private func startRecording() {
        let recorder = RPScreenRecorder.shared()
        recorder.isMicrophoneEnabled = true
        recorder.startRecording { [weak self] error in
            guard let self = self else { return }
            guard error == nil  else {
                DLog("Error recording: \(error!)")
                return
            }

            self.enableRecordingUI()
        }
    }

    private func stopRecording() {
        disableRecordingUI()
        RPScreenRecorder.shared().stopRecording { [weak self] (previewViewController, error) in
            self?.processRecordingStopped(previewViewController: previewViewController, error: error)
        }
    }

    private func enableRecordingUI() {
        // Update buttons
        PuppetViewController.startButtonRecordAnimation(button: self.recordButton)
    }

    private func disableRecordingUI() {
        // Update UI
        PuppetViewController.stopButtonRecordAnimation(button: recordButton)
    }

    private func processRecordingStopped(previewViewController: RPPreviewViewController?, error: Error?) {
        // Check errors
        guard error == nil else {
            DLog("Error recording: \(error!)")
            return
        }

        // Show recorder edit controller
        guard let previewViewController = previewViewController else { return }
        previewViewController.previewControllerDelegate = self
        self.present(previewViewController, animated: true, completion: nil)
    }

    private func switchRecording() {
        if RPScreenRecorder.shared().isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    // MARK: - UI
    private func updateValueUI() {

        // Update sparky rotation (only if the intro animation is not currently playing)
        if !isPlayingIntroAnimation {
            SCNTransaction.animationDuration = BlePeripheral.kAdafruitSensorDefaultPeriod

            let accelAngleX = atan2(acceleration.y, acceleration.z)
            filteredAccelAngleX.update(newValue: accelAngleX)
            jawNode?.eulerAngles = SCNVector3(filteredAccelAngleX.value.clamped(min: 0.13, max: 0.8), 0, 0)

            let accelAngleY = atan2(-acceleration.x, sqrt(acceleration.y*acceleration.y) + acceleration.z*acceleration.z)
            filteredAccelAngleY.update(newValue: accelAngleY)
            headNode?.eulerAngles = SCNVector3(-filteredAccelAngleX.value.clamped(min: 0.1, max: 0.7), -filteredAccelAngleY.value, filteredAccelAngleY.value)
        }
    }

    private func updateRecordButtonUI() {
        recordButton.isEnabled = RPScreenRecorder.shared().isAvailable
    }

    private func showFullScreen(enabled: Bool, animated: Bool) {
        // Calculate changes
        let applyUIChanges = { [unowned self] in
            self.cameraButtonsContainerView.alpha = enabled ? 0.3 : 1
            self.fullscreenButton.setImage(UIImage(named: enabled ? "shrink":"expand"), for: .normal)
        }

        // Apply changes
        self.navigationController?.setNavigationBarHidden(enabled, animated: animated)
        if animated {
            UIView.animate(withDuration: 0.3) {
                applyUIChanges()
            }
        } else {
            applyUIChanges()
        }
        isFullScreen = enabled
    }

    // MARK: - Animations
    private func startSparkyIntroAnimation() {
        guard let headNode = headNode else { return }
        self.isPlayingIntroAnimation = true

        let scale: Float = 0.0005
        headNode.scale = SCNVector3(x: scale, y: scale, z: scale)
        headNode.eulerAngles = SCNVector3(0, -12.57, 0)
        let scaleAction = SCNAction.scale(to: 1, duration: 1.3)
        let rotationAction = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 1.4)
        rotationAction.timingMode = .easeOut

        headNode.runAction(scaleAction)
        headNode.runAction(rotationAction) {
            self.isPlayingIntroAnimation = false
        }
    }

    private func startSparkyEyesAnimation() {
        guard let sparkyFaceNode = sparkyFaceNode else { return }

        // Reset pervious animation if still running
        self.sparkyFaceNode?.removeAllActions()

        // Animatie a bounce in and out animation for Sparky's eyes.
        let scale: Float = 0.0005
        sparkyFaceNode.scale = SCNVector3(x: scale, y: scale, z: scale)

        let bounceAction = SCNAction.scale(to: 1, duration: 1)
        bounceAction.timingMode = .linear

        bounceAction.timingFunction = { time in // Use a custom timing function
            return self.easeOutElastic(time)
        }
        sparkyFaceNode.runAction(bounceAction)
    }

    private func startSparkyShakeAnimation() {
        guard let headNode = headNode else { return }
        guard !isPlayingIntroAnimation else { return }      // Don't play while intro is playing because both overwrite the headNode animations

        // Reset pervious animation if still running
        self.headNode?.removeAllActions()

        // Animate
        let rotateAnimation = SCNAction.rotateTo(x: 0, y: 0, z: -0.3, duration: 0.1)
        rotateAnimation.timingMode = .linear

        let rotateAnimationReverse = SCNAction.rotateTo(x: 0, y: 0, z: 0.3, duration: 0.1)
        rotateAnimationReverse.timingMode = .linear

        let headReset = SCNAction.rotateTo(x: -0.01, y: 0, z: -0.0, duration: 0.1)

        let sequence = SCNAction.sequence([rotateAnimation, rotateAnimationReverse, rotateAnimation, rotateAnimationReverse, rotateAnimation, rotateAnimationReverse, headReset])

        headNode.runAction(sequence)
    }

    private func easeOutElastic(_ t: Float) -> Float {
        // Timing function that has a "bounce in" effect
        let p: Float = 0.3
        let result = pow(2.0, -5.0 * t) * sin((t - p / 4.0) * (2.0 * Float.pi) / p) + 1.0
        return result
    }

    private static func startButtonRecordAnimation(button: UIButton) {
        let pulseAnimation = CASpringAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 0.6
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.20
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = 1
        pulseAnimation.initialVelocity = 0.8
        pulseAnimation.damping = 0.8

        let animationGroup = CAAnimationGroup()
        animationGroup.duration = 2.7
        animationGroup.repeatCount = .greatestFiniteMagnitude
        animationGroup.animations = [pulseAnimation]

        button.setImage(UIImage(named: "record_stop")!, for: .normal)
        button.imageView?.layer.add(animationGroup, forKey: "pulse")
        button.tintColor = .red
    }

    private static func stopButtonRecordAnimation(button: UIButton) {
        button.imageView?.layer.removeAllAnimations()
        button.setImage(UIImage(named: "record_start")!, for: .normal)
        button.tintColor = UIColor(named: "text_default")!
    }

    // MARK: - Actions
    @IBAction func switchCameraAction(_ sender: Any) {
        switchCamera()
    }

    @IBAction func switchRecordingAction(_ sender: Any) {
        switchRecording()
    }

    @IBAction func switchScreenModeAction(_ sender: Any) {
        switchScreenMode()
    }

    @IBAction func fullScreenAction(_ sender: Any) {
        self.showFullScreen(enabled: !isFullScreen, animated: true)
    }

    @IBAction func help(_ sender: Any) {
        guard let navigationController = storyboard?.instantiateViewController(withIdentifier: HelpViewController.kIdentifier) as? UINavigationController, let helpViewController = navigationController.topViewController as? HelpViewController else { return }
        helpViewController.addMessage(LocalizationManager.shared.localizedString("puppet_help_header"))
        if let image = UIImage(named: "puppet_hand") {
            helpViewController.addImage(image)
        }
        helpViewController.addMessage(LocalizationManager.shared.localizedString("puppet_help_details"))

        self.present(navigationController, animated: true, completion: nil)
    }
}

// MARK: - CPBBleAccelerometerDelegate
extension PuppetViewController: AdafruitAccelerometerDelegate {
    func adafruitAccelerationReceived(_ acceleration: BlePeripheral.AccelerometerValue) {
        self.acceleration = acceleration
        updateValueUI()
    }
}

// MARK: - CPBBleButtonsDelegate
extension PuppetViewController: AdafruitButtonsDelegate {
    func adafruitButtonsReceived(_ newButtonsState: BlePeripheral.ButtonsState) {
        // Check if A became pressed
        if newButtonsState.buttonA == .pressed && newButtonsState.buttonA != buttonsState?.buttonA {
            startSparkyEyesAnimation()
        }

        // Check if B became pressed
        if newButtonsState.buttonB == .pressed && newButtonsState.buttonB != buttonsState?.buttonB {
            startSparkyShakeAnimation()
        }

        // Save current state
        self.buttonsState = newButtonsState
    }
}

// MARK: - RPScreenRecorderDelegate
extension PuppetViewController: RPScreenRecorderDelegate {
    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {

        // Update 'record' button
        DispatchQueue.main.async {
            self.updateRecordButtonUI()
        }
    }

    func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWith previewViewController: RPPreviewViewController?, error: Error?) {

        // Disable Recording
        DispatchQueue.main.async {
            self.disableRecordingUI()
            self.processRecordingStopped(previewViewController: previewViewController, error: error)

            if previewViewController == nil || error != nil {       // No preview controller means that there was an error
                let localizationManager = LocalizationManager.shared
                let alertController = UIAlertController(title: localizationManager.localizedString("puppet_recording_error_title"), message: localizationManager.localizedString("puppet_recording_error_description"), preferredStyle: .alert)
                let okAction = UIAlertAction(title: localizationManager.localizedString("dialog_ok"), style: .default, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - RPPreviewViewControllerDelegate
extension PuppetViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true, completion: nil)
    }
}
