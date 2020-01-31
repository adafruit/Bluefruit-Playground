//
//  GridView.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

@IBDesignable
class GridView: UIView
{
    // Params
    @IBInspectable var gridSeparation: CGFloat = 10 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // Data
    private var path = UIBezierPath()

    // MARK: - Draw
    override func draw(_ rect: CGRect)
    {
        // Lighter grid
        drawGrid(lineSeparation: gridSeparation, lineWidth: 1, color: UIColor.init(white: 1, alpha: 0.05))
        
        // Stronger grid overlayed
        drawGrid(lineSeparation: gridSeparation * 4, lineWidth: 1, color: UIColor.init(white: 1, alpha: 0.2))
    }
    
    private func drawGrid(lineSeparation: CGFloat, lineWidth: CGFloat, color: UIColor)
    {
        path = UIBezierPath()
        
        var x: CGFloat = 0
        repeat {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: bounds.height))
            
            x = x + lineSeparation
        } while (x < bounds.width)
        
        var y: CGFloat = 0
        repeat {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: bounds.width, y: y))
            
            y = y + lineSeparation
        } while (y < bounds.height)
        
        path.close()

        path.lineWidth = lineWidth
        color.setStroke()
        path.stroke()

    }
}
