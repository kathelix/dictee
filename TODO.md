
# Paper-session safety net for missing separators

During a paper dictation session, if the pupil forgets commas between answers the OCR merges multiple answers into a single chunk and positional matching scores them all as wrong — even when every individual word is spelt correctly.

Use the dictated sequence as ground truth to recover these cases:

- When OCR returns fewer chunks than expected, inspect each chunk that contains internal whitespace.
- Try splitting it on whitespace and see whether the resulting pieces match the next N expected words (via `String.normalizedForDictation`).
- If they match, accept the pieces as correct answers for those positions.
- When a recovery happens, reduce the run's neatness score (the student did write legibly, but failed to format — docking neatness is the right signal).

Scope: paper session only (`PaperSessionView.processPhoto`). The import flow has no ground truth to compare against and stays heuristic-free.
