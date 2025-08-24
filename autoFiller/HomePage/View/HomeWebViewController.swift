//
//  HomeWebViewController.swift
//  autoFiller
//
//  Created by Neosoft on 2025-08-23.
//

import UIKit
import WebKit

class HomeWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var searchview: UISearchBar!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var leftBtn: UIButton!
    @IBOutlet weak var rigthBtn: UIButton!
    @IBOutlet weak var refreshBtn: UIButton!
    
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
        injectFileUploadJS()
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
    
    // MARK: - File Upload Autofill
    private func injectFileUploadJS() {
        let js = """
        document.querySelectorAll('input[type=file]').forEach(input => {
            input.addEventListener('click', function(e) {
                e.preventDefault();
                window.webkit.messageHandlers.fileUpload.postMessage('resume');
            });
        });
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

// MARK: - WKScriptMessageHandler
extension HomeWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "fileUpload" {
            if let resumeURL = Bundle.main.url(forResource: "SaadVadanagara", withExtension: "pdf"),
               let data = try? Data(contentsOf: resumeURL) {
                
                let base64 = data.base64EncodedString()
                let js = """
                (function() {
                    var fileInput = document.querySelector('input[type=file]');
                    if (!fileInput) return;
                    
                    // Create a new file from Base64
                    function base64ToBlob(base64, contentType) {
                        var byteCharacters = atob(base64);
                        var byteNumbers = new Array(byteCharacters.length);
                        for (var i = 0; i < byteCharacters.length; i++) {
                            byteNumbers[i] = byteCharacters.charCodeAt(i);
                        }
                        var byteArray = new Uint8Array(byteNumbers);
                        return new Blob([byteArray], {type: contentType});
                    }
                    
                    var blob = base64ToBlob('\(base64)', 'application/pdf');
                    var file = new File([blob], "SaadVadanagara.pdf", {type: "application/pdf"});
                    var dataTransfer = new DataTransfer();
                    dataTransfer.items.add(file);
                    fileInput.files = dataTransfer.files;
                    
                    fileInput.dispatchEvent(new Event('change', { bubbles: true }));
                    console.log("📂 Resume auto-attached!");
                })();
                """
                
                webView.evaluateJavaScript(js, completionHandler: nil)
            } else {
                print("⚠️ Resume not found in bundle")
            }
        }
    }
}
