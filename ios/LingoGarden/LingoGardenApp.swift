import SwiftUI

@main struct LingoGardenApp: App {
    @StateObject private var store = LearningStore()
    var body: some Scene {
        WindowGroup {
            GardenRoot().environmentObject(store).tint(GardenStyle.green)
        }
    }
}
