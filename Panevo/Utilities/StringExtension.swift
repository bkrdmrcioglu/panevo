import Foundation

extension String {
    var isValidBundleIdentifier: Bool {
        let pattern = "^[a-zA-Z0-9]+(\\.[a-zA-Z0-9]+)*$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(self.startIndex..., in: self)
        return regex.firstMatch(in: self, range: range) != nil
    }

    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count <= length {
            return self
        }
        let maxLength = length - trailing.count
        return String(self.prefix(maxLength)) + trailing
    }

    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }

    func localized(withComment comment: String) -> String {
        return NSLocalizedString(self, comment: comment)
    }

    var isNotEmpty: Bool {
        return !self.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func withoutWhitespace() -> String {
        return self.replacingOccurrences(of: " ", with: "")
    }

    var camelCaseToWords: String {
        var result = ""
        for (index, char) in self.enumerated() {
            if char.isUppercase && index > 0 {
                result.append(" ")
            }
            result.append(char)
        }
        return result
    }

    func matches(_ pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(self.startIndex..., in: self)
        return regex.firstMatch(in: self, range: range) != nil
    }
}
