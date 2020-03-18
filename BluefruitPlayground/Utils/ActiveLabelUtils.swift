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
            let color = UIColor(named: "text_link") ?? .blue
            let selectedColor = color.lighter()
            
            label.enabledTypes = [.url]
            label.URLColor = color
            label.URLSelectedColor = selectedColor
            
            // Search general link
            addLink(label: label, linkPrefix: "\(linksLocalizationStringsIdPrefix)_link")
            
            // Search numbered links
            var found = true
            var i = 0
            repeat {
                found = addLink(label: label, linkPrefix: "\(linksLocalizationStringsIdPrefix)_link\(i)")
                i = i + 1

            } while(found)
            
            // Add handle for text urls
            label.handleURLTap { url in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
            // Modify link style
            label.configureLinkAttribute = { (type, attributes, isSelected) in
                var atts = attributes
                if label.enabledTypes.contains(type) {
                    atts[.underlineStyle] = NSUnderlineStyle.single.rawValue
                }
                return atts
            }
        }
    }
    
    /**
        Add link to an ActiveLabel
        returns: true if a link matching the text is found on localization strings
     */
    @discardableResult
    private static func addLink(label: ActiveLabel, linkPrefix: String) -> Bool {
        let localizationManager = LocalizationManager.shared
        guard let linkString = localizationManager.localizedStringIfExists("\(linkPrefix)_text") else { return false }
        let customType = ActiveType.custom(pattern: "(\\w*\(linkString)\\w*)")
        label.enabledTypes.append(customType)
        
        let color = UIColor(named: "text_link") ?? .blue
        let selectedColor = color.lighter()
        
        label.customColor[customType] = color
        label.customSelectedColor[customType] = selectedColor
        
        if let linkUrl = URL(string: localizationManager.localizedString("\(linkPrefix)_url")) {
            label.handleCustomTap(for: customType) { _ in
                UIApplication.shared.open(linkUrl, options: [:], completionHandler: nil)
            }
        }
        
        return true
    }
}
