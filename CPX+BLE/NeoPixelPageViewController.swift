//
//  NeoPixelViewController.swift
//  CPX+BLE
//
//  Created by Trevor B on 9/16/19.
//  Copyright © 2019 Adafruit Industries LLC. All rights reserved.
//

import Foundation
import UIKit




class NeoPixelPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    

private var pageViewController: UIPageViewController!

    lazy var viewControllerList: [UIViewController] = {
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        
        let vc1 = sb.instantiateViewController(withIdentifier: "intro1")
        let vc2 = sb.instantiateViewController(withIdentifier: "intro2")
        let vc3 = sb.instantiateViewController(withIdentifier: "intro3")
        
        return [vc1, vc2, vc3]
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.dataSource = self
        self.delegate = self
        if let firstViewController = viewControllerList.first {
            self.setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
      //  configPageControl()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
//    func configPageControl() {
//
//        pageControl = UIPageControl(frame: CGRect(x: 0, y: UIScreen.main.bounds.maxY - 50, width:
//            UIScreen.main.bounds.width, height: 50))
//
//        pageControl.numberOfPages = viewControllerList.count
//        pageControl.currentPage = 0
//        pageControl.tintColor = UIColor.lightGray
//        pageControl.currentPageIndicatorTintColor = UIColor.white
//        pageControl.pageIndicatorTintColor = UIColor.lightGray
//        pageControl.isEnabled = false
//        self.view.addSubview(pageControl)
//
//    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageContentViewController = pageViewController.viewControllers![0]
//        pageControl.currentPage = viewControllerList.index(of: pageContentViewController)!
//        print("Page Check: \(pageControl.currentPage)")
    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let vcIndex = viewControllerList.index(of: viewController) else {return nil}
        let previousIndex = vcIndex - 1
        
        guard previousIndex >= 0 else {return nil}
        
        guard viewControllerList.count > previousIndex else {return nil}
        return viewControllerList[previousIndex]
        
    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let vcIndex = viewControllerList.index(of: viewController) else {return nil}
        
        let nextIndex = vcIndex + 1
        
        guard viewControllerList.count != nextIndex else {return nil}
        
        guard viewControllerList.count > nextIndex else {return nil}
        
        return viewControllerList[nextIndex]
        
    }
    
    
    
    

}
