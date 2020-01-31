//
//  TipsAnimationComposerViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 09/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class TipsAnimationComposerViewController: UIViewController {

    // Data
    private var tipAnimationViewControllers = [TipAnimationViewController]()
    
    private var isFirstTime = true
    
    private var previousPage = 0
    
        // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
     override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Order based on tag
        tipAnimationViewControllers.sort(by: {$0.view.tag < $1.view.tag})
        
        //
        if isFirstTime {
            setOffset(0, pageWidth: self.view.bounds.width)     // Force first step
            isFirstTime = false
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? TipAnimationViewController {
            tipAnimationViewControllers.append(viewController)
        }
    }
    
    // MARK: - Actions
    func setOffset(_ offset: CGFloat, pageWidth: CGFloat) {
        let page = Int(floor(offset / pageWidth))
        let offsetInPage = offset.truncatingRemainder(dividingBy: pageWidth)
        let progress = offsetInPage / pageWidth
        
        let viewControllers = tipAnimationViewControllers
        
        // Visibility
        for (i, viewController) in viewControllers.enumerated() {
            let isShown = i==page
                //|| (i==0 && page<0) // is First view controller and page is negative
                //|| (i==viewControllers.count-1 && page>viewControllers.count-1)    // is Last view controller and page is beyond bounds
                || i==page-1
                || i==page+1
            viewController.view.isHidden = !isShown
        }
        
        //DLog("page: \(page) offset: \(offsetInPage)/\(pageWidth) progress: \(progress)")
        guard page >= 0, page < viewControllers.count else { return }

        if page != previousPage {
            //DLog("animation page changed: \(previousPage) -> \(page)")
            // Send last update to the previous controller with start progress or end progress
            viewControllers[previousPage].setAnimationProgress(page>previousPage ? 1:-1)
            previousPage = page
        }

        if page>0 { // send progress to previous page
            viewControllers[page-1].setAnimationProgress(progress+1)
        }
        viewControllers[page].setAnimationProgress(progress)        // Send progress to current page
        if page < viewControllers.count-1 {     // send progress to next page
            viewControllers[page+1].setAnimationProgress(progress-1)
        }
    }
}
