import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var webViewModel = WebViewModel()

    var body: some View {
        ZStack {
            WebView(viewModel: webViewModel)
                .ignoresSafeArea()

            if webViewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                    Spacer()
                }
                .background(Color.white)
            }

            if webViewModel.hasError {
                VStack(spacing: 20) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("İnternet bağlantısı yok")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Lütfen bağlantını kontrol et ve tekrar dene.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button(action: {
                        webViewModel.reload()
                    }) {
                        Text("Tekrar Dene")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
}

class WebViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var isLoading = true
    @Published var hasError = false
    var webView: WKWebView?

    func setup(webView: WKWebView) {
        self.webView = webView
        webView.navigationDelegate = self
        load()
    }

    func load() {
        hasError = false
        isLoading = true
        guard let url = URL(string: "https://cipkotest.com") else { return }
        webView?.load(URLRequest(url: url))
    }

    func reload() {
        load()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        hasError = true
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        hasError = true
    }
}

struct WebView: UIViewRepresentable {
    @ObservedObject var viewModel: WebViewModel

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = false
        viewModel.setup(webView: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
