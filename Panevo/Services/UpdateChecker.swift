import Foundation
import AppKit
import Combine

/// Lightweight GitHub Releases updater (download DMG → replace app → relaunch).
final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    @Published var latestVersion: String?
    @Published var releaseURL: URL?
    @Published var dmgURL: URL?
    @Published var isUpdateAvailable = false
    @Published var isChecking = false
    @Published var isInstalling = false
    @Published var installStatus: String = ""
    @Published var downloadProgress: Double = 0
    @Published var lastError: String?

    private let repo = "bkrdmrcioglu/panevo"
    private var downloadTask: URLSessionDownloadTask?

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    private var userAgent: String { "Panevo/\(currentVersion)" }

    // MARK: - Check

    /// Checks GitHub for a newer release. If `installIfAvailable`, downloads and installs automatically.
    func checkForUpdates(installIfAvailable: Bool = false) {
        guard !isChecking, !isInstalling else { return }
        isChecking = true
        lastError = nil
        installStatus = ""

        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else {
            isChecking = false
            return
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
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
                    self.lastError = NSLocalizedString("Could not parse release info", comment: "")
                    return
                }

                let remote = tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                self.latestVersion = remote
                if let html = json["html_url"] as? String {
                    self.releaseURL = URL(string: html)
                }
                self.dmgURL = Self.dmgAssetURL(from: json)
                self.isUpdateAvailable = Self.isVersion(remote, newerThan: self.currentVersion)

                if installIfAvailable, self.isUpdateAvailable {
                    self.installUpdate()
                }
            }
        }.resume()
    }

    // MARK: - Install

    func installUpdate() {
        guard !isInstalling else { return }

        if let dmgURL {
            startDownload(from: dmgURL)
            return
        }

        guard !isChecking else { return }
        isChecking = true
        lastError = nil

        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else {
            isChecking = false
            return
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
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
                      let dmg = Self.dmgAssetURL(from: json) else {
                    self.lastError = NSLocalizedString("No DMG found in the latest release", comment: "")
                    return
                }

                self.dmgURL = dmg
                if let tag = json["tag_name"] as? String {
                    self.latestVersion = tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                }
                self.startDownload(from: dmg)
            }
        }.resume()
    }

    private func startDownload(from url: URL) {
        isInstalling = true
        downloadProgress = 0
        lastError = nil
        installStatus = NSLocalizedString("Downloading update…", comment: "")

        let session = URLSession(
            configuration: .default,
            delegate: DownloadDelegate(owner: self),
            delegateQueue: .main
        )

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        downloadTask = session.downloadTask(with: request)
        downloadTask?.resume()
    }

    fileprivate func handleDownloadFinished(tempURL: URL?, error: Error?) {
        if let error {
            fail(error.localizedDescription)
            return
        }

        guard let tempURL else {
            fail(NSLocalizedString("Download failed", comment: ""))
            return
        }

        installStatus = NSLocalizedString("Installing…", comment: "")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.applyUpdate(dmgURL: tempURL)
        }
    }

    fileprivate func updateProgress(_ progress: Double) {
        downloadProgress = min(max(progress, 0), 1)
        let pct = Int(downloadProgress * 100)
        installStatus = String(format: NSLocalizedString("Downloading update… %d%%", comment: ""), pct)
    }

    private func applyUpdate(dmgURL: URL) {
        let fm = FileManager.default
        let mountPoint = fm.temporaryDirectory.appendingPathComponent("PanevoUpdateMount-\(UUID().uuidString)")
        let staging = fm.temporaryDirectory.appendingPathComponent("Panevo-new-\(UUID().uuidString).app")
        let helper = fm.temporaryDirectory.appendingPathComponent("panevo-apply-update.sh")

        do {
            try fm.createDirectory(at: mountPoint, withIntermediateDirectories: true)

            let attach = Process()
            attach.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            attach.arguments = [
                "attach", dmgURL.path,
                "-nobrowse", "-readonly",
                "-mountpoint", mountPoint.path,
            ]
            attach.standardOutput = FileHandle.nullDevice
            attach.standardError = FileHandle.nullDevice
            try attach.run()
            attach.waitUntilExit()
            guard attach.terminationStatus == 0 else {
                throw UpdateError.mountFailed
            }

            guard let sourceApp = findApp(in: mountPoint) else {
                detach(mountPoint)
                throw UpdateError.appNotFoundInDMG
            }

            try? fm.removeItem(at: staging)
            try fm.copyItem(at: sourceApp, to: staging)

            detach(mountPoint)
            try? fm.removeItem(at: mountPoint)
            try? fm.removeItem(at: dmgURL)

            let destination = installDestination()
            let script = """
            #!/bin/bash
            set -e
            DEST=\(shellEscape(destination.path))
            SRC=\(shellEscape(staging.path))
            for i in $(seq 1 50); do
              if ! pgrep -x "Panevo" >/dev/null 2>&1; then
                break
              fi
              sleep 0.2
            done
            sleep 0.4
            rm -rf "$DEST"
            /usr/bin/ditto "$SRC" "$DEST"
            /usr/bin/xattr -cr "$DEST" || true
            rm -rf "$SRC"
            /usr/bin/open "$DEST"
            rm -f "$0"
            """

            try script.write(to: helper, atomically: true, encoding: .utf8)
            try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: helper.path)

            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = [helper.path]
            try task.run()

            DispatchQueue.main.async {
                self.installStatus = NSLocalizedString("Restarting…", comment: "")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    NSApp.terminate(nil)
                }
            }
        } catch {
            detach(mountPoint)
            try? fm.removeItem(at: staging)
            try? fm.removeItem(at: dmgURL)
            DispatchQueue.main.async {
                self.fail(error.localizedDescription)
            }
        }
    }

    private func detach(_ mountPoint: URL) {
        let detach = Process()
        detach.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        detach.arguments = ["detach", mountPoint.path, "-quiet", "-force"]
        try? detach.run()
        detach.waitUntilExit()
    }

    private func installDestination() -> URL {
        let running = Bundle.main.bundleURL
        if running.pathExtension == "app" {
            return running
        }
        return URL(fileURLWithPath: "/Applications/Panevo.app")
    }

    private func findApp(in mountPoint: URL) -> URL? {
        let fm = FileManager.default
        let direct = mountPoint.appendingPathComponent("Panevo.app")
        if fm.fileExists(atPath: direct.path) { return direct }

        if let contents = try? fm.contentsOfDirectory(
            at: mountPoint,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            return contents.first { $0.pathExtension == "app" }
        }
        return nil
    }

    private func fail(_ message: String) {
        isInstalling = false
        downloadProgress = 0
        installStatus = ""
        lastError = message
    }

    private func shellEscape(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    // MARK: - Helpers

    private static func dmgAssetURL(from json: [String: Any]) -> URL? {
        guard let assets = json["assets"] as? [[String: Any]] else { return nil }
        for asset in assets {
            if let name = asset["name"] as? String,
               name.lowercased().hasSuffix(".dmg"),
               let urlString = asset["browser_download_url"] as? String,
               let url = URL(string: urlString) {
                return url
            }
        }
        return nil
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

// MARK: - Download delegate

private final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    weak var owner: UpdateChecker?
    private var didFinish = false

    init(owner: UpdateChecker) {
        self.owner = owner
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let fm = FileManager.default
        let stable = fm.temporaryDirectory.appendingPathComponent("Panevo-download-\(UUID().uuidString).dmg")
        try? fm.removeItem(at: stable)
        do {
            try fm.copyItem(at: location, to: stable)
            didFinish = true
            owner?.handleDownloadFinished(tempURL: stable, error: nil)
        } catch {
            owner?.handleDownloadFinished(tempURL: nil, error: error)
        }
        session.finishTasksAndInvalidate()
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        owner?.updateProgress(progress)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error, !didFinish {
            owner?.handleDownloadFinished(tempURL: nil, error: error)
            session.finishTasksAndInvalidate()
        }
    }
}

private enum UpdateError: LocalizedError {
    case mountFailed
    case appNotFoundInDMG

    var errorDescription: String? {
        switch self {
        case .mountFailed:
            return NSLocalizedString("Could not open the update disk image", comment: "")
        case .appNotFoundInDMG:
            return NSLocalizedString("Panevo.app not found in the update package", comment: "")
        }
    }
}
