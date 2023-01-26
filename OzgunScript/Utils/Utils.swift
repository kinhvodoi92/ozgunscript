//
//  Utils.swift
//  OzgunScript
//
//  Created by DucDT on 26/01/2023.
//

import Cocoa

class Utils {
	static func showAlert(_ message: String) {
		let alert = NSAlert()
		
		alert.messageText = message
		
		alert.addButton(withTitle: "OK")
		
		alert.alertStyle = .informational
		
		alert.runModal()
	}
	
	static func showWarning(_ message: String) {
		let alert = NSAlert()
		
		alert.messageText = message
		
		alert.addButton(withTitle: "OK")
		
		alert.alertStyle = .warning
		
		alert.runModal()
	}
	
	static func showError(_ error: String) {
		let alert = NSAlert()
		
		alert.messageText = error
		
		alert.addButton(withTitle: "OK")
		
		alert.alertStyle = .critical
		
		alert.runModal()
	}
}
