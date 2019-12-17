//
//  ScreenFlowManager.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 10/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

struct ScreenFlowManager {
    
    // MARK: - Go to app areas
    public static func gotoScanner() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let rootNavigationViewController = mainStoryboard.instantiateViewController(withIdentifier: ScannerViewController.kIdentifier)
        ScreenFlowManager.changeRootViewController(rootViewController: rootNavigationViewController, animated: false)
    }
    
    public static func restoreAndGoToHome() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)

        // Add home to scanner
        let rootNavigationViewController = mainStoryboard.instantiateViewController(withIdentifier: ScannerViewController.kIdentifier) as! UINavigationController
        let homeViewController = mainStoryboard.instantiateViewController(withIdentifier: HomeViewController.kIdentifier)
        rootNavigationViewController.viewControllers.append(homeViewController)

        ScreenFlowManager.changeRootViewController(rootViewController: rootNavigationViewController, animated: false)
    }
    
    
    // MARK: - Change Root View Controller
    public static func changeRootViewController(rootViewController: UIViewController, animated: Bool = true, completionHandler: (() -> Void)? = nil ) {
        guard let window = UIApplication.shared.keyWindow else { return }
        
        if animated {
            rootViewController.view.layoutIfNeeded()
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = rootViewController
            }, completion: { completed in
                completionHandler?()
            })
        }
        else {
            window.rootViewController = rootViewController
            completionHandler?()
        }
    }
}
