//
//  AppabeticalApp.swift
//  Appabetical
//
//  Created by Rory Madden on 5/12/22.
//

import SwiftUI
import Dynamic


typealias UsageReportCompletionBlock = @convention(block) (
    _ localUsageReports: NSArray?,
    _ usageReportsByDeviceIdentifier: NSDictionary?,
    _ aggregateUsageReports: NSArray?,
    _ error: NSError?) -> Void


@main
struct AppabeticalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
            .onAppear {
                checkNewVersions()
                if isiPad() {
                    UIApplication.shared.alert(title: "提示", body: "Appabetical还不支持iPad! 请不要使用该应用程序，可能会出现未知问题。")
                }
                checkAndEscape()
            }
//            .onAppear {
//                UsageTrackingWrapper.shared.getAppUsages(completion: { usages, error  in
//                    remLog("USAGES", usages)
//                })
//            }
        }
    }
    
    func isiPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    func checkAndEscape() {
#if targetEnvironment(simulator)
#else
        var supported = false
        var needsTrollStore = false
        if #available(iOS 16.7, *) {
            supported = false
        } else if #available(iOS 16.0, *) {
            supported = true
            needsTrollStore = true
        } else if #available(iOS 15.8.2, *) {
            supported = false
        } else if #available(iOS 15.0, *) {
            supported = true
            needsTrollStore = true
        } else if #available(iOS 14.0, *) {
            supported = true
            needsTrollStore = true
        }
        
        if !supported {
            UIApplication.shared.alert(title: "不支持", body: "不支持此版本的iOS，请关闭应用程序。")
            return
        }
            
        do {
            // Check if application is entitled
            try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "/var/mobile"), includingPropertiesForKeys: nil)
        } catch {
            if needsTrollStore {
                UIApplication.shared.alert(title: "使用 TrollStore", body: "您必须将此应用程序与TrollStore一起安装，以便与此版本的iOS一起工作，请关闭应用程序。")
                return
            }
            // Use MacDirtyCOW to gain r/w
            grant_full_disk_access() { error in
                if (error != nil) {
                    UIApplication.shared.alert(body: "\(String(describing: error?.localizedDescription))\n请关闭应用程序并重试。")
                    return
                }
            }
        }
#endif
    }
    
    // Credit to SourceLocation
    // https://github.com/sourcelocation/AirTroller/blob/main/AirTroller/AirTrollerApp.swift
    func checkNewVersions() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let url = URL(string: "https://api.github.com/repos/wwg135/Appabetical/releases/latest") {
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else { return }
                
                if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    if (json["tag_name"] as? String)?.compare(version, options: .numeric) == .orderedDescending {
                        UIApplication.shared.confirmAlert(title: "有更新可用", body: "Appabetical的新版本已经发布，建议您更新以避免遇到错误，您想查看发布页面吗?", onOK: {
                            UIApplication.shared.open(URL(string: "https://github.com/wwg135/Appabetical/releases/latest")!)
                        }, noCancel: false)
                    }
                }
            }
            task.resume()
        }
    }
}
