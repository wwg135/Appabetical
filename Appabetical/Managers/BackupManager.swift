//
//  BackupUtils.swift
//  Appabetical
//
//  Created by Rory Madden on 14/12/22.
//

import Foundation

class BackupManager {
    /// Save a homescreen backup manually
    static func saveLayout() {
        func copyAndAlert() {
            do {
                try? fm.removeItem(at: savedLayoutUrl)
                try fm.copyItem(at: plistUrl, to: savedLayoutUrl)
                // Set modification date to now
                let attributes: [FileAttributeKey : Any] = [.modificationDate: Date()]
                try fm.setAttributes(attributes, ofItemAtPath: savedLayoutUrl.path)
                UIApplication.shared.alert(title: "布局已保存", body: "布局已成功保存。")
            } catch {
                UIApplication.shared.alert(body: error.localizedDescription)
            }
        }
        
        if fm.fileExists(atPath: savedLayoutUrl.path) {
            UIApplication.shared.confirmAlert(title: "确认保存", body: "这将覆盖您先前保存的布局。您是否要继续？", onOK: {
                copyAndAlert()
            }, noCancel: false)
        } else {
            copyAndAlert()
        }
    }
    
    /// Restore the manual homescreen backup
    static func restoreLayout() throws {
        let _ = try fm.replaceItemAt(plistUrl, withItemAt: savedLayoutUrl)
        try fm.copyItem(at: plistUrl, to: savedLayoutUrl)
        if fm.fileExists(atPath: plistUrlBkp.path) {
            try fm.removeItem(at: plistUrlBkp)
        }
    }
    
    /// Make a backup
    static func makeBackup() throws {
        try? fm.removeItem(at: plistUrlBkp)
        try fm.copyItem(at: plistUrl, to: plistUrlBkp)
        // Set modification date to now
        let attributes: [FileAttributeKey : Any] = [.modificationDate: Date()]
        try fm.setAttributes(attributes, ofItemAtPath: plistUrlBkp.path)
    }
    
    /// Restore the latest backup
    static func restoreBackup() throws {
        do {
            let _ = try fm.replaceItemAt(plistUrl, withItemAt: plistUrlBkp)
        } catch {
            UIApplication.shared.alert(body: error.localizedDescription)
            return
        }
    }
    
    /// Get the time saved of a file in yyyy-MM-dd HH:mm
    static func getTimeSaved(url: URL) -> String? {
        if fm.fileExists(atPath: url.path) {
            do {
                let attributes = try fm.attributesOfItem(atPath: url.path)
                if let modificationDate = attributes[FileAttributeKey.modificationDate] as? Date {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                    let modificationDateString = dateFormatter.string(from: modificationDate)
                    return modificationDateString
                }
            } catch {
                return nil
            }
        }
        return nil
    }
}
