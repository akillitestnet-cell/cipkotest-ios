import SwiftUI
import RevenueCat

@main
struct CipkoTestApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Purchases.configure(withAPIKey: "test_JCtkbdjsQjajehffxGNairKVvRf")
        return true
    }
}
