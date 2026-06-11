//
//  NFCScannerManager.swift
//  AmiiboAnalyzer
//

import CoreNFC
import Observation

@Observable
final class NFCScannerManager: NSObject {

    enum ScanState {
        case idle
        case scanning
        case detected(NFCTag)
        case failed(Error)
    }

    private(set) var scanState: ScanState = .idle
    var isScanning: Bool { if case .scanning = scanState { return true }; return false }

    let detectedTags: AsyncStream<NFCTag>
    private let tagContinuation: AsyncStream<NFCTag>.Continuation

    private var session: NFCTagReaderSession?

    override init() {
        var continuation: AsyncStream<NFCTag>.Continuation!
        detectedTags = AsyncStream { continuation = $0 }
        tagContinuation = continuation
        super.init()
    }

    deinit {
        tagContinuation.finish()
    }

    /// Reads pages 21–22 of the NTAG215 and returns the 16-char hex Amiibo ID.
    /// Call this before stopScanning() while the session is still active.
    func readAmiiboID(from tag: NFCTag) async throws -> String {
        guard case .miFare(let miFareTag) = tag else {
            throw AmiiboScanError.unsupportedTagType
        }
        // READ returns 16 bytes (4 pages) starting at the given page number.
        let response = try await miFareTag.sendMiFareCommand(commandPacket: Data([0x30, 21]))
        guard response.count >= 8 else {
            throw AmiiboScanError.insufficientData
        }
        return response[0..<8].map { String(format: "%02x", $0) }.joined()
    }

    func startScanning() {
        guard NFCTagReaderSession.readingAvailable else { return }
        let configuration = NFCTagReaderSession.Configuration(
            pollingOption: .iso14443,
            iso7816SelectIdentifiers: [],
            feliCaSystemCodes: []
        )
        let newSession = NFCTagReaderSession(configuration: configuration, delegate: self, queue: nil)
        newSession.alertMessage = "Hold your Amiibo near the top of your iPhone."
        newSession.begin()
        session = newSession
        scanState = .scanning
    }

    func stopScanning() {
        session?.invalidate()
        session = nil
        scanState = .idle
    }
}

enum AmiiboScanError: Error {
    case unsupportedTagType
    case insufficientData
}

extension NFCScannerManager: NFCTagReaderSessionDelegate {

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        self.session = nil
        if let readerError = error as? NFCReaderError,
           readerError.code == .readerSessionInvalidationErrorUserCanceled ||
           readerError.code == .readerSessionInvalidationErrorSessionTerminatedUnexpectedly {
            scanState = .idle
        } else {
            scanState = .failed(error)
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }
        session.connect(to: tag) { [weak self] error in
            guard let self else { return }
            if let error {
                session.invalidate(errorMessage: "Failed to connect. Please try again.")
                self.scanState = .failed(error)
                return
            }
            session.alertMessage = "Amiibo detected!"
            self.scanState = .detected(tag)
            self.tagContinuation.yield(tag)
        }
    }
}
