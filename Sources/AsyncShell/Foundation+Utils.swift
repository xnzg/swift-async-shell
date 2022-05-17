import Foundation

extension FileManager {
    func executablePath(for name: String) -> String? {
        let pathList = (ProcessInfo.processInfo.environment["PATH"] ?? "/bin:/sbin")
        for path in pathList.split(separator: ":") {
            let attempt = "\(path)/\(name)"
            guard FileManager.default.isExecutableFile(atPath: attempt) else { continue }
            return attempt
        }
        return nil
    }
}
