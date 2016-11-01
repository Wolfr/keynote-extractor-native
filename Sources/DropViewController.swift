//
//  DropViewController.swift
//  KeynoteExtractor
//
//  Created by David Sinclair on 2016-10-20.
//  Copyright © 2016 Mono Company BVBA. All rights reserved.
//

import Cocoa

enum DropStatus {
    case idle
    case processing(percentage: Double)
    case success
    case failure(error: Error)
}

protocol DropDelegate: class {
    /// Delegate function to begin extracting a URL.
    ///
    /// - Parameter url: URL of the Keynote file dropped on the drop view.
    func dropped(url: URL)
}

class DropViewController: NSViewController {
    
    /// The URL of the Keynote file dropped on the drop view.  Nil if none yet.
    var sourceURL: URL?
    
    /// The URL of the output folder.  Nil if none yet.  Currently is the same as the source URL, without the extension, though could be a custom location in the future.
    var destinationURL: URL? {
        if let url = sourceURL {
            return url.deletingPathExtension()
        } else {
            return nil
        }
    }
    
    /// The current phase of the extraction.
    var status = DropStatus.idle
    
    /// Outlet for the drop view, automatically connects the delegate.
    @IBOutlet weak var dropView: DropView! {
        didSet {
            dropView.delegate = self
        }
    }
    
    @IBOutlet weak var containerView: NSView!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var revealButton: NSButton!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var imageView: NSImageView!
    
    /// Extractor to do the work.
    fileprivate var extractor: Extractor? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        update(status: .idle)
    }
    
    /// Returns true if currently processing, or false if in another state.
    var isProcessing: Bool {
        switch status {
        case .processing(_):
            return true
        default:
            return false
        }
    }
    
    /// Updates the status and the UI.
    ///
    /// - Parameter status: The new status.
    func update(status: DropStatus) {
        self.status = status
        
        switch status {
        case .processing(let percentage):
            dropView.isHidden = true
            revealButton.isHidden = true
            progressIndicator.isHidden = false
            progressIndicator.doubleValue = percentage
            imageView.isHidden = true
        default:
            dropView.isHidden = false
            revealButton.isHidden = true
            progressIndicator.isHidden = true
            imageView.isHidden = false
        }
        
        switch status {
        case .idle:
            statusLabel.stringValue = "Drop a Keynote document here\nto export as HTML."
            imageView.image = NSImage(named: "Idle")
        case .processing(_):
            statusLabel.stringValue = "Extracting your document..."
        case .success:
            statusLabel.stringValue = "Extraction complete."
            imageView.image = NSImage(named: "Success")
            revealButton.isHidden = false
        case .failure(let error):
            if error is AppleScriptError {
                statusLabel.stringValue = "Unable to extract the document; open it in Keynote then try again."
            } else {
                statusLabel.stringValue = (error as NSError).localizedDescription
            }
            imageView.image = NSImage(named: "Failure")
        }
    }
    
    /// Handles the File > Open menu command.
    @IBAction func openDocument(_ sender: Any) {
        guard !isProcessing else {
            return
        }
        
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["key"]
        
        openPanel.beginSheetModal(for: view.window!) { (result) in
            if result == NSFileHandlingPanelOKButton {
                if let url = openPanel.url {
                    self.dropped(url: url)
                }
            }
        }
        
    }
    
   /// Reveals the destination folder in the Finder.
    @IBAction func revealInFinder(_ sender: NSButton) {
        if let url = destinationURL {
            NSWorkspace.shared().open(url)
        }
    }
}

extension DropViewController: DropDelegate {
    /// Delegate function to begin extracting a URL.
    ///
    /// - Parameter url: The URL of the Keynote file to extract.
    func dropped(url: URL) {
        guard !isProcessing else {
            return
        }
        
        self.sourceURL = url
        
        NSDocumentController.shared().noteNewRecentDocumentURL(url)
        
        update(status: .processing(percentage: 0))
        
        print("extracting \(url)")
        
        if let destinationURL = destinationURL {
            extractor = Extractor(sourceURL: url, destinationURL: destinationURL, progressHandler: progress, completionHandler: completion)
        }
        
        if let extractor = extractor {
            extractor.extract()
        }
    }
    
    /// Delegate function to update the progress of the extraction.
    ///
    /// - Parameter percentage: The progress percentage.
    func progress(percentage: Double) {
        update(status: .processing(percentage: percentage))
        
        print("progress: \(percentage * 100.0)%")
    }
    
    /// Delegate function invoked when the extraction is either successfully finished or an error occurs.
    ///
    /// - Parameter result: Either success or failure (with an error).
    func completion(result: Result<URL>) {
        if result.isSuccess {
            update(status: .success)
            print("success: \(result.value)")
        } else {
            update(status: .failure(error: result.error!))
            print("failure: \(result.error)")
        }
        
        self.extractor = nil
    }
}

