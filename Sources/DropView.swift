//
//  DropView.swift
//  KeynoteExtractor
//
//  Created by David Sinclair on 2016-10-20.
//

import Cocoa

@IBDesignable
class DropView: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame:frameRect);
        
        setupDragging()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupDragging()
    }
    
    @IBInspectable public var highlighted = false {
        didSet {
            needsDisplay = true
            
            if !highlighted {
                url = nil
            }
        }
    }
    
    public weak var delegate: DropDelegate?
    
    var url: URL?
    
    override func draw(_ dirtyRect: NSRect) {
        if highlighted {
            NSColor(white: 0.3, alpha: 0.2).setFill()
        } else {
            NSColor(white: 0.8, alpha: 0.1).setFill()
        }
        
        NSColor.gray.setStroke()
        
        let bezierPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 2.0, dy: 2.0), xRadius: 10.0, yRadius: 10.0)
        bezierPath.setLineDash([3.0, 3.0], count: 2, phase: 0.0)
        
        bezierPath.fill()
        bezierPath.stroke()
    }
    
    private func setupDragging() {
        register(forDraggedTypes: [kUTTypeFileURL as String])
    }
}

//MARK: Dragging
extension DropView {
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if let paths = sender.draggingPasteboard().propertyList(forType: NSFilenamesPboardType) as? NSArray, let path = paths[0] as? String {
            let fileURL = URL(fileURLWithPath: path)
            let fileExtension = fileURL.pathExtension.lowercased()
            
            if fileExtension == "key" {
                highlighted = true
                url = fileURL
                return .every
            }
        }
        
        return []
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        highlighted = false
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard highlighted, let url = url else {
            return false
        }
        
        highlighted = false
        
//        Swift.print("\(url)")
        
        // Invoke the delegate asyncronously, so the drop is completed first
        if let delegate = delegate {
            DispatchQueue.main.async {
                delegate.dropped(url: url)
            }
        }
        
        return true
    }
}

