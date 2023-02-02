//
//  AuthViewRow.swift
//  OzgunScript
//
//  Created by DucDT on 26/01/2023.
//

import Cocoa

class AuthViewRow: NSStackView {
	var onOpenFolder: ((AuthItem) -> Void)?
	var onDelete: ((AuthItem) -> Void)?
	var onStop: ((AuthItem) -> Void)?
	var onStart: ((AuthItem) -> Void)?
	var auth: AuthItem? {
		didSet {
			guard let auth = auth else { return }
			nameView.title = auth.name
			authView.stringValue = auth.hasAuth ? "" : "no auth"
			statusView.title = auth.status.title
			statusView.contentTintColor = auth.status.color
			restartView.stringValue = auth.restartCount > 0 ? "\(auth.restartCount)" : ""
		}
	}
	
	private let nameView: NSButton = {
		let view = NSButton()
		view.title = "Name"
		view.isBordered = false
		view.alignment = .left
		view.contentTintColor = NSColor.white
		return view
	}()
	
	private let authView: NSTextField = {
		let view = NSTextField()
		view.stringValue = ""
		view.isEditable = false
		view.isBordered = false
		view.backgroundColor = .clear
		view.textColor = .systemRed
		return view
	}()
	
	private let statusView: NSButton = {
		let view = NSButton()
		view.title = "Working"
		view.isBordered = false
		return view
	}()
	
	private let restartView: NSTextField = {
		let view = NSTextField()
		view.stringValue = ""
		view.isEditable = false
		view.isBordered = false
		view.backgroundColor = .clear
		view.textColor = .systemBlue
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
		self.addArrangedSubview(authView)
		self.addArrangedSubview(statusView)
		self.addArrangedSubview(restartView)
		self.addArrangedSubview(deleteView)
		
		self.addConstraint(nameView.widthAnchor.constraint(greaterThanOrEqualTo: self.widthAnchor, multiplier: 0.3))
		self.addConstraint(authView.widthAnchor.constraint(equalToConstant: 100))
		self.addConstraint(statusView.widthAnchor.constraint(equalToConstant: 100))
		self.addConstraint(restartView.widthAnchor.constraint(equalToConstant: 30))
		self.addConstraint(deleteView.widthAnchor.constraint(equalToConstant: 100))
		
		nameView.target = self
		nameView.action = #selector(openFolder)
		
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
	
	@objc func openFolder() {
		guard let auth = self.auth else { return }
		onOpenFolder?(auth)
	}
	
	@objc func toggleStatus() {
		guard let auth = self.auth else { return }
		auth.status == .running ? onStop?(auth) : onStart?(auth)
	}
	
	@objc func deleteItem() {
		guard let auth = self.auth else { return }
		onDelete?(auth)
	}
}
