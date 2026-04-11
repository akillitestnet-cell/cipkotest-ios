import SwiftUI
import RevenueCat

@main
struct CipkoTestApp: App {
    init() {
        Purchases.configure(withAPIKey: "test_JCtkbdjsQjajehffxGNairKVvRf")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
