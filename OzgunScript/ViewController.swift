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
	@IBOutlet var runningCountView: NSTextField!
	@IBOutlet var countView: NSTextField!
	@IBOutlet var timeDelayView: NSTextField!
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
	
	private var auths = ValueNotifier(value: [String]())
	private var tasks = [String: Process]()
	private var timer: Timer?
	private lazy var timeDelay = UserDefaults.standard.integer(forKey: delayTimeKey)
	
	private let delayTimeKey = "DelayTimeKey"
	
	//	var textView: NSTextView {
	//		return outputView.contentView.documentView as! NSTextView
	//	}
	
	var encodedName: String {
		return computerName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? computerName
	}
	var isRunningScript: Bool {
		return tasks.values.contains(where: { $0.isRunning }) || timer?.isValid == true
	}
	
	var output: String = ""
	
	deinit {
		try? pipe.fileHandleForReading.close()
		terminate()
		print("Deinit ===> \(self.description)")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		title = "Script"
		
		nameView.stringValue = computerName
		runButton.attributedTitle = NSAttributedString(string: "Run Script", attributes: [.foregroundColor: NSColor.systemGreen])
		clearButton.attributedTitle = NSAttributedString(string: "Delete Current Online Datas", attributes: [.foregroundColor: NSColor.systemRed])
		
		listenAuths()
		setup()
		removeDSstoreFiles()
	}
	
	override var representedObject: Any? {
		didSet {
			// Update the view, if already loaded.
		}
	}
	
	private func path(with name: String) -> String {
		return "\(workPath)_\(name)"
	}
	
	private func setup() {
		guard let workingPath = URL(string: workPath) else {
			return
		}
		
		folderName = workingPath.lastPathComponent
		parentPath = workingPath.deletingLastPathComponent().absoluteString
		
		updateAuthList()
		
		if timeDelay == 0 {
			timeDelay = 5
			UserDefaults.standard.set(timeDelay, forKey: delayTimeKey)
		}
		timeDelayView.stringValue = "\(timeDelay)"
	}
	
	private func runScript(authName: String) {
		DispatchQueue(label: authName).async {
			let task = Process()
			//			self.pipe = Pipe()
			
			//			self.task.standardOutput = self.pipe
			//			self.task.standardError = self.pipe
			//			task.arguments =  ["-c", script]
			//			task.executableURL = URL(fileURLWithPath: "/bin/zsh")
			task.arguments = ["\(self.workPath)_\(authName)"]
			task.launchPath = Bundle.main.path(forResource: "tsnode_script", ofType: nil)
			task.launch()
			
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
	//				self?.runButton.attributedTitle = NSAttributedString(string: "Run Script", attributes: [.foregroundColor: NSColor.systemGreen])
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
			self.runButton.attributedTitle = NSAttributedString(string: isRunning ? "Stop" : "Run Script", attributes: [.foregroundColor: isRunning ? NSColor.systemRed : NSColor.systemGreen])
			self.clearButton.isHidden = isRunning
			
			self.authListView.arrangedSubviews.forEach { view in
				if let view = view as? AuthViewRow, var auth = view.auth {
					auth.status = self.tasks[auth.name]?.isRunning == true ? .running : .stopped
					view.auth = auth
				}
			}
			
			self.updateRunningCount()
		}
	}
	
	private func updateRunningCount() {
		self.runningCountView.stringValue = "Running: \(self.tasks.filter({ $0.value.isRunning }).count) / \(self.auths.value?.count ?? 0)"
	}
	
	private func updateAuthList() {
		guard let list = try? FileManager.default.contentsOfDirectory(atPath: parentPath) else {
			return
		}
		let prefix = "\(folderName)_"
		let auths = list.filter({ $0.hasPrefix(prefix) }).map({ $0.replacingOccurrences(of: prefix, with: "")})
		
		self.auths.value = auths
		
		self.authListView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
		auths.forEach { [weak self] name in
			self?.addAuthToView(AuthItem(name: name, status: .stopped))
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
		
		self.timer?.invalidate()
		self.timer = nil
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
	@IBAction private func refreshClicked(_ button: NSButton) {
		guard !isRunningScript else {
			Utils.showWarning("You must stop all scripts before refreshing list!")
			return
		}
		updateAuthList()
	}
	
	@IBAction func runScriptClicked(_ button: NSButton) {
		if isRunningScript {
			//			insertOutput("STOPPED")
			stopScriptRequest()
			terminate()
			
			runButton.attributedTitle = NSAttributedString(string: "Run Script", attributes: [.foregroundColor: NSColor.systemGreen])
			clearButton.isHidden = false
		} else {
			startScriptRequest()
			
			timeDelay = Int(timeDelayView.stringValue) ?? 5
			UserDefaults.standard.set(timeDelay, forKey: delayTimeKey)
			
			runButton.attributedTitle = NSAttributedString(string: "Stop", attributes: [.foregroundColor: NSColor.systemRed])
			clearButton.isHidden = true
			
			if let auths = self.auths.value {
				var index = 0
				timer?.invalidate()
				timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(self.timeDelay), repeats: true, block: { [weak self] _ in
					if index >= auths.count {
						self?.timer?.invalidate()
						self?.timer = nil
						return
					}
					self?.runScript(authName: auths[index])
					index += 1
				})
				timer?.fire()
			}
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
			task.arguments = [workPath, path(with: name)]
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
}

extension ViewController {
	private func setAuthCount() {
		guard let auths = self.auths.value, !auths.isEmpty else {
			countView.stringValue = "Total Auth: \(totalAuthCount([workPath]))"
			return
		}
		
		let totalAuth = totalAuthCount(auths.map({ path(with: $0) }))
		countView.stringValue = "Total Auth: \(totalAuth)"
	}
	
	private func totalAuthCount(_ paths: [String]) -> Int {
		var total: Int = 0
		paths.forEach { path in
			if let files = try? FileManager.default.contentsOfDirectory(atPath: "\(path)/auth") {
				total += files.count
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
			try FileManager.default.copyItem(atPath: workPath, toPath: path(with: name))
			auths.append(name)
			self.auths.value = auths
			self.addAuthToView(AuthItem(name: name, status: self.isRunningScript ? .running : .stopped))
			print("Added auth: \(name)")
		} catch (let err) {
			Utils.showError(err.localizedDescription)
		}
	}
	
	private func addAuthToView(_ item: AuthItem) {
		var auth = item
		auth.hasAuth = FileManager.default.fileExists(atPath: "\(path(with: item.name))/auth")
		
		let authView = AuthViewRow()
		authView.auth = auth
		authView.onOpenFolder = { [weak self] item in
			if let path = self?.path(with: item.name) {
				NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
			}
		}
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
			self?.updateRunningCount()
		}
	}
}

extension ViewController {
	private func deleteAuth(_ name: String) {
		if let task = tasks[name], task.isRunning { task.terminate() }
		do {
			try FileManager.default.removeItem(atPath: path(with: name))
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
	
	private func removeDSstoreFiles() {
		try? FileManager.default.removeItem(atPath: "\(workPath)/auth/.DS_Store")
		
		let folders = self.auths.value ?? []
		folders.forEach { name in
			let dspath = "\(path(with: name))/auth/.DS_Store"
			try? FileManager.default.removeItem(atPath: dspath)
		}
	}
}
