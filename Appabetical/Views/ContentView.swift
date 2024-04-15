//
//  ContentView.swift
//  Appabetical
//
//  Created by Rory Madden on 5/12/22.
//

import SwiftUI
import MobileCoreServices

struct ContentView: View {
    
    // Settings variables
    @State private var selectedItems = [Int]()
    @State private var pageOp = IconStateManager.PageSortingOption.individually
    @State private var folderOp = IconStateManager.FolderSortingOption.noSort
    @State private var sortOp = IconStateManager.SortOption.alphabetically
    @State private var widgetOp = IconStateManager.WidgetOptions.top
    
    @Environment(\.openURL) var openURL
    
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: {
                        MultiSelectPickerView(pages: IconStateManager.getPages(), selectedItems: $selectedItems, pageOp: $pageOp).navigationBarTitle("", displayMode: .inline)
                    }, label: {
                        HStack {
                            Text("选择页面")
                            Spacer()
                            Text(selectedItems.isEmpty ? "None" : selectedItems.map { String($0 + 1) }.joined(separator: ", ")).foregroundColor(.secondary)
                        }
                    })
                    Picker("Ordering", selection: $sortOp) {
                        Text("A-Z").tag(IconStateManager.SortOption.alphabetically)
                        Text("Z-A").tag(IconStateManager.SortOption.alphabeticallyReversed)
                        Text("颜色").tag(IconStateManager.SortOption.color)
                    }.onChange(of: sortOp, perform: {nv in if nv == .color && folderOp == .alongside { folderOp = .separately }})
                    Picker("Pages", selection: $pageOp) {
                        Text("独立排序页面").tag(IconStateManager.PageSortingOption.individually)
                        Text("跨页面排序应用程序").tag(IconStateManager.PageSortingOption.acrossPages)
                    }
                    Picker("Folders", selection: $folderOp) {
                        Text("保留当前顺序").tag(IconStateManager.FolderSortingOption.noSort)
                        if (sortOp == .alphabetically || sortOp == .alphabeticallyReversed) {
                            Text("混合排序应用").tag(IconStateManager.FolderSortingOption.alongside)
                        }
                        Text("分开排序应用").tag(IconStateManager.FolderSortingOption.separately)
                    }
                    Picker("Widgets", selection: $widgetOp) {
                        Text("移到顶部").tag(IconStateManager.WidgetOptions.top)
                    }
                    Button("应用排序") {
                        sortPage()
                    }.disabled(selectedItems.isEmpty)
                }
                Section(footer: Text((fm.fileExists(atPath: savedLayoutUrl.path) ?  "之前保存的布局将被覆盖。" : "建议您在进行实验之前保存当前的布局，因为只能撤销一次操作。" ) + "\n\nVersion \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "pirate version bozo®")")) {
                    Button("撤销上次排序") {
                        restoreBackup()
                    }.disabled(!fm.fileExists(atPath: plistUrlBkp.path))
                    Button("恢复保存布局") {
                        restoreLayout()
                    }.disabled(!fm.fileExists(atPath: savedLayoutUrl.path))
                    Button("备份当前布局") {
                        saveLayout()
                    }
                }
            }
            .navigationTitle("Appabetical")
            .toolbar {
                // Credit to SourceLocation
                // https://github.com/sourcelocation/AirTroller/blob/main/AirTroller/ContentView.swift
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        openURL(URL(string: "https://discord.gg/VyVcNjRMeg")!)
                    }) {
                        Image("discord")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                    Menu {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            openURL(URL(string: "https://github.com/Avangelista/Appabetical")!)
                        } label: {
                            Label("源代码", systemImage: "shippingbox")
                        }
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            openURL(URL(string: "https://github.com/Avangelista")!)
                        } label: {
                            Label("Avangelista", systemImage: "person")
                        }
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            openURL(URL(string: "https://github.com/wwg135")!)
                        } label: {
                            Label("wwg135", systemImage: "person")
                        }
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            openURL(URL(string: "https://github.com/sourcelocation")!)
                        } label: {
                            Label("sourcelocation", systemImage: "person")
                        }
                    } label: {
                        Image("github")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    }
                    Menu {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            openURL(URL(string: "https://ko-fi.com/avangelista")!)
                        } label: {
                            Label("Avangelista", systemImage: "1.circle")
                        }
                        
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            openURL(URL(string: "https://ko-fi.com/sourcelocation")!)
                        } label: {
                            Label("sourcelocation", systemImage: "2.circle")
                        }
                    } label: {
                        Image(systemName: "heart.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .onAppear {
                
            }
        }
    }
    
    
    // Sort the selected pages
    func sortPage() {
        do {
            let pageCount = try IconStateManager.shared.pageCount()
            selectedItems = selectedItems.filter {$0 - 1 < pageCount }
            if selectedItems.isEmpty { return }
            
            try IconStateManager.shared.sortPages(selectedPages: selectedItems, sortOption: sortOp, pageSortingOption: pageOp, folderSortingOption: folderOp)
        } catch {  UIApplication.shared.alert(body: error.localizedDescription) }
    }
    
    func saveLayout() {
        BackupManager.saveLayout()
    }
    
    func restoreBackup() {
        UIApplication.shared.confirmAlert(title: "确认撤销", body: "布局保存在 \(BackupManager.getTimeSaved(url: plistUrlBkp) ?? "(unknown date)"). 当然，请注意如果您在那之后添加或删除了任何应用程序、小部件或文件夹，它们可能会显示不正确。您是否希望继续？", onOK: {
            do {
                try BackupManager.restoreBackup()
                respringFrontboard()
            } catch {  UIApplication.shared.alert(body: error.localizedDescription) }
        })
    }
    
    func restoreLayout() {
        UIApplication.shared.confirmAlert(title: "确认恢复", body: "布局 \(BackupManager.getTimeSaved(url: savedLayoutUrl) ?? "(unknown date)"). 当然，请注意如果您在那之后添加或删除了任何应用程序、小部件或文件夹，它们可能会显示不正确。您是否希望继续？", onOK: {
            do {
                try BackupManager.restoreLayout()
                respringFrontboard()
            } catch {  UIApplication.shared.alert(body: error.localizedDescription) }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
