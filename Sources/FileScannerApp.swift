import SwiftUI

@main
struct FileScannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandMenu("Organize") {
                Button("Start Scan") {
                    // Trigger scan - would need to access app state
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Button("Create Plan") {
                    // Trigger plan creation
                }
                .keyboardShortcut("p", modifiers: .command)
                
                Divider()
                
                Button("Undo Last Action") {
                    // Trigger undo
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }
        }
    }
}
