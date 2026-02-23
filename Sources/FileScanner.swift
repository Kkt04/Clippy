import Foundation

// MARK: - Scan Result Models

public struct ScanResult: Sendable {
    public let files: [FileDescriptor]
    public let errors: [ScanError]
    public let wasCancelled: Bool
    public let scannedFileCount: Int

    public init(
        files: [FileDescriptor],
        errors: [ScanError],
        wasCancelled: Bool = false,
        scannedFileCount: Int? = nil
    ) {
        self.files = files
        self.errors = errors
        self.wasCancelled = wasCancelled
        self.scannedFileCount = scannedFileCount ?? files.count
    }
}

public struct ScanError: Error, Sendable, Identifiable {
    public let id = UUID()
    public let url: URL
    public let message: String
}

public struct ScanProgress: Sendable {
    public let filesFound: Int
    public let currentPath: String?
    public let isCancelled: Bool

    public init(
        filesFound: Int,
        currentPath: String? = nil,
        isCancelled: Bool = false
    ) {
        self.filesFound = filesFound
        self.currentPath = currentPath
        self.isCancelled = isCancelled
    }
}

// MARK: - File Scanner Actor

public actor FileScanner {

    private var currentTask: Task<ScanResult, Never>?
    private var isCancelled = false

    public init() {}

    // MARK: Cancellation

    public func cancel() {
        isCancelled = true
        currentTask?.cancel()
    }

    private func resetCancellation() {
        isCancelled = false
    }

    // MARK: Public Scan API

    public func scan(
        folderURL: URL,
        progressHandler: (@Sendable (ScanProgress) -> Void)? = nil
    ) async -> ScanResult {

        resetCancellation()

        let task = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else {
                return ScanResult(files: [], errors: [])
            }

            return await self.performScan(
                at: folderURL,
                progressHandler: progressHandler
            )
        }

        currentTask = task
        let result = await task.value
        currentTask = nil

        return result
    }

    public func scanWithDuplicateDetection(
        folderURL: URL,
        progressHandler: (@Sendable (ScanProgress) -> Void)? = nil
    ) async -> (scanResult: ScanResult, duplicates: [[FileDescriptor]]) {

        let scanResult = await scan(
            folderURL: folderURL,
            progressHandler: progressHandler
        )

        if Task.isCancelled || isCancelled {
            return (scanResult, [])
        }

        let duplicates = findDuplicates(in: scanResult.files)
        return (scanResult, duplicates)
    }

    // MARK: Duplicate Detection

    private func findDuplicates(in files: [FileDescriptor]) -> [[FileDescriptor]] {
        let sizeGroups = Dictionary(grouping: files) { $0.fileSize }

        return sizeGroups.values.filter { $0.count > 1 }
    }

    // MARK: Core Scan Logic (SYNC – Swift 6 Safe)

    private func performScan(
        at rootURL: URL,
        progressHandler: (@Sendable (ScanProgress) -> Void)? = nil
    ) async -> ScanResult {

        var files: [FileDescriptor] = []
        var fileCount = 0
        var collectedErrors: [ScanError] = []

        let needsStopAccessing = rootURL.startAccessingSecurityScopedResource()
        defer {
            if needsStopAccessing {
                rootURL.stopAccessingSecurityScopedResource()
            }
        }

        let keys: [URLResourceKey] = [
            .nameKey,
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .fileSizeKey,
            .creationDateKey,
            .contentModificationDateKey,
            .isReadableKey
        ]

        guard let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: keys,
            options: [],
            errorHandler: { url, error in
                collectedErrors.append(
                    ScanError(url: url, message: error.localizedDescription)
                )
                return true
            }
        ) else {
            return ScanResult(
                files: [],
                errors: [ScanError(url: rootURL, message: "Failed to create file enumerator.")]
            )
        }

        // 🔥 SAFE in Swift 6 because enumeration is inside actor context
        while let fileURL = enumerator.nextObject() as? URL {

            if Task.isCancelled || isCancelled {
                progressHandler?(
                    ScanProgress(
                        filesFound: fileCount,
                        currentPath: fileURL.path,
                        isCancelled: true
                    )
                )

                return ScanResult(
                    files: files,
                    errors: collectedErrors,
                    wasCancelled: true,
                    scannedFileCount: fileCount
                )
            }

            do {
                let resourceValues = try fileURL.resourceValues(
                    forKeys: Set(keys)
                )

                let descriptor = FileDescriptor(
                    fileURL: fileURL,
                    fileName: resourceValues.name ?? fileURL.lastPathComponent,
                    fileExtension: fileURL.pathExtension,
                    fileSize: resourceValues.fileSize.map { Int64($0) },
                    createdAt: resourceValues.creationDate,
                    modifiedAt: resourceValues.contentModificationDate,
                    isDirectory: resourceValues.isDirectory ?? false,
                    isSymlink: resourceValues.isSymbolicLink ?? false,
                    permissionsReadable: resourceValues.isReadable ?? false
                )

                files.append(descriptor)
                fileCount += 1

                if fileCount % 100 == 0 {
                    progressHandler?(
                        ScanProgress(
                            filesFound: fileCount,
                            currentPath: fileURL.path,
                            isCancelled: false
                        )
                    )
                }

            } catch {
                collectedErrors.append(
                    ScanError(
                        url: fileURL,
                        message: "Attribute extraction failed: \(error.localizedDescription)"
                    )
                )
            }
        }

        return ScanResult(
            files: files,
            errors: collectedErrors,
            wasCancelled: false,
            scannedFileCount: fileCount
        )
    }
}