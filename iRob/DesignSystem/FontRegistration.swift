import SwiftUI
import CoreText

// Registers the bundled typefaces at launch.
//
// The usual route is a `UIAppFonts` array in Info.plist, but this target uses
// Xcode's generated Info.plist and there is no `INFOPLIST_KEY_UIAppFonts` to
// set it with. (`ATSApplicationFontsPath`, which *does* have a build setting,
// is macOS-only and silently does nothing on iOS.) Registering through
// CoreText at launch is equivalent, and has the advantage of failing loudly.

enum FontRegistrar {
    private static let files = [
        "PlusJakartaSans-Regular",
        "PlusJakartaSans-Medium",
        "PlusJakartaSans-SemiBold",
        "PlusJakartaSans-Bold",
        "PlusJakartaSans-ExtraBold",
        "IBMPlexMono-Regular",
        "IBMPlexMono-Medium",
    ]

    static func register() {
        let urls = files.compactMap {
            Bundle.main.url(forResource: $0, withExtension: "ttf")
        }

        assert(urls.count == files.count,
               "Missing font files in bundle — expected \(files.count), found \(urls.count)")

        CTFontManagerRegisterFontURLs(urls as CFArray, .process, true) { errs, _ in
            if CFArrayGetCount(errs) > 0 {
                print("⚠️ Font registration errors: \(errs)")
            }
            return true
        }

        #if DEBUG
        // Fail loudly rather than silently falling back to San Francisco —
        // the whole type scale depends on these resolving.
        for name in files where UIFont(name: name, size: 12) == nil {
            assertionFailure("Font did not register: \(name)")
        }
        #endif
    }
}
