import Foundation
import WebKit
import RevenueCat

class PurchaseManager: NSObject, WKScriptMessageHandler {
    weak var webView: WKWebView?

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "cipkoIAP",
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }

        switch action {
        case "setUserId":
            if let userId = body["userId"] as? String {
                Task { await self.loginUser(userId) }
            }
        case "purchase":
            if let productId = body["productId"] as? String {
                Task { await self.purchaseProduct(productId: productId) }
            }
        case "restorePurchases":
            Task { await self.restorePurchases() }
        case "getProducts":
            Task { await self.getProducts() }
        default:
            break
        }
    }

    private func loginUser(_ userId: String) async {
        do {
            let (_, _) = try await Purchases.shared.logIn(userId)
            sendToWeb(["action": "userLoggedIn", "userId": userId])
        } catch {
            sendToWeb(["action": "error", "message": error.localizedDescription])
        }
    }

    private func purchaseProduct(productId: String) async {
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let offering = offerings.current else {
                sendToWeb(["action": "purchaseError", "message": "Paket listesi yüklenemedi."])
                return
            }

            let targetPackage = offering.availablePackages.first {
                $0.identifier == productId ||
                $0.storeProduct.productIdentifier == productId
            }

            guard let pkg = targetPackage else {
                let available = offering.availablePackages.map { $0.identifier }.joined(separator: ", ")
                sendToWeb(["action": "purchaseError", "message": "Ürün bulunamadı (\(productId)). Mevcut: \(available)"])
                return
            }

            let (transaction, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: pkg)

            if userCancelled {
                sendToWeb(["action": "purchaseCancelled"])
                return
            }

            sendToWeb([
                "action": "purchaseSuccess",
                "productId": productId,
                "transactionId": transaction?.transactionIdentifier ?? "",
                "appUserId": customerInfo.originalAppUserId
            ])
        } catch let purchasesError as ErrorCode {
            sendToWeb(["action": "purchaseError", "message": purchasesError.localizedDescription])
        } catch {
            sendToWeb(["action": "purchaseError", "message": error.localizedDescription])
        }
    }

    private func restorePurchases() async {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            sendToWeb(["action": "restoreSuccess", "appUserId": customerInfo.originalAppUserId])
        } catch {
            sendToWeb(["action": "restoreError", "message": error.localizedDescription])
        }
    }

    private func getProducts() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let offering = offerings.current else {
                sendToWeb(["action": "productsError", "message": "Paket listesi boş"])
                return
            }
            var products: [[String: String]] = []
            for pkg in offering.availablePackages {
                products.append([
                    "identifier": pkg.identifier,
                    "productId": pkg.storeProduct.productIdentifier,
                    "localizedPrice": pkg.localizedPriceString,
                    "title": pkg.storeProduct.localizedTitle
                ])
            }
            if let data = try? JSONSerialization.data(withJSONObject: products),
               let jsonStr = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.webView?.evaluateJavaScript(
                        "window.cipkoIAPCallback && window.cipkoIAPCallback({action:'products', products:\(jsonStr)})"
                    )
                }
            }
        } catch {
            sendToWeb(["action": "productsError", "message": error.localizedDescription])
        }
    }

    private func sendToWeb(_ data: [String: String]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let jsonStr = String(data: jsonData, encoding: .utf8) else { return }
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(
                "window.cipkoIAPCallback && window.cipkoIAPCallback(\(jsonStr))"
            ) { _, _ in }
        }
    }
}
