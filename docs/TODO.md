## Re-investigate keyboard voice dictation defeat

`DictationTextField` overrides `insertDictationResult(_:)` as belt-and-braces,
but on iOS 16+ Apple's "continuous dictation" streams recognised text through
the regular `insertText:` pipeline, bypassing every public hook. A pupil can
still tap the keyboard mic key and speak the word into a typed session. We
rejected `keyboardType = .emailAddress` (the only documented OS-level mic
suppressor) on UX grounds — the resulting `@` key feels wrong in a French
spelling app.

Options to revisit:

- Build a custom `inputView` — our own SwiftUI keyboard with the French
  alphabet and long-press accents, no system mic / QuickType / autocorrect
  surface area. Highest effort, fully reliable.
- Check each new iOS release for `textField.allowDictation = false` (a
  long-standing HIPAA-compliance request that Apple may eventually grant).
- Document Guided Access for parents as a system-level workaround.
