import SwiftUI
import UIKit

/// A UITextField wrapper that disables every keyboard assistance feature
/// that could help a pupil avoid thinking about the correct spelling:
///   - Autocorrection
///   - Spell-check underlining
///   - QuickType predictive-text suggestion bar
///   - Voice dictation results (the system mic key cannot be hidden, but
///     any phrase it recognises is swallowed before reaching the field)
struct DictationTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var onSubmit: (() -> Void)? = nil

    func makeUIView(context: Context) -> UITextField {
        let field = NoDictationTextField()
        field.delegate = context.coordinator
        field.placeholder = placeholder
        field.textAlignment = .center
        field.font = UIFont.preferredFont(forTextStyle: .title2)
        field.returnKeyType = .done
        field.borderStyle = .none
        field.backgroundColor = .clear

        // Disable all keyboard assistance
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.autocapitalizationType = .none
        field.smartQuotesType = .no
        field.smartDashesType = .no
        field.smartInsertDeleteType = .no

        // Remove the QuickType suggestion bar entirely
        field.inputAssistantItem.leadingBarButtonGroups = []
        field.inputAssistantItem.trailingBarButtonGroups = []

        field.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged(_:)),
            for: .editingChanged
        )
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        var onSubmit: (() -> Void)?

        init(text: Binding<String>, onSubmit: (() -> Void)?) {
            _text = text
            self.onSubmit = onSubmit
        }

        @objc func textChanged(_ field: UITextField) {
            text = field.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onSubmit?()
            return false
        }
    }
}

// MARK: - Dictation-resistant UITextField

/// A `UITextField` that ignores voice-dictation input.
///
/// The microphone key on the system keyboard cannot be hidden by an app — its
/// visibility is governed by *Settings → General → Keyboard → Enable
/// Dictation*. To stop pupils cheating by speaking the word, we override the
/// dictation insertion hook so any recognised phrase is silently dropped.
/// The mic key still appears and can be tapped, but produces no text.
private final class NoDictationTextField: UITextField {
    override func insertDictationResult(_ dictationResult: [UIDictationPhrase]) {
        // Intentionally empty: pupils must type, not speak.
    }
}
