//
//  ColorSliderControl.swift
//  FlexColorPicker
//
//  Created by Rastislav Mirek on 28/5/18.
//  
//	MIT License
//  Copyright (c) 2018 Rastislav Mirek
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit

public let OUTSIDE_DRAG_HORIZONTAL_TO_VERTICAL_TRANSLATION_RATIO: CGFloat = 2.5

private let defaultGradientViewHeight: CGFloat = 15

/// Color control that allows to change selected color by tapping a point on (or panning over) a line. The control displays color preview for all positions in that line.
/// 
/// Any subvies must be added to `contentView` only for this to work correctly inside `UIScrollView` and iOS 13 modal view controllers.
@IBDesignable
open class ColorSliderControl: ColorControlWithThumbView {

    /// This is view behind gradient that can be used to show custom color options preview if the preview cannot be represented by simple gradient.
    public let gradientBackgroundView = UIImageView()
    /// Previews color options avaialable va chnaging value of the slider in form of linear gradient.
    public let gradientView = GradientView()
    
    /// When `true` the thumb shows 100% label for left-most possition of the slider and 0% for right-most possition. Default is `false` (0% is displayed on left). Has no effect if `thumbLabelFormatter` is set.
    ///
    /// This is usefull e.g. when "physically correct" percentage label behaviour of `BrightnessSliderControl` is preferred (as the most "bright" color is on the left of the slider in that case).
    public var reversePercentage: Bool = false {
        didSet {
            let (value, _, _) = sliderDelegate.valueAndGradient(for: selectedHSBColor)
            updatePercentageLabel(for: value)
        }
    }
    
    /// When set to non-nil value it will be used to generate label text of `thumbView` directly instead of via setting `thumbView`s `percentage` property. setting this overrides `percentage` property.
    public var thumbLabelFormatter: ((CGFloat) -> String)? {
        didSet {
            let (value, _, _) = sliderDelegate.valueAndGradient(for: selectedHSBColor)
            updatePercentageLabel(for: value)
        }
    }

    /// Whether to display default thin border around the slider.
    @IBInspectable
    public var borderOn: Bool = true {
        didSet {
            updateBorder(visible: borderOn, view: gradientBackgroundView)
        }
    }
    
    /// A delegate that specifies gradient of the slider and how selecting a value is interpreted.
    open var sliderDelegate: ColorSliderDelegate = BrightnessSliderDelegate() {
        didSet {
            updateThumbAndGradient(isInteractive: false)
        }
    }

    open override var bounds: CGRect {
        didSet {
            guard oldValue != bounds else {
                return
            }
            updateCornerRadius()
            updateThumbAndGradient(isInteractive: false)
        }
    }

    open override var intrinsicContentSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: defaultGradientViewHeight)
    }

    open override func commonInit() {
        super.commonInit()
        contentView.addAutolayoutFillingSubview(gradientBackgroundView)
        gradientBackgroundView.addAutolayoutFillingSubview(gradientView)
        updateCornerRadius()
        gradientBackgroundView.clipsToBounds = true
        updateThumbAndGradient(isInteractive: false)
        contentView.addSubview(thumbView)
        updateBorder(visible: borderOn, view: gradientBackgroundView)
    }

    open override func setSelectedHSBColor(_ hsbColor: HSBColor, isInteractive interactive: Bool) {
        super.setSelectedHSBColor(hsbColor, isInteractive: interactive)
        updateThumbAndGradient(isInteractive: interactive)
    }

    private func updateCornerRadius() {
        gradientBackgroundView.cornerRadius_ = contentBounds.height / 2
    }

    /// Updates slider's preview (the gradient) to reflect current state of the slider (e.g. value of `selectedHSBColor` and `sliderDelegate`).
    ///
    /// Override this if you need to update slider's visual state differently on state change.
    ///
    /// - Parameter interactive:  Whether the change originated from user interaction or is programatic. This can be used to determine if certain animations should be played.
    open func updateThumbAndGradient(isInteractive interactive: Bool) {
        layoutIfNeeded() //force subviews layout to update their bounds - bounds of subviews are not automatically updated
        let (value, gradientStart, gradientEnd) = sliderDelegate.valueAndGradient(for: selectedHSBColor)
        let gradientLength = contentBounds.width - thumbView.colorIdicatorRadius * 2 //cannot use self.bounds as that is extended compared to foregroundImageView.bounds when AdjustedHitBoxColorControl.hitBoxInsets are non-zero
        thumbView.frame = CGRect(center: CGPoint(x: thumbView.colorIdicatorRadius + gradientLength * min(max(0, value), 1), y: contentView.bounds.midY), size: thumbView.intrinsicContentSize)
        thumbView.setColor(selectedHSBColor.toUIColor(), animateBorderColor: interactive)
        gradientView.startOffset = thumbView.colorIdicatorRadius
        gradientView.endOffset = thumbView.colorIdicatorRadius
        gradientView.startColor = gradientStart //to keep the gradient realistic (you select exactly the same color that you tapped) we need to offset gradient as tapping first and last part of gradient (of length thumbView.colorIdicatorRadius) always selects max or min color
        gradientView.endColor = gradientEnd
    }

    open override func updateSelectedColor(at point: CGPoint, isInteractive: Bool) {
        let gradientLength = contentBounds.width - thumbView.colorIdicatorRadius * 2
        let value = max(0, min(1, (point.x - thumbView.colorIdicatorRadius) / gradientLength))
        updatePercentageLabel(for: value)
        setSelectedHSBColor(sliderDelegate.modifiedColor(from: selectedHSBColor, with: min(max(0, value), 1)), isInteractive: isInteractive)
        sendActions(for: .valueChanged)
    }
    
    public func updatePercentageLabel(for value: CGFloat) {
        thumbView.percentage = Int(round((reversePercentage ? 1 - value : value) * 100))
        if let thumbLabelFormatter = thumbLabelFormatter {
            thumbView.percentageLabel.text = thumbLabelFormatter(value)
        }
    }
    
    /// Updates  border color of the color slider control when interface is changed to dark or light mode.
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *), traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle  {
            updateBorder(visible: borderOn, view: gradientBackgroundView)
        }
    }
}

extension ColorSliderControl {
    /// When `true` the slider's thumb will automatically darken its border when selected color is too bright to be contrast enought with white border.
    @IBInspectable
    public var autoDarken: Bool {
        get {
            return thumbView.autoDarken
        }
        set {
            thumbView.autoDarken = newValue
        }
    }

    /// Whether to show selected value as percentage above the thumb view while user is interacting with the slider.
    @IBInspectable
    public var showPercentage: Bool {
        get {
            return thumbView.showPercentage
        }
        set {
            thumbView.showPercentage = newValue
        }
    }

    /// Whether the slider's thumb view should be expanded when a user is interacting with the slider.
    @IBInspectable
    public var expandOnTap: Bool {
        get {
            return thumbView.expandOnTap
        }
        set {
            thumbView.expandOnTap = newValue
        }
    }

    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        let translation = gestureRecognizer.translation(in: self)
        return abs(translation.x) * OUTSIDE_DRAG_HORIZONTAL_TO_VERTICAL_TRANSLATION_RATIO < abs(translation.y) || !bounds.contains(gestureRecognizer.location(in: self)) && abs(translation.x) < abs(translation.y)
    }
}
