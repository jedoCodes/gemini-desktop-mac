//
//  UserScripts.swift
//  GeminiDesktop
//
//  Created by alexcding on 2025-12-15.
//

import WebKit

/// Collection of user scripts injected into WKWebView
enum UserScripts {

    /// Message handler name for console log bridging
    static let consoleLogHandler = "consoleLog"

    /// Creates all user scripts to be injected into the WebView
    static func createAllScripts() -> [WKUserScript] {
        var scripts: [WKUserScript] = [
            createIMEFixScript()
        ]

        #if DEBUG
        scripts.insert(createConsoleLogBridgeScript(), at: 0)
        #endif

        return scripts
    }

    /// Creates a script that bridges console.log to native Swift
    private static func createConsoleLogBridgeScript() -> WKUserScript {
        WKUserScript(
            source: consoleLogBridgeSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
    }

    /// Creates the IME fix script that resolves the double-enter issue
    /// when using input method editors (e.g., Chinese, Japanese, Korean input)
    private static func createIMEFixScript() -> WKUserScript {
        WKUserScript(
            source: imeFixSource,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
    }

    // MARK: - Script Sources

    /// JavaScript to bridge console.log to native Swift via WKScriptMessageHandler
    private static let consoleLogBridgeSource = """
    (function() {
        const originalLog = console.log;
        console.log = function(...args) {
            originalLog.apply(console, args);
            try {
                const message = args.map(arg => {
                    if (typeof arg === 'object') {
                        return JSON.stringify(arg, null, 2);
                    }
                    return String(arg);
                }).join(' ');
                window.webkit.messageHandlers.\(consoleLogHandler).postMessage(message);
            } catch (e) {}
        };
    })();
    """

    /// JavaScript to fix IME double-enter issue on Gemini
    /// When using IME (e.g., Chinese/Japanese input), pressing Enter after completing
    /// composition would require a second Enter to send. This script detects when
    /// IME composition just ended and automatically clicks the send button.
    /// Only activates Enter-key interception after IME usage is detected.
    /// https://update.greasyfork.org/scripts/532717/阻止Gemini两次点击.user.js
    private static let imeFixSource = """
    (function() {
        'use strict';

        let imeActive = false;
        let imeEverUsed = false;
        let imeJustEnded = false;

        document.addEventListener('compositionstart', function() {
            imeActive = true;
            imeEverUsed = true;
        }, true);

        document.addEventListener('compositionend', function() {
            imeActive = false;
            imeJustEnded = true;
            requestAnimationFrame(() => { imeJustEnded = false; });
        }, true);

        function findAndClickSendButton() {
            const button = document.querySelector('button:has(.send-button-icon)');
            if (button && !button.disabled && button.offsetParent !== null) {
                button.click();
                return true;
            }
            return false;
        }

        document.addEventListener('keydown', function(e) {
            if (!imeEverUsed) return;
            // First keydown after compositionend: if it's not Enter,
            // the composition was ended by another key (e.g. Space) — clear the flag
            if (imeJustEnded && e.key !== 'Enter') {
                imeJustEnded = false;
            }
            if (imeActive || imeJustEnded || e.isComposing || e.keyCode === 229) return;
            if (e.key === 'Enter' && !e.shiftKey && !e.ctrlKey && !e.altKey) {
                if (findAndClickSendButton()) {
                    e.stopImmediatePropagation();
                    e.preventDefault();
                }
            }
        }, true);
    })();
    """
}
