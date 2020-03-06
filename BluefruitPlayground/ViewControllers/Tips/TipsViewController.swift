//
//  TipsViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 09/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class TipsViewController: UIViewController {
    // Constants
    static let kIdentifier = "TipsViewController"
    private static let kNumTips = 3
    private static let kStartingPage = Config.isDebugEnabled ? 0:0

    // UI
    @IBOutlet weak var tipsContainerView: UIView!
    @IBOutlet weak var baseScrollView: UIScrollView!
    @IBOutlet weak var contentWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!

    // Data
    private var tipsAnimationComposerViewController: TipsAnimationComposerViewController?
    private var tipViewControllers = [TipViewController]()
    private var tipLeadingConstraints = [NSLayoutConstraint]()
    private var currentPage: Int {
        return pageFromOffset(baseScrollView.contentOffset.x)
    }
    private var isInLastPage: Bool {
        return currentPage >= TipsViewController.kNumTips-1
    }

    private var previousPage = -1
    private var isFirstTime = true

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup page control
        pageControl.addTarget(self, action: #selector(pageControlTapHandler(sender:)), for: .touchUpInside)

        // Tips
        let localizationManager = LocalizationManager.shared
        for i in 0..<TipsViewController.kNumTips {
            if let tipViewController = addTipViewController() {
                let titleStringId = String(format: "tip%ld_title", i)
                tipViewController.titleText = localizationManager.localizedString(titleStringId)
                let detailStringId = String(format: "tip%ld_detail", i)
                tipViewController.detailText = localizationManager.localizedString(detailStringId)

                let detailTextLinkStringId = String(format: "tip%ld_link_text", i)
                tipViewController.detailTextLinkString = localizationManager.localizedString(detailTextLinkStringId)
                let detailTextLinkUrlId = String(format: "tip%ld_link_url", i)
                tipViewController.detailTextLinkUrl = URL(string: localizationManager.localizedString(detailTextLinkUrlId))

                let actionStringId = String(format: "tip%ld_action", i)
                tipViewController.actionText = localizationManager.localizedString(actionStringId).uppercased()
                tipViewController.actionHandler = { [weak self] in
                    self?.nextPage()
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isFirstTime {
            isFirstTime = false
            baseScrollView.scrollRectToVisible(CGRect(x: CGFloat(TipsViewController.kStartingPage) * baseScrollView.bounds.width, y: 0, width: baseScrollView.bounds.width, height: baseScrollView.bounds.height), animated: true)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        contentWidthConstraint.constant = CGFloat(tipViewControllers.count) * baseScrollView.bounds.width
        for (i, leadingConstraint) in tipLeadingConstraints.enumerated() {
            leadingConstraint.constant = CGFloat(i) * baseScrollView.bounds.width
        }
    }

     // MARK: - Navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let viewController = segue.destination as? TipsAnimationComposerViewController {
            tipsAnimationComposerViewController = viewController
        }
     }

    // MARK: - UI
    private func addTipViewController() -> TipViewController? {
        // Instanciate
        guard let tipViewController = storyboard?.instantiateViewController(withIdentifier: TipViewController.kIdentifier) as? TipViewController, let subview = tipViewController.view else { return nil }

        // Add to scrollview
        subview.translatesAutoresizingMaskIntoConstraints = false
        tipsContainerView.addSubview(subview)
        self.addChild(tipViewController)

        // Add constraints
        let dictionaryOfVariableBindings = ["subview": subview as Any]
        tipsContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[subview]|", options: [], metrics: nil, views: dictionaryOfVariableBindings))
        let leadingConstraint = NSLayoutConstraint(item: subview, attribute: .leading, relatedBy: .equal, toItem: tipsContainerView, attribute: .leading, multiplier: 1, constant: 0)
        tipsContainerView.addConstraint(leadingConstraint)

        NSLayoutConstraint(item: subview, attribute: .width, relatedBy: .equal, toItem: baseScrollView, attribute: .width, multiplier: 1, constant: 0).isActive = true

        // Finished
        tipViewController.didMove(toParent: self)

        // Add variables to arrays
        tipViewControllers.append(tipViewController)
        tipLeadingConstraints.append(leadingConstraint)

        return tipViewController
    }

    // MARK: - Actions
    private func nextPage() {
        if isInLastPage {
            skip(self)
        } else {
            goToPage(currentPage+1)
        }
    }

    private func goToPage(_ page: Int) {
        baseScrollView.scrollRectToVisible(CGRect(x: CGFloat(page) * baseScrollView.bounds.width, y: 0, width: baseScrollView.bounds.width, height: baseScrollView.bounds.height), animated: true)
    }

    @IBAction func skip(_ sender: Any) {
        if Config.isAutomaticConnectionEnabled && Config.useAutomaticConnectionAsDefaultMode {
            ScreenFlowManager.gotoAutoconnect()
        } else {
            ScreenFlowManager.goToManualScan()
        }
    }

    @objc private func pageControlTapHandler(sender: UIPageControl) {
        goToPage(sender.currentPage)
    }

    // MARK: - Page Management
    private func onPageChanged() {

        pageControl.currentPage = currentPage

        let showSkipButton = currentPage < TipsViewController.kNumTips - 1
        UIView.animate(withDuration: 0.3) {
            self.skipButton.alpha = showSkipButton ? 1:0
        }
    }

    private func pageFromOffset(_ offset: CGFloat) -> Int {
         return Int(round(offset / (baseScrollView.contentSize.width / CGFloat(TipsViewController.kNumTips))))
    }
}

// MARK: - UIScrollViewDelegate
extension TipsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
       // DLog("Page: \(currentPage) - offsetX: \(scrollView.contentOffset.x)")
        tipsAnimationComposerViewController?.setOffset(scrollView.contentOffset.x, pageWidth: scrollView.bounds.width)

        if currentPage != previousPage {
            onPageChanged()
            previousPage = currentPage
        }
    }
}
