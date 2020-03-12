//
//  ActiveLabelUtils.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 12/03/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import UIKit
import ActiveLabel

struct ActiveLabelUtils {
    public static func addActiveLabelLinks(label: ActiveLabel, linksLocalizationStringsIdPrefix: String) {
        let localizationManager = LocalizationManager.shared
        label.text  = localizationManager.localizedString("\(linksLocalizationStringsIdPrefix)_text")
        
        label.customize { label in
            //let kMaxLinksNumber = 10        // Maximum number of links
            let color = UIColor(named: "text_link") ?? .blue
            let selectedColor = color.lighter()
            
            label.enabledTypes = [.url]
            label.URLColor = color
            label.URLSelectedColor = selectedColor
            
            // Search links
            var found = true
            var i = 0
            repeat {
                if let linkString = localizationManager.localizedStringIfExists("\(linksLocalizationStringsIdPrefix)_link\(i)_text") {
                    
                    let customType = ActiveType.custom(pattern: "(\\w*\(linkString)\\w*)")
                    label.enabledTypes.append(customType)
                    
                    label.customColor[customType] = color
                    label.customSelectedColor[customType] = selectedColor
                    
                    if let linkUrl = URL(string: localizationManager.localizedString("\(linksLocalizationStringsIdPrefix)_link\(i)_url")) {
                        label.handleCustomTap(for: customType) { _ in
                            UIApplication.shared.open(linkUrl, options: [:], completionHandler: nil)
                        }
                    }
                    
                    i = i + 1
                }
                else {
                    found = false
                }
            } while(found/* && i < kMaxLinksNumber*/)
            
            label.handleURLTap { url in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
            label.configureLinkAttribute = { (type, attributes, isSelected) in
                var atts = attributes
                if label.enabledTypes.contains(type) {
                    atts[.underlineStyle] = NSUnderlineStyle.single.rawValue
                }
                return atts
            }
        }
    }
}
