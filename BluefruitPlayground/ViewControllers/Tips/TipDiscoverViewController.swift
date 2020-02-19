//
//  TipDiscoverViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 17/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class TipDiscoverViewController: TipAnimationViewController {

    // UI
    @IBOutlet weak var scaleView: UIView!
    @IBOutlet weak var botContainerView: UIView!
    @IBOutlet weak var armImageView: UIImageView!
    @IBOutlet weak var bodyWidthConstraint: NSLayoutConstraint!

    // Data
    enum AnimationState {
        case reset
        case intro
    }
    private var animationState = AnimationState.reset {
        didSet {
            DLog("discover animationState state: \(animationState)")
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        botContainerView.alpha = 0
        resetIntro()
        registerNotifications(enabled: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let margin: CGFloat = 30
        let originalSize = bodyWidthConstraint.constant
        let minDimension = min(self.view.bounds.width - margin*2, self.view.bounds.height - margin*2)
        let scale = minDimension / originalSize

        scaleView.transform = CGAffineTransform(scaleX: scale, y: scale)
    }

    deinit {
        registerNotifications(enabled: false)
    }

    // MARK: - Notifications
    private var applicationDidBecomeActiveObserver: NSObjectProtocol?

    private func registerNotifications(enabled: Bool) {
        let notificationCenter = NotificationCenter.default
        if enabled {
            applicationDidBecomeActiveObserver = notificationCenter.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
                guard let self = self else { return }

                // Restore animation if the user move the app to the background
                self.startArmAnimation()
            }
        } else {
            if let applicationDidBecomeActiveObserver = applicationDidBecomeActiveObserver {notificationCenter.removeObserver(applicationDidBecomeActiveObserver)}
        }
    }

    // MARK: - Animations
    private func resetIntro() {
        animationState = .reset
    }

    private func animateIntro() {
        animationState = .intro

        // Start arm animation
        startArmAnimation()
    }

    private func startArmAnimation() {
         let originalArmSize = armImageView.image!.size
         let anchorPoint = CGPoint(x: 0.95, y: 0.25)

         armImageView.layer.removeAllAnimations()

         self.armImageView.transform = .identity
         UIView.animate(withDuration: 2, delay: 0, options: [.repeat, .autoreverse], animations: {

             var transform = CGAffineTransform(translationX: (anchorPoint.x - 0.5) * originalArmSize.width, y: (anchorPoint.y - 0.5) * originalArmSize.height)
             transform = transform.rotated(by: 15 * .pi / 180)
             transform = transform.translatedBy(x: -(anchorPoint.x - 0.5) * originalArmSize.width, y: -(anchorPoint.y - 0.5) * originalArmSize.height)

             self.armImageView.transform = transform

         }, completion: nil)
     }

    // MARK: - Actions
    override func setAnimationProgress(_ progress: CGFloat) {
        //DLog("discover progress: \(progress)")

        if progress < 0 {
            // Transition (appearing)
            let appearProgress = progress + 1
            botContainerView.alpha = appearProgress
            botContainerView.transform = CGAffineTransform(translationX: (1-appearProgress) * self.view.bounds.width, y: (1-appearProgress) * self.view.bounds.height)
        } else {
            botContainerView.alpha = 1

            switch animationState {
            case .reset:
                animateIntro()

            case .intro:
                break
            }
        }
    }
}
