//
//  FinderSyncerApp.swift
//  FinderSyncer
//
//  Created by 李旭 on 2024/9/20.
//

import AppKit
import OSLog
import SwiftUI

@main
struct FinderSyncerApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }.defaultSize(CGSize(width: 600, height: 450))
    }
}

// AppDelegate 负责处理文件打开请求
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    @AppLog(category: "AppState")
    private var logger

    func applicationWillFinishLaunching(_ notification: Notification) {
        logger.info("---- app will finish launch")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("applicationDidFinishLaunching  .......")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 当最后一个窗口关闭时，终止应用
        return true
    }
}

@propertyWrapper
struct AppLog {
    private let logger: Logger

    init(subsystem: String = Bundle.main.bundleIdentifier ?? "", category: String = "main") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    var wrappedValue: Logger {
        return logger
    }
}
