import CoreText
import Foundation

/// Loads bundled Latin `.ttf` files shipped under `Fonts/GoogleFonts/`.
///
/// Fonts are fetched with `scripts/fetch_google_fonts.py` (@fontsource / Google Fonts).
enum GoogleFontsRegistrar {
    private static var didRegister = false
    private static let lock = NSLock()

    private static let bundleNames: [String] = [
        "DotoMono-Regular",
        "RobotoMono-Regular",
        "SometypeMono-Regular",
        "SometypeMono-Bold",
        "Inter-Regular",
        "GothicA1-SemiBold",
        "RedHatMono-Regular",
    ]

    static func registerBundledFonts() {
        lock.lock()
        defer { lock.unlock() }
        guard !didRegister else { return }
        didRegister = true

        let subfolder = "Fonts/GoogleFonts"

        for base in bundleNames {
            let url = Bundle.main.url(
                forResource: base,
                withExtension: "ttf",
                subdirectory: subfolder
            ) ?? Bundle.main.url(forResource: base, withExtension: "ttf")

            guard let url else {
                #if DEBUG
                print("GoogleFontsRegistrar: missing \(base).ttf (expected in \(subfolder) or bundle root)")
                #endif
                continue
            }
            _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
