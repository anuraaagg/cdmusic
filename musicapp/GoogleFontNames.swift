/// PostScript names from the bundled `.ttf` files (`Fonts/GoogleFonts/`).
///
/// Refresh by running `python3 scripts/fetch_google_fonts.py` — see
/// `scripts/google_font_postscript_names.json`.
enum GoogleFontName {
    /// **Doto** on Google Fonts (monospace; sometimes called “Doto Mono”). Bundled as `DotoMono-Regular.ttf`.
    /// PostScript name is read from the font’s `name` table (instanced variable font).
    static let dotoMono = "DotoBlack-Regular"

    /// @deprecated Renamed — use `dotoMono`.
    static let dotoStatus = dotoMono
    static let robotoMonoRegular = "RobotoMono-Regular"
    static let sometypeMonoRegular = "SometypeMono-Regular"
    static let sometypeMonoBold = "SometypeMono-Bold"
    static let interRegular = "Inter-Regular"
    static let gothicA1Semibold = "GothicA1-SemiBold"
    static let redHatMonoRegular = "RedHatMono-Regular"
}
