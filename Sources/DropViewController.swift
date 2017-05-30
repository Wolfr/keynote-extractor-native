//
//  DropViewController.swift
//  KeynoteExtractor
//
//  Created by David Sinclair on 2016-10-20.
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


// In progress: run responsive image process
// @todo figure out how to run local command
// currently getting error that launch path is not accessible
func runResponsiveImagesScript() {

    // Create a task…
    let task = Process()
    
    // Select a path…
    task.launchPath = "say2"

    // Pass any arguments to the command…
    
    task.arguments = []
    
    //Launch the task, and block the current thread until it's done…
    task.launch()
    task.waitUntilExit()

}

class DropViewController: NSViewController {

    /// The URL of the Keynote file dropped on the drop view.  Nil if none yet.
    var sourceURL: URL?
    
    // Check if the responsive images checkbox is checked
    @IBAction func responsiveImagesCheck(_ sender: NSButton) {
        if (sender.state == 1) {
            // Checkbox is on so we have to run the script
            print("Checkbox is on")
            runResponsiveImagesScript()
        } else {
            return // do nothing
        }
    }

    /// The URL of the output folder, or nil if none yet.
    var destinationURL: URL?
    
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
            statusLabel.stringValue = "Extracting your document.\n\nApple Keynote will open; please don't close it until done."
        case .success:
            statusLabel.stringValue = "Extraction complete."
            imageView.image = NSImage(named: "Success")
            revealButton.isHidden = false
        case .failure(error: let error):
            report(error: error)
            update(status: .idle)
            break
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
        
        prepareDestination {
            // If the destination URL is nil here, the user must have cancelled when asked about an existing output
            guard let destinationURL = self.destinationURL else {
                self.update(status: .idle)
                return
            }
            
            self.update(status: .processing(percentage: 0))
            
            print("extracting \(url)")
            
            self.extractor = Extractor(sourceURL: url, destinationURL: destinationURL, progressHandler: self.progress, completionHandler: self.completion)
            
            if let extractor = self.extractor {
                extractor.extract()
            }
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
            //print("success: \(result.value)")
        } else {
            update(status: .failure(error: result.error!))
            //print("failure: \(result.error)")
        }
        
        self.extractor = nil
    }
}

private extension DropViewController {
    /// Handle any existing item at the destination URL.
    ///
    /// - Parameter completionHandler: A closure to invoke once the destination URL has been determined.
    func prepareDestination(completionHandler: @escaping () -> Void) {
        guard let baseURL = sourceURL?.deletingPathExtension() else {
            destinationURL = nil
            completionHandler()
            return
        }
    
        let exists = Preferences.shared.exists
        
        // If there isn't anything there, or we want to replace duplicates, we're done
        if !FileManager.default.fileExists(atPath: baseURL.path) || exists == .replace {
            destinationURL = baseURL
            completionHandler()
            return
        }
        
        if exists == .keepBoth {
            destinationURL = uniqueURL(for: baseURL)
            completionHandler()
            return
        }
        
        // Otherwise we need to ask
        guard let window = view.window else {
            destinationURL = nil
            completionHandler()
            return
        }
        
        let alert = NSAlert()
        
        alert.messageText = "This presentation has already been extracted."
        alert.informativeText = "Do you want to replace it, or keep both?"
        alert.addButton(withTitle: "Keep Both")
        alert.addButton(withTitle: "Replace")
        alert.addButton(withTitle: "Cancel")
        
        alert.beginSheetModal(for: window) { (result: NSModalResponse) in
            switch result {
            case NSAlertFirstButtonReturn:
                self.destinationURL = self.uniqueURL(for: baseURL)
            case NSAlertSecondButtonReturn:
                self.destinationURL = baseURL
            default:
                self.destinationURL = nil
            }
            
            completionHandler()
        }
    }
    
    /// Returns a uniqued URL.
    func uniqueURL(for url: URL) -> URL {
        let filename = url.lastPathComponent
        let parentURL = url.deletingLastPathComponent()
        var candidateURL = parentURL
        var suffix = 1
        
        repeat {
            suffix += 1
            let suffixedName = "\(filename) \(suffix)"
            candidateURL = parentURL.appendingPathComponent(suffixedName)
        } while FileManager.default.fileExists(atPath: candidateURL.path)
        
        return candidateURL
    }
    
    /// Report an error.
    func report(error: Error) {
        guard let window = view.window else {
            return
        }
        
        let alert = NSAlert()
        
        if error is AppleScriptError {
            alert.messageText = "Unable to extract the document; open it in Keynote first."
        } else {
            alert.messageText = (error as NSError).localizedDescription
        }
        
        alert.informativeText = "Please try again."
        
        alert.beginSheetModal(for: window)
    }
}
