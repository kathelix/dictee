import Vision
import UIKit

enum OCRService {
    enum OCRError: Error {
        case invalidImage
    }

    /// Recognises words in an image using on-device Vision OCR (French locale).
    /// Returns a flat list of individual tokens split on commas and whitespace.
    static func recognizeText(in image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else { throw OCRError.invalidImage }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []

                // Each observation is a line; split each line on commas to
                // separate list items that share a line (e.g. "un membre, la maison").
                let words: [String] = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .flatMap { line in
                        line
                            .components(separatedBy: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                    }

                continuation.resume(returning: words)
            }

            request.recognitionLanguages = ["fr-FR", "fr"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
