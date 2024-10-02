//
//  ContentView.swift
//  FinderSyncer
//
//  Created by 李旭 on 2024/9/20.
//

import SwiftUI

struct ContentView: View {
    @AppLog(subsystem: "ContentView")
    private var logger

    @State private var extensionsList: [ExtensionInfo] = []

    @State private var vibrateOnRing = false

    var body: some View {
        Section {
            List(extensionsList) { ext in

                HStack {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: ext.path))
                        .resizable()
                        .frame(width: 28, height: 28)
                    Text(ext.parentName)
                    Text(ext.bundle)
                    Text(ext.version)

                    Spacer()
                    Image(systemName: ext.status == "+" ? "checkmark.square" : "square")
                        .font(.system(size: 24)) // Set the size of the SF Symbol
                        .foregroundColor(.blue)
                }
                .padding([.vertical], 6)
                .onTapGesture {
                    toggleExt(ext)
                }
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push() // Change to hand cursor
                    } else {
                        NSCursor.pop() // Revert to the default cursor
                    }
                }
            }
            .cornerRadius(4)
        }
        header: {
            HStack {
                Spacer()
                Button {
                    fetchExtensions()
                } label: {
                    Label("Refresh", systemImage: "arrow.triangle.2.circlepath")
                        .font(.title2)
                        .padding(8)
                }
            }
        }
        .padding()
        .onAppear {
            fetchExtensions()
        }
    }

    // 根据 status 返回相应的背景颜色
    func backgroundColor(for status: String) -> Color {
        if status == "+" {
            return Color.red
        } else {
            return Color.primary
        }
    }

    func toggleExt(_ ext: ExtensionInfo) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        if ext.status == "+" {
            process.arguments = ["-e", "ignore", "-i", ext.bundle]
        } else {
            process.arguments = ["-e", "use", "-i", ext.bundle]
        }

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Error running pluginkit: \(error)")
        }

        pipe.fileHandleForReading.readDataToEndOfFile()

        fetchExtensions()
    }

    func fetchExtensions() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let output = runPluginkitCommand() {
//                print("output:\(output)")
                self.extensionsList = self.parseExtensions(text: output)
            } else {
                DispatchQueue.main.async {
                    extensionsList = []
                }
            }
        }
    }

    func parseExtensions(text: String) -> [ExtensionInfo] {
        var extensionsDict: [String: ExtensionInfo] = [:]

        var extensions: [ExtensionInfo] = []

        // 使用正则表达式匹配扩展块
        let pattern = #"([!+-])\s+([a-zA-Z0-9\.]+)\(([0-9\.\-]+)\)\s+Path\s*=\s*(.+)\s+UUID\s*=\s*([A-Z0-9\-]+)\s+Timestamp\s*=\s*([0-9\-\s:]+)\+\d+\s+SDK\s*=\s*([a-zA-Z0-9\.]+)\s+Parent Bundle\s*=\s*(.+)\s+Display Name\s*=\s*(.+)\s+Short Name\s*=\s*(.+)\s+Parent Name\s*=\s*(.+)\s+Platform\s*=\s*(.+)"#

        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let nsrange = NSRange(text.startIndex ..< text.endIndex, in: text)

        regex.enumerateMatches(in: text, options: [], range: nsrange) { match, _, _ in
            if let match = match {
                if let statusRange = Range(match.range(at: 1), in: text),
                   let bundleRange = Range(match.range(at: 2), in: text),
                   let versionRange = Range(match.range(at: 3), in: text),
                   let pathRange = Range(match.range(at: 4), in: text),
                   let uuidRange = Range(match.range(at: 5), in: text),
                   let timestampRange = Range(match.range(at: 6), in: text),
                   let sdkRange = Range(match.range(at: 7), in: text),
                   let parentBundleRange = Range(match.range(at: 8), in: text),
                   let displayNameRange = Range(match.range(at: 9), in: text),
                   let shortNameRange = Range(match.range(at: 10), in: text),
                   let parentNameRange = Range(match.range(at: 11), in: text),
                   let platformRange = Range(match.range(at: 12), in: text)
                {
                    let extensionInfo = ExtensionInfo(
                        status: String(text[statusRange]),
                        bundle: String(text[bundleRange]),
                        version: String(text[versionRange]),
                        path: String(text[pathRange]),
                        uuid: String(text[uuidRange]),
                        timestamp: String(text[timestampRange]),
                        sdk: String(text[sdkRange]),
                        parentBundle: String(text[parentBundleRange]),
                        displayName: String(text[displayNameRange]),
                        shortName: String(text[shortNameRange]),
                        parentName: String(text[parentNameRange]),
                        platform: String(text[platformRange])
                    )

                    // Compare the version if a bundle already exists in the dictionary
                    if let existingExt = extensionsDict[extensionInfo.bundle] {
                        if compareVersions(existingExt.version, extensionInfo.version) == .orderedAscending {
                            // Replace the existing extension if the new one has a higher version
                            extensionsDict[extensionInfo.bundle] = extensionInfo
                        }
                    } else {
                        // Add the new extension to the dictionary
                        extensionsDict[extensionInfo.bundle] = extensionInfo
                    }
                }
            }
        }

        extensions = Array(extensionsDict.values).sorted { $0.bundle < $1.bundle }

//        logger.info("\(extensions)")

        return extensions
    }

    // Helper function to compare two version strings
    func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult {
        let versionComponents1 = version1.split(separator: ".").map { Int($0) ?? 0 }
        let versionComponents2 = version2.split(separator: ".").map { Int($0) ?? 0 }

        for (v1, v2) in zip(versionComponents1, versionComponents2) {
            if v1 < v2 {
                return .orderedAscending
            } else if v1 > v2 {
                return .orderedDescending
            }
        }

        return versionComponents1.count < versionComponents2.count ? .orderedAscending : .orderedSame
    }

    func runPluginkitCommand() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        process.arguments = ["-mAD", "-p", "com.apple.FinderSync", "-vvv"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Error running pluginkit: \(error)")
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}

// 定义扩展的结构体
struct ExtensionInfo: Identifiable {
    var status: String // +, -, !
    let bundle: String
    let version: String
    let path: String
    let uuid: String
    let timestamp: String
    let sdk: String
    let parentBundle: String
    let displayName: String
    let shortName: String
    let parentName: String
    let platform: String
    var id: String {
        return uuid
    }
}

#Preview {
    ContentView()
}
