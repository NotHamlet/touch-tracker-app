//
//  DrawView.swift
//  TouchTracker
//
//  Created by Stephen Atwood on 3/18/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import UIKit

class DrawView: UIView, UIGestureRecognizerDelegate {
    
    // MARK: Properties
    
    var currentLines = [NSValue:Line]()
    var finishedLines = [Line]()
    var selectedLineIndex: Int? {
        didSet {
            if selectedLineIndex == nil {
                let menu = UIMenuController.sharedMenuController()
                menu.setMenuVisible(false, animated: true)
            }
        }
    }
    var moveRecognizer: UIPanGestureRecognizer!
    
    
    // MARK: IBInspectable Properties
    
    @IBInspectable var finishedLineColor: UIColor = UIColor.blackColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var currentLineColor: UIColor = UIColor.redColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var lineThickness: CGFloat = 10 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    
    // MARK: Initializers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: "doubleTap:")
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tap:")
        tapRecognizer.delaysTouchesBegan = true
        tapRecognizer.requireGestureRecognizerToFail(doubleTapRecognizer)
        addGestureRecognizer(tapRecognizer)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "longPress:")
        addGestureRecognizer(longPressRecognizer)
        
        moveRecognizer = UIPanGestureRecognizer(target: self, action: "moveLine:")
        moveRecognizer.delegate = self
        moveRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(moveRecognizer)
    }
    
    
    // MARK: Drawing methods
    
    func strokeLine(line: Line) {
        let path = UIBezierPath()
        path.lineWidth = lineThickness
        path.lineCapStyle = .Round
        
        path.moveToPoint(line.begin)
        path.addLineToPoint(line.end)
        path.stroke()
    }

    override func drawRect(rect: CGRect) {
        // Draw finished lines in black
        finishedLineColor.setStroke()
        for line in finishedLines {
            strokeLine(line)
        }

        // Draw current lines in red
        currentLineColor.setStroke()
        for (_, line) in currentLines {
            strokeLine(line)
        }
        
        if let index = selectedLineIndex {
            UIColor.greenColor().setStroke()
            let selectedLine = finishedLines[index]
            strokeLine(selectedLine)
        }
    }
    
    
    // MARK: UIResponder touch event handlers
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        // Let's put in a log statement to see the order of events
        print(__FUNCTION__)
        
        for touch in touches {
            let location = touch.locationInView(self)
            
            let newLine = Line(begin: location, end: location)
            
            let key = NSValue(nonretainedObject: touch)
            currentLines[key] = newLine
        }
        
        setNeedsDisplay()
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        // Let's put in a log statement to see the order of events
        print(__FUNCTION__)
        
        for touch in touches {
            let location = touch.locationInView(self)
            let key = NSValue(nonretainedObject: touch)
            currentLines[key]?.end = location
        }
        setNeedsDisplay()
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        // Let's put in a log statement to see the order of events
        print(__FUNCTION__)
        
        for touch in touches {
            let key = NSValue(nonretainedObject: touch)
            if var line = currentLines[key] {
                let location = touch.locationInView(self)
                line.end = location
                
                finishedLines.append(line)
                currentLines.removeValueForKey(key)
            }
        }
        
        setNeedsDisplay()
        
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        // Let's put in a log statement to see the order of events
        print(__FUNCTION__)
        
        currentLines.removeAll()
        
        setNeedsDisplay()
    }
    
    
    // MARK: UIResponder methods
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    
    // MARK: UIGestureRecognizer methods
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
    // MARK: Miscellaneous event handlers
    
    func doubleTap(gestureRecognizer: UIGestureRecognizer) {
        print("Recognized a double tap")
        
        selectedLineIndex = nil
        currentLines.removeAll(keepCapacity: false)
        finishedLines.removeAll(keepCapacity: false)
        setNeedsDisplay()
    }
    
    func tap(gestureRecognizer: UIGestureRecognizer) {
        print("Recognized a tap")
        
        let point = gestureRecognizer.locationInView(self)
        selectedLineIndex = indexOfLineAtPoint(point)
        
        // Grab the menu controller
        let menu = UIMenuController.sharedMenuController()
        
        if selectedLineIndex != nil {
            
            // Make DrawView the target of menu item action messages
            becomeFirstResponder()
            
            // Create a new "Delete" UIMenuItem
            let deleteItem = UIMenuItem(title: "Delete", action: "deleteLine:")
            menu.menuItems = [deleteItem]
            
            // Tell the menu where it should come from and show it
            menu.setTargetRect(CGRect(x: point.x, y: point.y, width: 2, height: 2), inView: self)
            menu.setMenuVisible(true, animated: true)
        }
        else {
            // Hide the menu if no line is selected
            menu.setMenuVisible(false, animated: true)
        }
        
        setNeedsDisplay()
    }
    
    func indexOfLineAtPoint(point: CGPoint) -> Int? {
        
        // Fine a line close to point
        for (index, line) in finishedLines.enumerate() {
            let begin = line.begin
            let end = line.end
            
            // Check a few points on the line
            for t in CGFloat(0).stride(to: 1.0, by: 0.05) {
                let x = begin.x + ((end.x - begin.x) * t)
                let y = begin.y + ((end.y - begin.y) * t)
                
                // If the tapped point is within 20 points, let's return this line
                if hypot(x-point.x, y-point.y) < 20 {
                    return index
                }
            }
        }
        
        // If nothing is close enough to the tapped point, then we did not select a line
        return nil
    }
    
    func deleteLine(sender: AnyObject) {
        // Remove the selected line from the list of finishedLines
        if let index = selectedLineIndex {
            finishedLines.removeAtIndex(index)
            selectedLineIndex = nil
            
            // Redraw everything
            setNeedsDisplay()
        }
    }
    
    func longPress(gestureRecognizer: UIGestureRecognizer) {
        print("Recognized a long press")
        
        if gestureRecognizer.state == .Began {
            let point = gestureRecognizer.locationInView(self)
            selectedLineIndex = indexOfLineAtPoint(point)
            
            if selectedLineIndex != nil {
                currentLines.removeAll(keepCapacity: false)
            }
        }
        else if gestureRecognizer.state == .Ended {
            selectedLineIndex = nil
        }
        
        setNeedsDisplay()
    }
    
    func moveLine(gestureRecognizer: UIPanGestureRecognizer) {
        print("Recognized a pan")
        
        // If a line is selected...
        if let index = selectedLineIndex {
            // When the pan recognizer changes its position
            if gestureRecognizer.state == .Changed {
                // How far has the pan moved?
                let translation = gestureRecognizer.translationInView(self)
                
                // Add the translation to the current beginning and end points of the line
                finishedLines[index].begin.x = finishedLines[index].begin.x + translation.x
                finishedLines[index].begin.y = finishedLines[index].begin.y + translation.y
                finishedLines[index].end.x = finishedLines[index].end.x + translation.x
                finishedLines[index].end.y = finishedLines[index].end.y + translation.y
                
                gestureRecognizer.setTranslation(CGPoint.zero, inView: self)
                
                // Redraw the screen
                setNeedsDisplay()
            }
        }
        else {
            // If no line is selected, don't do anything
        }
    }
}
