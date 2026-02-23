import Foundation

enum CurrencyFormatting {
    static func format(raw: String) -> String {
        if raw == "N/A" {
            return "N/A"
        }

        guard let value = parseSignedNumber(from: raw) else {
            return "$---.---/kWh"
        }

        let absValue = abs(value)
        if value < 0 {
            return String(format: "-$%.3f/kWh", absValue)
        }
        return String(format: "$%.3f/kWh", absValue)
    }

    private static func parseSignedNumber(from raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let direct = Double(trimmed) {
            return direct
        }

        let allowed = Set("0123456789.-")
        var filtered = ""
        for char in trimmed where allowed.contains(char) {
            filtered.append(char)
        }

        guard !filtered.isEmpty else { return nil }

        // Normalize malformed sign patterns like "--0.05".
        var sign = ""
        var digits = filtered
        if filtered.contains("-") {
            sign = "-"
            digits = filtered.replacingOccurrences(of: "-", with: "")
        }

        let normalized = sign + digits
        return Double(normalized)
    }
}
