import Foundation

extension Notification.Name {
    static let onboardingDidReset = Notification.Name("OnboardingConfig.didReset")
}

enum OnboardingConfig {
    /// Flip to `false` to disable onboarding app-wide.
    static var isEnabled = true

    static let completionStorageKey = "figma.hasCompletedOnboarding"

    static var shouldPresent: Bool {
        isEnabled && !UserDefaults.standard.bool(forKey: completionStorageKey)
    }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: completionStorageKey)
    }

    /// Clears completion for QA (only meaningful when `isEnabled == true`).
    static func resetCompletion() {
        UserDefaults.standard.removeObject(forKey: completionStorageKey)
        NotificationCenter.default.post(name: .onboardingDidReset, object: nil)
    }
}
