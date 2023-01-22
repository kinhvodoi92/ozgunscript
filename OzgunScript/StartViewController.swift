//
//  StartViewController.swift
//  OzgunScript
//
//  Created by DucDT on 21/01/2023.
//

import Cocoa

class StartViewController: NSViewController {
	
	@IBOutlet var nameView: NSTextField!
	@IBOutlet var pathView: NSButton!
	@IBOutlet var saveView: NSButton!
	
	private lazy var pcName: String? = UserDefaults.standard.string(forKey: nameKey) ?? Host.current().localizedName
	private lazy var path: String? = UserDefaults.standard.string(forKey: pathKey)
	
	private let nameKey = "PCNameKey"
	private let pathKey = "WorkPathKey"

    override func viewDidLoad() {
        super.viewDidLoad()
		
		saveView.attributedTitle = NSAttributedString(string: "Save", attributes: [.foregroundColor: NSColor.green])
		
		if let pcName = pcName {
			nameView.stringValue = pcName
		}
		if let path = path {
			pathView.title = path
		}
    }
    
	@IBAction func choosePath(_ button: NSButton) {
		let dialog = NSOpenPanel();

		dialog.title                   = "Choose folder";
		dialog.showsResizeIndicator    = true
		dialog.showsHiddenFiles        = false
		dialog.allowsMultipleSelection = false
		dialog.canChooseDirectories = true
		dialog.canChooseFiles = false

		if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
			if let path = dialog.url?.path {
				self.path = path
				self.pathView.title = path
			}
		}
	}
	
	@IBAction func save(_ button: NSButton) {
		let name = nameView.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
		if name.isEmpty {
			return showError("You must enter your pc name!")
		}
		if path == nil {
			return showError("You must select project path!")
		}

		pcName = name
		
		UserDefaults.standard.set(name, forKey: nameKey)
		UserDefaults.standard.set(path, forKey: pathKey)
		
		if let vc = NSStoryboard(name: "Main", bundle: .main).instantiateController(withIdentifier: "ViewController") as? ViewController {
			vc.computerName = pcName ?? ""
			vc.workPath = path ?? ""
			self.view.window?.contentViewController = vc
		}
	}
	
	private func showError(_ error: String) {
		let alert = NSAlert()
		
					alert.messageText = error
		
					alert.addButton(withTitle: "OK")
		
					alert.alertStyle = .critical
		
					alert.runModal()
	}
}
