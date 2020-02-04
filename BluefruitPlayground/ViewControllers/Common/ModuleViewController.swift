//
//  ModuleViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 17/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class ModuleViewController: UIViewController {
    // Constants
    private static let kStartingPage = Config.isDebugEnabled ? 0:0
    
    // UI
    @IBOutlet weak var panelsContainerView: UIView!
    @IBOutlet weak var baseScrollView: UIScrollView!
    @IBOutlet weak var contentWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var pageControl: UIPageControl?
    
    // Data
    private var panelViewControllers = [UIViewController]()
    private var panelLeadingConstraints = [NSLayoutConstraint]()
    private var previousPage = -1
    private var currentPage: Int {
        return pageFromOffset(baseScrollView.contentOffset.x)
    }
    private var isInLastPage: Bool {
        return currentPage >= panelViewControllers.count-1
    }
    private var isFirstTime = true
    
    var moduleHelpMessage: String?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup page control
        pageControl?.addTarget(self, action: #selector(pageControlTapHandler(sender:)), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Navigationbar setup
        if let customNavigationBar = navigationController?.navigationBar as? NavigationBarWithScrollAwareRightButton {
            customNavigationBar.setRightButton(topViewController: self, image: UIImage(named: "help"), target: self, action: #selector(help(_:)))
        }
        
        // Page control setup
        pageControl?.numberOfPages = panelViewControllers.count
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isFirstTime {
            isFirstTime = false
            baseScrollView.scrollRectToVisible(CGRect(x: CGFloat(ModuleViewController.kStartingPage) * baseScrollView.bounds.width, y: 0, width: baseScrollView.bounds.width, height: baseScrollView.bounds.height), animated: true)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        contentWidthConstraint.constant = CGFloat(panelViewControllers.count) * baseScrollView.bounds.width
        for (i, leadingConstraint) in panelLeadingConstraints.enumerated() {
            leadingConstraint.constant = CGFloat(i) * baseScrollView.bounds.width
        }
    }
    
    // MARK: - UI
    func addPanelViewController(storyboardIdentifier: String) -> ModulePanelViewController? {
        // Instanciate
        guard let panelViewController = storyboard?.instantiateViewController(withIdentifier: storyboardIdentifier) as? ModulePanelViewController, let subview = panelViewController.view else { return nil }
        
        // Add to scrollview
        subview.translatesAutoresizingMaskIntoConstraints = false
        panelsContainerView.addSubview(subview)
        self.addChild(panelViewController)
        
        // Add constraints
        let dictionaryOfVariableBindings = ["subview": subview as Any]
        panelsContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[subview]|", options: [], metrics: nil, views: dictionaryOfVariableBindings))
        let leadingConstraint = NSLayoutConstraint(item: subview, attribute: .leading, relatedBy: .equal, toItem: panelsContainerView, attribute: .leading, multiplier: 1, constant: 0)
        panelsContainerView.addConstraint(leadingConstraint)
        
        NSLayoutConstraint(item: subview, attribute: .width, relatedBy: .equal, toItem: baseScrollView, attribute: .width, multiplier: 1, constant: 0).isActive = true
        
        // Finished
        panelViewController.didMove(toParent: self)
        
        // Add variables to arrays
        panelViewControllers.append(panelViewController)
        panelLeadingConstraints.append(leadingConstraint)
        
        return panelViewController
    }
    
    // MARK: - Page Management
    func onPageChanged(_ page: Int) {
        pageControl?.currentPage = page
    }
    
    func onFinishedScrollingToPage(_ page: Int) {
        // implement on descentants if needed
    }
    
    func goToPage(_ page: Int, animated: Bool) {
        if animated {
            baseScrollView.scrollRectToVisible(CGRect(x: CGFloat(page) * baseScrollView.bounds.width, y: 0, width: baseScrollView.bounds.width, height: baseScrollView.bounds.height), animated: true)
        }
        else {
            baseScrollView.contentOffset = CGPoint(x: CGFloat(page) * baseScrollView.bounds.width, y: 0)
        }
    }
    
    private func pageFromOffset(_ offset: CGFloat) -> Int {
        guard panelViewControllers.count > 0 else { return -1 }
        let contentWidth = baseScrollView.contentSize.width
        guard contentWidth > 0 else { return -1 }
        return Int(round(offset / (contentWidth / CGFloat(panelViewControllers.count))))
    }
    
    @objc private func pageControlTapHandler(sender: UIPageControl) {
        goToPage(sender.currentPage, animated: true)
    }
    
    // MARK: - Actions
    @IBAction func help(_ sender: Any) {
        guard let navigationController = storyboard?.instantiateViewController(withIdentifier: HelpViewController.kIdentifier) as? UINavigationController, let helpViewController = navigationController.topViewController as? HelpViewController else { return }
        helpViewController.message = moduleHelpMessage
        
        self.present(navigationController, animated: true, completion: nil)
    }
}

// MARK: - UIScrollViewDelegate
extension ModuleViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /*
        // NavigationBar Button Custom Animation
        if let customNavigationBar = navigationController?.navigationBar as? NavigationBarWithScrollAwareRightButton {
            customNavigationBar.updateRightButtonPosition()
        }*/
        
        // Calculate current page
        if currentPage != previousPage {
            onPageChanged(currentPage)
            previousPage = currentPage
        }
        // DLog("Page: \(currentPage) - offsetX: \(scrollView.contentOffset.x)")
    }
    
   func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
         onFinishedScrollingToPage(currentPage)
     }
     
     func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
         onFinishedScrollingToPage(currentPage)
     }
}
