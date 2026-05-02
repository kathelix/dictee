# Dictee — iOS App Spec

## Overview

A French dictation learning app for pupils, targeting iPhone and iPad. The teacher gives a word list on paper; the pupil photographs it, then practises spelling through typed or paper dictation sessions.

---

## Core Concepts

**Word List** — a set of French words imported from a single photo. A pupil can have many lists (e.g. one per week).

**Session** — a run through all words in a list. Two modes:
- **Typed** — pupil types each word on screen after hearing it.
- **Paper** — pupil hears all words and writes them on paper, then photographs the page; the app grades the handwriting.

**Review Bank** — a persistent collection of words the pupil has misspelled, drawn from across all lists.

---

## Screens & User Flows

### 1. Home

- Shows all saved word lists as a scrollable grid of cards, each displaying:
  - Thumbnail of the original photo
  - Name (auto-generated from import date, editable)
  - Word count, accompanied by a **score ring** and, if a paper session has been completed, a **neatness ring** (see below)
  - Last practiced date (relative, e.g. "2 hours ago")

**Score ring** — a small circular progress arc with the percentage printed in the centre, reflecting the score from the most recent session (typed or paper) for that list:

| Score | Ring colour |
|---|---|
| ≥ 90% correct | Green |
| ≥ 75% correct | Amber |
| < 75% correct | Red |
| Never practised | Gray (0% fill) |

- The arc fill corresponds to the percentage (e.g. 75% correct → ring three-quarters full)
- The percentage number is displayed inside the ring (e.g. "87%")
- Score is taken from the last **Practice Session** for that specific list; Revisit sessions do not affect it
- A never-practised list shows a gray empty ring with no percentage label

**Neatness ring** — a second circular ring shown only for lists that have had at least one **Paper Session** completed. Displays a pencil icon inside (instead of a percentage) and uses the same colour coding as the score ring. The fill and colour reflect the OCR confidence from the most recent paper session — a proxy for how legibly the pupil wrote:

| OCR confidence | Ring colour |
|---|---|
| ≥ 90% | Green (neat / legible) |
| ≥ 75% | Amber |
| < 75% | Red (hard to read) |

- Intended for teachers to assess handwriting neatness alongside spelling correctness
- Not shown for lists that have only been practised in typed mode

- Toolbar: **⚙ Settings** (top-left), **+ Add New List** (top-right). When the learner has at least one star, a compact, non-interactive `⭐ N` total-stars badge sits in the centre of the toolbar between the two buttons; it is hidden entirely while the balance is zero.
- When the Review Bank is non-empty, an orange **Revisit · N words** banner appears pinned at the bottom; it is hidden entirely when the bank is empty
- Tapping a card shows a **mode picker** ("Type your answers" / "Write on paper") before starting a session
- Long-pressing a card shows a context menu with **Details** and **Delete**
- Empty state shown with a prompt to add the first list

---

### 2. Import Flow

**Step 1 — Capture**
- Tap "+ Add New List" to open the import sheet. The Capture step offers two options side by side:
  - **Take Photo** — opens the camera so the pupil can photograph the paper word list
  - **Choose from Library** — picks an existing image via the system Photos picker

**Step 2 — Review & Edit**
- App uses on-device OCR (Vision framework, `fr-FR` locale) to extract words
- Lines are split on commas as well as line breaks (French lists often pack multiple words per line)
- Extracted words shown as an editable list
- User can:
  - Edit a word inline (OCR error)
  - Delete a word (swipe to delete)
  - Reorder words (drag handle)
  - Add a missing word manually via a text field at the bottom
- Tap **Continue**

**Step 3 — Naming**
- Auto-name: "Liste du [date in French]" (e.g. "Liste du 14 avril 2026")
- User can edit before saving
- Tap **Save List**

---

### 3. Practice Session (Typed)

Triggered from Home → tap a word list card → **"Type your answers"**.

**Session flow:**

1. Words are shuffled randomly
2. For each word, the app:
   - Plays an audio pronunciation automatically (TTS, French locale)
   - Shows a large speaker button to replay at any time
   - Shows a progress bar and counter (e.g. "3 of 17")
   - Presents a text input field (keyboard assistance fully disabled — see Design Decisions)
3. Pupil types the spelling and taps **Next** (or **Finish** on the last word, or presses **Done** on the keyboard)
4. The app records the answer silently — **no immediate right/wrong feedback**
5. This continues until all words are exhausted

**End of session — Results Screen:**
- Score shown prominently (e.g. "14 / 17"), coloured by ratio:

| Ratio | Colour |
|---|---|
| ≥ 90% correct | Green |
| ≥ 75% correct | Amber |
| < 75% correct | Red |

- Contextual label beneath the score:

| Ratio | Label |
|---|---|
| 100% | "Perfect!" |
| ≥ 90% | "Excellent" |
| ≥ 70% | "Good job" |
| ≥ 50% | "Keep practising" |
| < 50% | "Don't give up!" |

- Two sections: **Correct ✓** (green) and **Needs work ✗** (red)
- Each incorrect entry shows the correct word and "You wrote: [what the pupil typed]"
- Incorrect words are automatically added to the Review Bank (miss count incremented if already present)
- Words answered correctly here are **not** removed from the Review Bank (only Revisit sessions do that)
- A **Stars** block appears directly under the score header — see "Stars & Rewards" below
- Buttons: **Practice Again**, **Back to Home**

---

### 4. Paper Dictation Session

Triggered from Home → tap a word list card → **"Write on paper"**.

The pupil hears every word, writes answers on a sheet of paper, then photographs it. The app grades the handwriting via OCR.

**Session flow:**

1. **Intro phase:** An "Example" card shows a sample handwritten answer sheet (comma- and newline-separated entries, including multi-word phrases) so the pupil knows how to format their writing. Tap **Start** to begin dictation.
2. Words are shuffled randomly
3. **Dictation phase:** For each word, the app:
   - Plays an audio pronunciation automatically (TTS, French locale)
   - Shows a large speaker button to replay at any time
   - Shows a progress bar and counter (e.g. "3 of 17")
   - **No text input** — the pupil writes on paper
   - Pupil taps **Next Word** to advance, or **Done — Take Photo** on the last word
4. **Capture phase:** App prompts the pupil to photograph their written answer sheet
5. **Processing:** On-device OCR (Vision framework, French locale, language correction disabled so the recogniser relies on raw stroke features rather than biasing toward dictionary words) recognises the words
6. **Matching:** Recognised words are matched positionally to the dictation order (word 1 on the photo ↔ word 1 dictated, etc.). When OCR returns fewer chunks than the dictated count and a chunk contains internal whitespace, the chunk is split greedily so each piece occupies its own position — recovering pupils who forgot a comma between answers. Each recovered chunk docks the neatness score by 0.05 (legible writing, but failed formatting).

**End of session — Results Screen:**
- Same Correct / Needs work layout as the typed session
- Additionally shows a **neatness score** (OCR confidence as a legibility proxy) with a colour-coded neatness ring
- Incorrect words are added to the Review Bank (same rules as typed sessions)
- A **Stars** block appears directly under the score header — see "Stars & Rewards" below
- The neatness score is saved to the word list and shown as a neatness ring on the home card

---

### 5. Revisit Session

Triggered from the orange Revisit banner on Home → shows a **mode picker** ("Type your answers" / "Write on paper") before starting.

The word pool is always drawn from the Review Bank (across all lists), sorted oldest-added first, capped at the configured session size (default 20).

**Typed Revisit** — works identically to the Typed Practice Session, using the Review Bank as the word pool.

**Paper Revisit** — works identically to the Paper Dictation Session (dictation → capture → OCR → results), using the Review Bank as the word pool. Neatness is shown in the results screen but is **not** saved to any individual word list (the words come from multiple lists).

Rules common to both modes:
- Words answered **correctly** are removed from the Review Bank immediately
- Words answered **incorrectly** remain in the Review Bank
- End screen shows the same Correct/Incorrect breakdown, plus: "X words removed from your review list"

---

### 6. Word List Detail

Accessible via long-press context menu → **Details** on any list card.

- View all words in the list, sorted alphabetically
- Each word shows an orange bookmark badge if it is currently in the Review Bank
- Tap the photo thumbnail to view the original photo full-screen
- Options: **Rename** (inline alert), **Delete List** (confirmation dialog)

---

### 7. Settings

Accessible via the ⚙ toolbar button on Home.

- **Max words per Revisit** — stepper, range 5–50 in steps of 5 (default: 20). Oldest-added words are shown first when the bank exceeds this cap.
- **About** — app name and version number

---

## Stars & Rewards

A small, local-first reward system intended to motivate continued practice. **No accounts, no backend, no online sync.**

**Slice 1 rules:**
- One star is awarded for each correctly written word at the end of every completed dictation session — typed, paper, and revisit alike.
- The total balance accumulates across all sessions and persists locally on the device.
- The result screen shows a **Stars** block directly under the score header with three rows:
  - `⭐ +N stars earned` — stars earned in this session
  - A **Total stars** row, with the running balance right-aligned (e.g. `Total stars` … `48`)
  - **🎁 Secret reward** with a lock icon, the caption `M / 50 stars`, and a yellow progress bar
- The reward is permanently locked in Slice 1; no unlock screen or game exists yet. Future slices may introduce additional tiers and unlock experiences.

**Idempotency.** Each completed session produces exactly one `RewardTransaction`, keyed by `SessionResult.id`. A re-render of the same result screen never grants stars twice. A "Practice Again" run starts a fresh session (new `SessionResult.id`) and is awarded normally.

**Persistence.** `RewardTransaction` rows are stored via SwiftData alongside `SessionResult`/`Answer`. The total balance is *derived* (sum over `starsEarned`) — there is no separate counter row to keep in sync.

---

## Data Model

| Entity | Fields |
|---|---|
| `WordList` | id, name, createdAt, photoData (JPEG), lastPracticedAt, handwritingNeatness (Double?), words[] |
| `Word` | id, text, list (WordList?) |
| `ReviewBankEntry` | id, wordId, wordText (denormalized), addedAt, missCount |
| `SessionResult` | id, listId (UUID?), listName, date, isRevisit, isPaperSession, answers[] |
| `Answer` | id, wordId, wordText (denormalized), typed, session (SessionResult?) — `correct` is **computed** (`typed.normalizedForDictation == wordText.normalizedForDictation`), not stored |
| `RewardTransaction` | id, dictationSessionId (= `SessionResult.id`), starsEarned, reason (`"correct_words"` in Slice 1), createdAt |

`WordList.handwritingNeatness` is updated after each paper session (most recent value wins), analogous to `lastPracticedAt`. It is `nil` for lists that have only been practised in typed mode.

---

## Key Design Decisions

**No immediate feedback during a session.** The pupil must commit to their spelling without getting hints partway through — this mirrors a real dictation exam.

**Revisit is the only gate for removing words from the Review Bank.** Getting a word right during a regular Practice Session (typed or paper) does not remove it; the pupil must demonstrate recall specifically in a Revisit context.

**OCR is editable before saving.** French accents (é, è, ê, ç, etc.) are error-prone in OCR; the edit step (including reorder) is a first-class part of the import flow, not an afterthought.

**Audio is TTS, French locale.** No network dependency; uses `AVSpeechSynthesizer` with `fr-FR` voice at a slightly reduced rate for clarity.

**Keyboard assistance is fully disabled during typed sessions.** Autocorrection, spell-check underlining, smart quotes, smart dashes, smart insert/delete, and the QuickType suggestion bar are all suppressed via a custom `UITextField` wrapper (`DictationTextField`). Voice dictation is partially defended: the field overrides `insertDictationResult(_:)` to drop any phrase delivered through that legacy hook, but iOS 16+ "continuous dictation" streams recognised text through `insertText:` — which has no public override — so the keyboard mic key is currently still exploitable. The known OS-level workaround (`keyboardType = .emailAddress`, which suppresses the mic) was rejected on UX grounds. See `docs/TODO.md` for the planned follow-up. The pupil must recall and type every character entirely from memory.

**Apostrophe variants are normalized before comparison.** iOS Smart Punctuation substitutes a curly right single quotation mark (U+2019) when the pupil types an apostrophe. The comparison folds U+2019, U+2018, and U+02BC to a plain straight apostrophe (U+0027) on both sides before comparing, so words like *l'enfance* are never incorrectly marked wrong due to apostrophe style.

**Leading and trailing spaces are stripped before storage.** Pupils sometimes accidentally type spaces at the start or end of a word. The answer is trimmed at submission time so stray spaces never cause a correct answer to be marked wrong.

**Comparison is case-insensitive and accent-sensitive.** "École" matches "école", but "ecole" does not match "école" — preserving accents is the whole point of a French dictation app.

**ReviewBankEntry is denormalized.** Word text is stored directly on the entry (not as a foreign key to `Word`) so Review Bank entries survive if the original word list is deleted.

**Paper session matching is positional.** The pupil writes words in the order they are dictated (shuffled). OCR reads the photo top-to-bottom, which should match that order. Words are paired by position; if OCR reads fewer words than dictated, the missing tail entries are treated as blank (wrong).

**Neatness score is OCR confidence.** After a paper session the mean recognition confidence across all detected text regions is saved as `WordList.handwritingNeatness`. High confidence indicates legible, well-formed letters; low confidence indicates messy or ambiguous writing. This is a practical proxy that requires no extra model or annotation.

---

## Out of Scope (v1)

- Teacher-side account or sharing
- Syncing across devices
- Stroke-level neatness analysis (current neatness score is OCR-confidence-based)
- Images or illustrations for words
- Translation display
- Word category hints (noun, verb, etc.)
