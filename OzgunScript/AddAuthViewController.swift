//
//  AddAuthViewController.swift
//  OzgunScript
//
//  Created by DucDT on 26/01/2023.
//

import Cocoa

class AddAuthViewController: NSViewController {
	
	@IBOutlet var nameView: NSTextField!
	@IBOutlet var addButton: NSButton!
	
	
	var onAddedAuth: ((String) -> Void)?
	
	deinit {
		print("Deinit ===> \(self.description)")
	}

    override func viewDidLoad() {
        super.viewDidLoad()
        
		title = "Add Auth"
		
//		(addButton.cell as? NSButtonCell)?.backgroundColor = .green
//		addButton.layer?.backgroundColor = NSColor.green.cgColor
    }
    
	@IBAction func addClicked(_ button: NSButton) {
		let name = nameView.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
		if name.isEmpty {
			return Utils.showError("You must enter auth name!")
		}
		
		self.onAddedAuth?(name)
		self.view.window?.close()
	}
}
