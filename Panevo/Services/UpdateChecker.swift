import Foundation
import AppKit
import Combine

/// Lightweight GitHub Releases check (no Sparkle dependency).
final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    @Published var latestVersion: String?
    @Published var releaseURL: URL?
    @Published var isUpdateAvailable = false
    @Published var isChecking = false
    @Published var lastError: String?

    private let repo = "bkrdmrcioglu/panevo"

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    func checkForUpdates(openIfAvailable: Bool = false) {
        guard !isChecking else { return }
        isChecking = true
        lastError = nil

        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else {
            isChecking = false
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Panevo/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isChecking = false

                if let error {
                    self.lastError = error.localizedDescription
                    return
                }

                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tag = json["tag_name"] as? String else {
                    self.lastError = "Could not parse release info"
                    return
                }

                let remote = tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                self.latestVersion = remote
                if let html = json["html_url"] as? String {
                    self.releaseURL = URL(string: html)
                }

                self.isUpdateAvailable = Self.isVersion(remote, newerThan: self.currentVersion)

                if openIfAvailable, self.isUpdateAvailable, let releaseURL = self.releaseURL {
                    NSWorkspace.shared.open(releaseURL)
                }
            }
        }.resume()
    }

    static func isVersion(_ a: String, newerThan b: String) -> Bool {
        let pa = a.split(separator: ".").compactMap { Int($0) }
        let pb = b.split(separator: ".").compactMap { Int($0) }
        let count = max(pa.count, pb.count)
        for i in 0..<count {
            let ai = i < pa.count ? pa[i] : 0
            let bi = i < pb.count ? pb[i] : 0
            if ai != bi { return ai > bi }
        }
        return false
    }
}
