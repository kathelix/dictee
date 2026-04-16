# Dictee — iOS App Spec

## Overview

A French dictation learning app for pupils, targeting iPhone and iPad. The teacher gives a word list on paper; the pupil photographs it, then practices spelling through typed dictation sessions.

---

## Core Concepts

**Word List** — a set of French words imported from a single photo. A pupil can have many lists (e.g. one per week).

**Session** — a run through all words in a list where the pupil types spellings from memory.

**Review Bank** — a persistent collection of words the pupil has misspelled, drawn from across all lists.

---

## Screens & User Flows

### 1. Home

- Shows all saved word lists as a scrollable grid of cards, each displaying:
  - Thumbnail of the original photo
  - Name (auto-generated from import date, editable)
  - Word count
  - Last practiced date (relative, e.g. "2 hours ago")
- Toolbar: **⚙ Settings** (top-left), **+ Add New List** (top-right)
- When the Review Bank is non-empty, an orange **Revisit · N words** banner appears pinned at the bottom; it is hidden entirely when the bank is empty
- Tapping a card immediately starts a Practice Session for that list
- Long-pressing a card shows a context menu with **Details** and **Delete**
- Empty state shown with a prompt to add the first list

---

### 2. Import Flow

**Step 1 — Capture**
- Tap "+ Add New List" → camera opens
- User photographs the paper word list
- Option to choose an existing photo from the library instead

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

### 3. Practice Session

Triggered from Home by tapping a word list card.

**Session flow:**

1. Words are shuffled randomly
2. For each word, the app:
   - Plays an audio pronunciation automatically (TTS, French locale)
   - Shows a large speaker button to replay at any time
   - Shows a progress bar and counter (e.g. "3 of 17")
   - Presents a text input field (keyboard assistance fully disabled — see Design Decisions)
3. Pupil types the spelling and taps **Next** (or **Finish** on the last word, or presses Return)
4. The app records the answer silently — **no immediate right/wrong feedback**
5. This continues until all words are exhausted

**End of session — Results Screen:**
- Score shown prominently (e.g. "14 / 17") with a contextual label ("Perfect!", "Excellent", "Good job", etc.)
- Two sections: **Correct ✓** (green) and **Needs work ✗** (red)
- Each incorrect entry shows the correct word and "You wrote: [what the pupil typed]"
- Incorrect words are automatically added to the Review Bank (miss count incremented if already present)
- Words answered correctly here are **not** removed from the Review Bank (only Revisit sessions do that)
- Buttons: **Practice Again**, **Back to Home**

---

### 4. Revisit Session

Triggered from the orange Revisit banner on Home.

- Works identically to a Practice Session, but the word pool is drawn from the Review Bank (across all lists), sorted oldest-added first
- Session size is capped (default 20, configurable in Settings)
- Words answered **correctly** in this session are removed from the Review Bank immediately
- Words answered **incorrectly** remain in the Review Bank
- End screen shows the same Correct/Incorrect breakdown, plus: "X words removed from your review list"

---

### 5. Word List Detail

Accessible via long-press context menu → **Details** on any list card.

- View all words in the list, sorted alphabetically
- Each word shows an orange bookmark badge if it is currently in the Review Bank
- Tap the photo thumbnail to view the original photo full-screen
- Options: **Rename** (inline alert), **Delete List** (confirmation dialog)

---

### 6. Settings

Accessible via the ⚙ toolbar button on Home.

- **Max words per Revisit** — stepper, range 5–50 in steps of 5 (default: 20). Oldest-added words are shown first when the bank exceeds this cap.
- **About** — app name and version number

---

## Data Model

| Entity | Fields |
|---|---|
| `WordList` | id, name, createdAt, photoData (JPEG), lastPracticedAt, words[] |
| `Word` | id, text, list → WordList |
| `ReviewBankEntry` | id, wordId, wordText (denormalized), addedAt, missCount |
| `SessionResult` | id, listId, listName, date, isRevisit, answers[] |
| `Answer` | id, wordId, wordText (denormalized), typed, correct, session → SessionResult |

---

## Key Design Decisions

**No immediate feedback during a session.** The pupil must commit to their spelling without getting hints partway through — this mirrors a real dictation exam.

**Revisit is the only gate for removing words from the Review Bank.** Getting a word right during a regular Practice Session does not remove it; the pupil must demonstrate recall specifically in a Revisit context.

**OCR is editable before saving.** French accents (é, è, ê, ç, etc.) are error-prone in OCR; the edit step (including reorder) is a first-class part of the import flow, not an afterthought.

**Audio is TTS, French locale.** No network dependency; uses `AVSpeechSynthesizer` with `fr-FR` voice at a slightly reduced rate for clarity.

**Keyboard assistance is fully disabled during sessions.** Autocorrection, spell-check underlining, smart quotes, smart dashes, and the QuickType suggestion bar are all suppressed via a custom `UITextField` wrapper (`DictationTextField`). The pupil must recall and type every character entirely from memory.

**Apostrophe variants are normalized before comparison.** iOS Smart Punctuation substitutes a curly right single quotation mark (U+2019) when the pupil types an apostrophe. The comparison folds U+2019, U+2018, and U+02BC to a plain straight apostrophe (U+0027) on both sides before comparing, so words like *l'enfance* are never incorrectly marked wrong due to apostrophe style.

**Leading and trailing spaces are stripped before storage.** Pupils sometimes accidentally type spaces at the start or end of a word. The answer is trimmed at submission time so stray spaces never cause a correct answer to be marked wrong, and the results screen never shows confusing whitespace in "You wrote: …".

**Comparison is case-insensitive and accent-sensitive.** "École" matches "école", but "ecole" does not match "école" — preserving accents is the whole point of a French dictation app.

**ReviewBankEntry is denormalized.** Word text is stored directly on the entry (not as a foreign key to `Word`) so Review Bank entries survive if the original word list is deleted.

---

## Out of Scope (v1)

- Teacher-side account or sharing
- Syncing across devices
- Handwriting recognition (typed input only)
- Images or illustrations for words
- Translation display
- Word category hints (noun, verb, etc.)
