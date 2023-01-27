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
	@IBOutlet var authListView: NSStackView!
	//	@IBOutlet var outputView: NSScrollView!
	
	private var task = Process()
	private var pipe = Pipe()
	
	var computerName: String = ""
	var workPath: String = ""
	var clonePath: String?
	private var parentPath: String = ""
	private var folderName: String = ""
	
	var auths = ValueNotifier(value: [String]())
	var tasks = [String: Process]()
	
	//	var textView: NSTextView {
	//		return outputView.contentView.documentView as! NSTextView
	//	}
	
	var encodedName: String {
		return computerName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? computerName
	}
	var isRunningScript: Bool {
		return tasks.values.contains(where: { $0.isRunning })
	}
	
	var output: String = ""
	
	deinit {
		try? pipe.fileHandleForReading.close()
		terminate()
		print("Deinit ===> \(self.description)")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		title = "OzgunScript"
		
		nameView.stringValue = computerName
		runButton.attributedTitle = NSAttributedString(string: "Run Script", attributes: [.foregroundColor: NSColor.green])
		clearButton.attributedTitle = NSAttributedString(string: "Delete Current Online Datas", attributes: [.foregroundColor: NSColor.red])
		
		setup()
		setAuthCount()
		listenAuths()
	}
	
	override var representedObject: Any? {
		didSet {
			// Update the view, if already loaded.
		}
	}
	
	private func setup() {
		guard let workingPath = URL(string: workPath) else {
			return
		}
		
		folderName = workingPath.lastPathComponent
		parentPath = workingPath.deletingLastPathComponent().absoluteString
		guard let list = try? FileManager.default.contentsOfDirectory(atPath: parentPath) else {
			return
		}
		let prefix = "\(folderName)_"
		let auths = list.filter({ $0.hasPrefix(prefix) }).map({ $0.replacingOccurrences(of: prefix, with: "")})
		
		self.auths.value = auths
		auths.forEach { [weak self] name in
			self?.addAuthToView(AuthItem(name: name, status: .stopped))
		}
	}
	
	private func runScript(authName: String) {
		DispatchQueue(label: authName).async {
			let task = Process()
			self.pipe = Pipe()
			
			self.task.standardOutput = self.pipe
			self.task.standardError = self.pipe
			//			task.arguments =  ["-c", script]
			//			task.executableURL = URL(fileURLWithPath: "/bin/zsh")
			task.arguments = ["\(self.workPath)_\(authName)"]
			task.launchPath = Bundle.main.path(forResource: "tsnode_script", ofType: nil)
			try? task.run()
			
			DispatchQueue.main.async {
				self.tasks.updateValue(task, forKey: authName)
				if let index = self.auths.value?.firstIndex(of: authName), let authView = self.authListView.arrangedSubviews[index] as? AuthViewRow {
					authView.auth = AuthItem(name: authName, status: .running)
				}
			}
			
			self.updateRunningStatus()
			task.terminationHandler = { [weak self] _ in
				DispatchQueue.main.async {
					self?.tasks.removeValue(forKey: authName)
				}
				self?.updateRunningStatus()
			}
		}
	}
	
	private func runTerminateScript() {
		let task = Process()
		task.launchPath = Bundle.main.path(forResource: "terminate_script", ofType: nil)
		task.launch()
	}
	
	//	func captureStandardOutputAndRouteToTextView(task: Process) {
	//		pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
	//
	//		task.terminationHandler = { [weak self] _ in
	//			DispatchQueue.main.async {
	//				self?.runButton.attributedTitle = NSAttributedString(string: "Run Script", attributes: [.foregroundColor: NSColor.green])
	//				self?.clearButton.isHidden = false
	//			}
	//		}
	//
	//		NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: pipe.fileHandleForReading , queue: nil) {
	//			[weak self] notification in
	//			self?.updateOutput()
	//		}
	//	}
	//
	//	private func updateOutput() {
	//		let output = self.pipe.fileHandleForReading.availableData
	//		let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
	//
	//		self.insertOutput(outputString)
	//
	//		self.pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
	//	}
	//
	//	private func insertOutput(_ string: String) {
	//		if string.isEmpty { return }
	//
	//		DispatchQueue.main.async(execute: {
	//			let previousOutput = self.textView.string
	//			let nextOutput = previousOutput + "\n" + string
	//			self.textView.string = nextOutput
	//
	//			let range = NSRange(location:nextOutput.count,length:0)
	//			self.textView.scrollRangeToVisible(range)
	//		})
	//	}
	
	private func updateRunningStatus() {
		DispatchQueue.main.async {
			let isRunning = self.isRunningScript
			self.runButton.attributedTitle = NSAttributedString(string: isRunning ? "Stop" : "Run Script", attributes: [.foregroundColor: isRunning ? NSColor.red : NSColor.green])
			self.clearButton.isHidden = isRunning
			
			self.authListView.arrangedSubviews.forEach { view in
				if let view = view as? AuthViewRow, var auth = view.auth {
					auth.status = self.tasks[auth.name]?.isRunning == true ? .running : .stopped
					view.auth = auth
				}
			}
		}
	}
	
	
	@IBAction func runScriptClicked(_ button: NSButton) {
		if isRunningScript {
			//			insertOutput("STOPPED")
			stopScriptRequest()
			terminate()
			
			runButton.attributedTitle = NSAttributedString(string: "Run Script", attributes: [.foregroundColor: NSColor.green])
			clearButton.isHidden = false
		} else {
			runButton.attributedTitle = NSAttributedString(string: "Stop", attributes: [.foregroundColor: NSColor.red])
			clearButton.isHidden = true
			
			startScriptRequest()
			self.auths.value?.forEach({ name in
				self.runScript(authName: name)
			})
		}
		
	}
	
	@IBAction func clearDataClicked(_ button: NSButton) {
		guard let url = URL(string: "http://logify-app.com/macControlPanel/deleted-online.php?pc=\(encodedName)") else { return }
		let request = URLRequest(url: url)
		URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
			DispatchQueue.main.async {
				if error == nil {
					Utils.showAlert("Delete online data successful!")
				} else {
					Utils.showError("Delete online data failed!")
				}
			}
		}).resume()
		
		//		terminate()
		//		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
		//			self.runScript("cleardata_script", arguments: [self.computerName])
		//		})
	}
	
	@IBAction func renewClonesClicked(_ button: NSButton) {
		guard let auths = auths.value else { return }
		for name in auths {
			let task = Process()
			task.arguments = [workPath, "\(workPath)_\(name)"]
			task.launchPath = Bundle.main.path(forResource: "copy_script", ofType: nil)
			task.launch()
		}
		
		Utils.showAlert("Copied .ts files to clones!")
	}
	
	@IBAction func addAuthClicked(_ button: NSButton) {
		let vc = AddAuthViewController(nibName: AddAuthViewController.className(), bundle: Bundle.main)
		//			vc.computerName = pcName ?? ""
		//			vc.workPath = path ?? ""
		//			vc.clonePath = clonePath ?? ""
		//			self.view.window?.contentViewController = vc
		self.presentAsModalWindow(vc)
		vc.onAddedAuth = { [weak self] authName in
			self?.addAuth(authName)
		}
	}
	
	private func startScriptRequest() {
		guard let url = URL(string: "http://logify-app.com/macControlPanel/started.php?pc=\(encodedName)") else { return }
		let request = URLRequest(url: url)
		URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
			//			print(error)
		}).resume()
	}
	
	private func stopScriptRequest() {
		guard let url = URL(string: "http://logify-app.com/macControlPanel/stopped.php?pc=\(encodedName)") else { return }
		let request = URLRequest(url: url)
		URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
			//			print(error)
		}).resume()
	}
	
	private func terminate() {
		self.tasks.values.forEach { task in
			if task.isRunning { task.terminate() }
		}
		self.runTerminateScript()
		
		self.tasks.removeAll()
		
		self.authListView.arrangedSubviews.forEach { view in
			if let view = view as? AuthViewRow {
				var auth = view.auth
				auth?.status = .stopped
				view.auth = auth
			}
		}
	}
}

extension ViewController {
	private func setAuthCount() {
		guard let auths = self.auths.value, !auths.isEmpty else {
			countView.stringValue = "Total Auth: \(totalAuthCount([workPath]))"
			return
		}
		
		let totalAuth = totalAuthCount(auths.map({ "\(workPath)_\($0)"}))
		countView.stringValue = "Total Auth: \(totalAuth)"
	}
	
	private func totalAuthCount(_ paths: [String]) -> Int {
		var total: Int = 0
		paths.forEach { path in
			if let files = try? FileManager.default.contentsOfDirectory(atPath: "\(path)/auth") {
				total += files.count - 1	// -1 of auth folder count
			}
		}
		return total
	}
	
	private func addAuth(_ name: String) {
		guard var auths = self.auths.value, !auths.contains(name) else {
			Utils.showWarning("Cannot add existed Auth!")
			return
		}
		
		do {
			try FileManager.default.copyItem(atPath: workPath, toPath: "\(workPath)_\(name)")
			print("Added auth: \(name)")
			self.addAuthToView(AuthItem(name: name, status: self.isRunningScript ? .running : .stopped))
			auths.append(name)
			self.auths.value = auths
		} catch (let err) {
			Utils.showError(err.localizedDescription)
		}
	}
	
	private func addAuthToView(_ item: AuthItem) {
		let authView = AuthViewRow()
		authView.auth = item
		authView.onDelete = { [weak self] item in
			self?.deleteAuth(item.name)
		}
		authView.onStop = { [weak self] item in
			if let task = self?.tasks[item.name], task.isRunning {
				task.terminate()
				self?.tasks.removeValue(forKey: item.name)
			}
			self?.updateRunningStatus()
		}
		authView.onStart = { [weak self] item in
			self?.runScript(authName: item.name)
		}
		self.authListView.addArrangedSubview(authView)
		
		if item.status == .running {
			runScript(authName: item.name)
		}
	}
	
	private func listenAuths() {
		auths.addListener { [weak self] auths in
			guard let auths = auths else { return }
			print(auths)
			self?.setAuthCount()
		}
	}
}

extension ViewController {
	private func deleteAuth(_ name: String) {
		if let task = tasks[name], task.isRunning { task.terminate() }
		do {
			try FileManager.default.removeItem(atPath: "\(workPath)_\(name)")
			self.tasks.removeValue(forKey: name)
			
			guard var auths = self.auths.value else { return }
			if let index = auths.firstIndex(of: name) {
				auths.remove(at: index)
				self.auths.value = auths
				if index < authListView.arrangedSubviews.count {
					authListView.arrangedSubviews[index].removeFromSuperview()
				}
			}
			
		} catch (let err) {
			Utils.showError("Can't remove this clone folder\n\(err.localizedDescription)")
		}
	}
}
