import Vision
import UIKit

enum OCRService {
    enum OCRError: Error {
        case invalidImage
    }

    struct OCRResult {
        let words: [String]
        /// Mean recognition confidence across all text observations (0–1).
        /// Use this as a handwriting neatness proxy: high confidence = legible writing.
        let averageConfidence: Double
    }

    /// Recognises words in an image using on-device Vision OCR (French locale).
    ///
    /// - Parameter handwriting: When `true`, disables language correction so the
    ///   recogniser relies on raw stroke-level features rather than biasing toward
    ///   dictionary words — this produces better results for handwritten text and
    ///   more honest confidence scores for neatness assessment.
    ///
    /// Returns words split on commas and line-breaks, plus an average confidence
    /// score that serves as a handwriting legibility/neatness proxy.
    static func recognizeText(in image: UIImage, handwriting: Bool = false) async throws -> OCRResult {
        guard let cgImage = image.cgImage else { throw OCRError.invalidImage }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []

                // Collect (line text, confidence) pairs.
                let items: [(String, Double)] = observations.compactMap { obs in
                    guard let top = obs.topCandidates(1).first else { return nil }
                    return (top.string, Double(top.confidence))
                }

                let avgConfidence = items.isEmpty
                    ? 0.0
                    : items.map(\.1).reduce(0, +) / Double(items.count)

                // Split each line on commas (French lists often pack multiple words per line).
                let words: [String] = items
                    .map(\.0)
                    .flatMap { line in
                        line
                            .components(separatedBy: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                    }

                continuation.resume(returning: OCRResult(words: words, averageConfidence: avgConfidence))
            }

            request.recognitionLanguages = ["fr-FR", "fr"]
            request.recognitionLevel = .accurate
            // Language correction helps printed text but biases against raw handwriting strokes.
            request.usesLanguageCorrection = !handwriting

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
