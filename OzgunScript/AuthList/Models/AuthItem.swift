//
//  AuthItem.swift
//  OzgunScript
//
//  Created by DucDT on 26/01/2023.
//

import Cocoa

enum RunningStatus { case running, stopped }

extension RunningStatus {
	var title: String {
		switch (self) {
		case .running: return "Working"
		case .stopped: return "Close"
		}
	}
	
	var color: NSColor {
		switch (self) {
		case .running: return .systemGreen
		case .stopped: return .systemRed
		}
	}
}

struct AuthItem {
	var name: String
	var hasAuth: Bool = true
	var status: RunningStatus = .stopped
	var restartCount: Int = 0
}
