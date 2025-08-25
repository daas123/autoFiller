//
//  HomeWebViewController.swift
//  autoFiller
//
//  Created by Neosoft on 2025-08-23.
//

import UIKit
import WebKit
import UniformTypeIdentifiers
import QuickLook

class HomeWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UISearchBarDelegate, WKScriptMessageHandler  {
    
    @IBOutlet weak var searchview: UISearchBar!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var leftBtn: UIButton!
    @IBOutlet weak var rigthBtn: UIButton!
    @IBOutlet weak var refreshBtn: UIButton!
    
    private var fileUploadCompletionHandler: (([URL]?) -> Void)?
    private var previewURL: URL?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "fileUpload")
        
        webView = WKWebView(frame: webView.frame, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        searchview.delegate = self
        view.addSubview(webView) // ensure it’s added after re-init
        
        if let url = URL(string: "https://healthasyst.keka.com/careers/applyjob/88608?source=linkedin") {
            webView.load(URLRequest(url: url))
        }
    }
    
    // MARK: - UISearchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        guard var text = searchBar.text, !text.isEmpty else { return }
        
        if !text.contains(".") {
            text = "https://www.google.com/search?q=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        } else if !text.hasPrefix("http://") && !text.hasPrefix("https://") {
            text = "https://\(text)"
        }
        
        if let url = URL(string: text) {
            webView.load(URLRequest(url: url))
        }
    }
    
    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        injectAutofillJS()
        updateNavButtons()
    }
    
    // MARK: - Autofill (Text fields)
    private func injectAutofillJS() {
        let js = """
        function matchAndFill(valueMap, skills) {
            let inputs = document.querySelectorAll('input, textarea, select');
        
            inputs.forEach(el => {
                let labelText = "";
        
                if (el.labels && el.labels.length > 0) {
                    labelText = el.labels[0].innerText.toLowerCase();
                }
                if (!labelText && el.getAttribute('aria-label')) {
                    labelText = el.getAttribute('aria-label').toLowerCase();
                }
                if (!labelText && el.placeholder) {
                    labelText = el.placeholder.toLowerCase();
                }
                if (!labelText && el.name) {
                    labelText = el.name.toLowerCase();
                }
                if (!labelText && el.id) {
                    labelText = el.id.toLowerCase();
                }
        
                for (const key in valueMap) {
                    let keywords = valueMap[key].keywords;
                    let value = valueMap[key].value;
        
                    if (keywords.some(word => labelText.includes(word))) {
                        if (el.tagName.toLowerCase() === 'select') {
                            for (let option of el.options) {
                                if (option.value.toLowerCase() === value.toLowerCase() ||
                                    option.text.toLowerCase() === value.toLowerCase()) {
                                    el.value = option.value;
                                    el.dispatchEvent(new Event('change', { bubbles: true }));
                                    break;
                                }
                            }
                        } else {
                            el.value = value;
                            el.dispatchEvent(new Event('input', { bubbles: true }));
                            el.dispatchEvent(new Event('change', { bubbles: true }));
                        }
                        break;
                    }
                }
        
                if (labelText.includes("skill")) {
                    skills.forEach(skill => {
                        el.value = skill;
                        el.dispatchEvent(new Event('input', { bubbles: true }));
                        let keyEvent = new KeyboardEvent('keydown', { key: 'Enter', bubbles: true });
                        el.dispatchEvent(keyEvent);
                    });
                }
            });
        }
        
        matchAndFill({
            firstName: { value: "Saad", keywords: ["first name", "given name", "fname"] },
            lastName: { value: "Vadanagara", keywords: ["last name", "surname", "lname", "family name"] },
            email: { value: "saadvadanagara@gmail.com", keywords: ["email","mail","emailid"] },
            phone: { value: "8080742420", keywords: ["phone", "mobile", "tel", "contact"] },
            city: { value: "Mumbai", keywords: ["city", "location", "town"] },
            country: { value: "India", keywords: ["country", "nation"] },
            zip: { value: "400097", keywords: ["zip", "postal", "postcode"] },
            expYears: { value: "2", keywords: ["experience year", "total experience", "exp year", "years of experience"] },
            expMonths: { value: "3", keywords: ["experience month", "exp month", "months of experience"] },
            noticePeriod: { value: "30", keywords: ["notice period"] },
            department: { value: "engineering", keywords: ["department", "team"] }
        }, ["Swift", "SwiftUI", "UIKit"]);
        """
        
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
    
   
    
    // MARK: - Nav Buttons
    @IBAction func leftBtnAction(_ sender: UIButton) {
        if webView.canGoBack { webView.goBack() }
        updateNavButtons()
    }
    
    @IBAction func rigthBtnAction(_ sender: UIButton) {
        if webView.canGoForward { webView.goForward() }
        updateNavButtons()
    }
    
    @IBAction func refreshBtnAction(_ sender: UIButton) {
        webView.reload()
    }
    
    private func updateNavButtons() {
        leftBtn.isEnabled = webView.canGoBack
        rigthBtn.isEnabled = webView.canGoForward
    }
}

extension HomeWebViewController : UIDocumentPickerDelegate {

    @available(iOS 18.4, *)
    func webView(_ webView: WKWebView,
                 runOpenPanelWith parameters: WKOpenPanelParameters,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping ([URL]?) -> Void) {

        fileUploadCompletionHandler = completionHandler

        let supportedTypes: [UTType] = [.pdf]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .automatic
        present(documentPicker, animated: true)
    }
    
    @objc(userContentController:didReceiveScriptMessage:) func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "fileUpload" {
            // handle JS file upload call
            print("JS requested file upload")
            // present your UIDocumentPicker here
//            presentFilePicker()
        }
    }

}

extension HomeWebViewController {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true)
        fileUploadCompletionHandler?(urls)  // Pass files back to WKWebView
        fileUploadCompletionHandler = nil
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
        fileUploadCompletionHandler?(nil)   // Notify cancellation
        fileUploadCompletionHandler = nil
    }

}


extension HomeWebViewController :  WKDownloadDelegate,QLPreviewControllerDataSource {
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction,
                 didBecome download: WKDownload) {
        download.delegate = self
    }

    // Called when download starts
        func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                      suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
            // Save to temporary folder
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(suggestedFilename)
            completionHandler(fileURL)
        }

        // Called periodically to report progress
        func download(_ download: WKDownload, didReceive data: Data) {
            // optional: update progress UI
        }

        // Called when download finishes successfully
        func downloadDidFinish(_ download: WKDownload) {
            print("Download finished")
        }

        // Called if download fails
        func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
            print("Download failed: \(error.localizedDescription)")
        }
    
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            if let url = navigationAction.request.url {
                let pathExtension = url.pathExtension.lowercased()
                
                // File types Safari usually "opens"
                let openableTypes = ["pdf", "png", "jpg", "jpeg", "txt", "doc", "docx"]
                
                if openableTypes.contains(pathExtension) {
                    // Download to temp and open with QuickLook
                    downloadAndPreview(url: url)
                    decisionHandler(.cancel)
                    return
                }
            }
            
            decisionHandler(.allow)
        }
        
        private func downloadAndPreview(url: URL) {
            let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
                guard let localURL = localURL else { return }
                DispatchQueue.main.async {
                    self.previewURL = localURL
                    let previewVC = QLPreviewController()
                    previewVC.dataSource = self
                    self.present(previewVC, animated: true)
                }
            }
            task.resume()
        }
        
        // MARK: - QuickLook DataSource
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return previewURL == nil ? 0 : 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return previewURL! as NSURL
        }
}


