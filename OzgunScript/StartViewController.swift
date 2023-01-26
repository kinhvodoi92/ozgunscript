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
	@IBOutlet var clonePathView: NSButton!
	@IBOutlet var saveView: NSButton!
	
	private lazy var pcName: String? = UserDefaults.standard.string(forKey: nameKey) ?? Host.current().localizedName
	private lazy var path: String? = UserDefaults.standard.string(forKey: pathKey)
	private var clonePath: String?
//	= UserDefaults.standard.string(forKey: clonePathKey)
	
	private let nameKey = "PCNameKey"
	private let pathKey = "WorkPathKey"
	private let clonePathKey = "ClonePathKey"
	
	deinit {
		print("Deinit ===> \(self.description)")
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		saveView.attributedTitle = NSAttributedString(string: "Save", attributes: [.foregroundColor: NSColor.green])
		
		if let pcName = pcName {
			nameView.stringValue = pcName
		}
		if let path = path {
			pathView.title = "Path: \(path)"
		}
		if let path = clonePath {
			clonePathView.title = "Clone Path: \(path)"
		}
    }
    
	@IBAction func chooseMainPath(_ button: NSButton) {
		let dialog = NSOpenPanel();

		dialog.title                   = "Choose Main folder";
		dialog.showsResizeIndicator    = true
		dialog.showsHiddenFiles        = false
		dialog.allowsMultipleSelection = false
		dialog.canChooseDirectories = true
		dialog.canChooseFiles = false

		if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
			if let path = dialog.url?.path {
				self.path = path
				self.pathView.title = "Path: \(path)"
			}
		}
	}
	
	@IBAction func chooseClonePath(_ button: NSButton) {
		let dialog = NSOpenPanel();

		dialog.title                   = "Choose Clone folder";
		dialog.showsResizeIndicator    = true
		dialog.showsHiddenFiles        = false
		dialog.allowsMultipleSelection = false
		dialog.canChooseDirectories = true
		dialog.canChooseFiles = false

		if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
			if let path = dialog.url?.path {
				self.clonePath = path
				self.clonePathView.title = "Clone Path: \(path)"
			}
		}
	}
	
	@IBAction func save(_ button: NSButton) {
		let name = nameView.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
		if name.isEmpty {
			return Utils.showError("You must enter your pc name!")
		}
		if path == nil {
			return Utils.showError("You must select project path!")
		}

		pcName = name
		
		UserDefaults.standard.set(name, forKey: nameKey)
		UserDefaults.standard.set(path, forKey: pathKey)
		UserDefaults.standard.set(clonePath, forKey: clonePathKey)
		
		if let vc = NSStoryboard(name: "Main", bundle: .main).instantiateController(withIdentifier: "ViewController") as? ViewController {
			vc.computerName = pcName ?? ""
			vc.workPath = path ?? ""
			vc.clonePath = clonePath ?? ""
			self.view.window?.contentViewController = vc
		}
	}
}
