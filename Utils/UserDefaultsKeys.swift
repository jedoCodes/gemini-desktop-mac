//
//  UserDefaultsKeys.swift
//  GeminiDesktop
//
//  Created by alexcding on 2025-12-13.
//

import Foundation
import AppKit

enum UserDefaultsKeys: String {
    case panelWidth
    case panelHeight
    case pageZoom
    case hideWindowAtLaunch
    case hideDockIcon
    case appTheme
    case userAgentOption
    case customUserAgent
}

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    func apply() {
        switch self {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    static var current: AppTheme {
        let raw = UserDefaults.standard.string(forKey: UserDefaultsKeys.appTheme.rawValue) ?? "system"
        return AppTheme(rawValue: raw) ?? .system
    }
}

enum UserAgentOption: String, CaseIterable {
    case safari
    case chrome
    case custom

    var displayName: String {
        switch self {
        case .safari: return "Safari"
        case .chrome: return "Chrome"
        case .custom: return "Custom"
        }
    }

    static let safariUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    static let chromeUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

    func userAgentString(custom: String = "") -> String {
        switch self {
        case .safari: return Self.safariUA
        case .chrome: return Self.chromeUA
        case .custom: return custom.isEmpty ? Self.safariUA : custom
        }
    }

    func settingsDescription(custom: String = "") -> String {
        switch self {
        case .safari: return "Identifies as Safari 17.0 on macOS"
        case .chrome: return "Identifies as Chrome 131 on macOS"
        case .custom: return custom.isEmpty ? "No custom user agent set — falls back to Safari" : "Using custom user agent string"
        }
    }

    static var current: UserAgentOption {
        let raw = UserDefaults.standard.string(forKey: UserDefaultsKeys.userAgentOption.rawValue) ?? "safari"
        return UserAgentOption(rawValue: raw) ?? .safari
    }

    static var currentUserAgentString: String {
        let option = current
        let custom = UserDefaults.standard.string(forKey: UserDefaultsKeys.customUserAgent.rawValue) ?? ""
        return option.userAgentString(custom: custom)
    }
}
