//
//  ViewController.swift
//  OzgunScript
//
//  Created by DucDT on 20/01/2023.
//

import Cocoa

class ViewController: NSViewController {
	@IBOutlet var headerView: NSStackView!
	@IBOutlet var nameView: NSTextField!
	@IBOutlet var countView: NSTextField!
	@IBOutlet var runButton: NSButton!
	@IBOutlet var clearButton: NSButton!
	@IBOutlet var outputView: NSScrollView!
	
	private var task = Process()
	private var pipe = Pipe()
	
	var computerName: String = ""
	var workPath: String = ""
	
	var textView: NSTextView {
		return outputView.contentView.documentView as! NSTextView
	}
	
	var output: String = ""
	
	deinit {
		try? pipe.fileHandleForReading.close()
		if task.isRunning {
			task.terminate()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		nameView.stringValue = computerName
		runButton.attributedTitle = NSAttributedString(string: "Run Script", attributes: [.foregroundColor: NSColor.green])
		clearButton.attributedTitle = NSAttributedString(string: "Delete Current Online Datas", attributes: [.foregroundColor: NSColor.red])
		
		if let files = try? FileManager.default.contentsOfDirectory(atPath: "\(workPath)/auth") {
			print(files.count)
			countView.stringValue = "Total Auth: \(files.count)"
		}
	}
	
	override var representedObject: Any? {
		didSet {
			// Update the view, if already loaded.
		}
	}
	
	private func runScript(_ file: String, arguments: [String] = []) {
		if task.isRunning {
			task.terminate()
		}
		
		self.task = Process()
		self.pipe = Pipe()
		
		self.task.standardOutput = self.pipe
		self.task.standardError = self.pipe
		self.task.arguments = arguments
		//		task.arguments = ["-c", "cd /Users/kinhroi/Desktop/EFI/OC & " + script]
		//		task.executableURL = URL(fileURLWithPath: "/bin/zsh")
		self.task.launchPath = Bundle.main.path(forResource: file, ofType: nil)
		self.task.launch()
		
		self.captureStandardOutputAndRouteToTextView(task: self.task)
	}
	
	func captureStandardOutputAndRouteToTextView(task: Process) {
		pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
		
		task.terminationHandler = { [weak self] _ in
			DispatchQueue.main.async {
				self?.runButton.attributedTitle = NSAttributedString(string: "Run Script", attributes: [.foregroundColor: NSColor.green])
				self?.clearButton.isHidden = false
			}
		}
		
		NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: pipe.fileHandleForReading , queue: nil) {
			[weak self] notification in
			self?.updateOutput()
		}
		
	}
	
	private func updateOutput() {
		let output = self.pipe.fileHandleForReading.availableData
		let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
		
		self.insertOutput(outputString)
		
		self.pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
	}
	
	private func insertOutput(_ string: String) {
		if string.isEmpty { return }
		
		DispatchQueue.main.async(execute: {
			let previousOutput = self.textView.string
			let nextOutput = previousOutput + "\n" + string
			self.textView.string = nextOutput
			
			let range = NSRange(location:nextOutput.count,length:0)
			self.textView.scrollRangeToVisible(range)
		})
	}
	
	
	@IBAction func runScriptClicked(_ button: NSButton) {
		if task.isRunning {
			insertOutput("STOPPED")
			stopScriptRequest()
			task.terminate()
			
			runButton.attributedTitle = NSAttributedString(string: "Run Script", attributes: [.foregroundColor: NSColor.green])
			clearButton.isHidden = false
		} else {
			runButton.attributedTitle = NSAttributedString(string: "Stop", attributes: [.foregroundColor: NSColor.red])
			clearButton.isHidden = true
			
			startScriptRequest()
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
				self.runScript("tsnode_script", arguments: [self.workPath])
			})
		}
	}
	
	@IBAction func clearDataClicked(_ button: NSButton) {
		if task.isRunning {
			task.terminate()
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
			self.runScript("cleardata_script", arguments: [self.computerName])
		})
	}
	
	private func startScriptRequest() {
		guard let url = URL(string: "http://logify-app.com/macControlPanel/started.php?pc=\(computerName)") else { return }
		let request = URLRequest(url: url)
		URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
			print(error?.localizedDescription ?? "")
		}).resume()
	}
	
	private func stopScriptRequest() {
		guard let url = URL(string: "http://logify-app.com/macControlPanel/stopped.php?pc=\(computerName)") else { return }
		let request = URLRequest(url: url)
		URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
			print(error?.localizedDescription ?? "")
		}).resume()
	}
}

