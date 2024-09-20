//
//  ContentView.swift
//  FinderSyncer
//
//  Created by 李旭 on 2024/9/20.
//

import SwiftUI


struct ContentView: View {
    @State private var extensionsList: [ExtensionInfo] = []

    var body: some View {
        VStack {
            List(extensionsList) { ext in

                HStack {
                    Text(ext.parentName)

                    Text(ext.version)

                    Text(ext.status)
                    Spacer()
                    Button(ext.status == "+" ? "关闭" : "开启") {
                        toggleExt(ext)
                    }
                }.padding([.vertical], 6)
            }
            .cornerRadius(4)
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

        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        print(String(data: data, encoding: .utf8) ?? "")

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

                    extensions.append(extensionInfo)
                }
            }
        }
        print("------ \(extensions.count)")
        return extensions
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
