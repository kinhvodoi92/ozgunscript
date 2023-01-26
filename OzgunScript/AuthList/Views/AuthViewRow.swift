//
//  AuthViewRow.swift
//  OzgunScript
//
//  Created by DucDT on 26/01/2023.
//

import Cocoa

class AuthViewRow: NSStackView {
	var onDelete: ((AuthItem) -> Void)?
	var onStop: ((AuthItem) -> Void)?
	var onStart: ((AuthItem) -> Void)?
	var auth: AuthItem? {
		didSet {
			guard let auth = auth else { return }
			nameView.stringValue = auth.name
			statusView.title = auth.status.title
			statusView.contentTintColor = auth.status.color
		}
	}
	
	private let nameView: NSTextField = {
		let view = NSTextField()
		view.isEditable = false
		view.stringValue = "Name"
		view.drawsBackground = false
		view.isBordered = false
		return view
	}()
	
	private let statusView: NSButton = {
		let view = NSButton()
		view.title = "Working"
		view.isBordered = false
		return view
	}()
	
	private let deleteView: NSButton = {
		let view = NSButton()
		view.title = "Delete"
		view.isBordered = false
		return view
	}()
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		
		self.addArrangedSubview(nameView)
		self.addArrangedSubview(statusView)
		self.addArrangedSubview(deleteView)
		
		self.addConstraint(nameView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.5))
		self.addConstraint(statusView.widthAnchor.constraint(equalToConstant: 100))
		self.addConstraint(deleteView.widthAnchor.constraint(equalToConstant: 100))
		
		statusView.target = self
		statusView.action = #selector(toggleStatus)
		
		deleteView.target = self
		deleteView.action = #selector(deleteItem)
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
	
	@objc func toggleStatus() {
		guard let auth = self.auth else { return }
		auth.status == .running ? onStop?(auth) : onStart?(auth)
	}
	
	@objc func deleteItem() {
		if let auth = self.auth {
			onDelete?(auth)
		}
	}
}
