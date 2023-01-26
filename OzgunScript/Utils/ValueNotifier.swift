//
//  ValueNotifier.swift
//  OzgunScript
//
//  Created by DucDT on 26/01/2023.
//

import Cocoa

class ValueNotifier<T> {
	var value: T? {
		didSet {
			notifyListeners()
		}
	}
	
	typealias ValueNotifierListener = ( (T?) -> Void)
	private var listeners: [ValueNotifierListener] = []
	
	init(value: T) {
		self.value = value
	}
	
	func notifyListeners() {
		listeners.forEach({ $0(self.value) })
	}
	
	func addListener(_ listener: @escaping ValueNotifierListener) {
		listeners.append(listener)
	}
}

extension ValueNotifier where T == [Any] {
	func append(_ item: Any) {
		self.value?.append(item)
		self.notifyListeners()
	}
}
