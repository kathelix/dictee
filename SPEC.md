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

- Shows all saved word lists, each displaying:
  - Thumbnail of the original photo
  - Name (auto-generated from import date, editable)
  - Word count
  - Last practiced date
- Buttons: **Add New List**, **Start Revisit** (disabled if Review Bank is empty)

---

### 2. Import Flow

**Step 1 — Capture**
- Tap "Add New List" → camera opens
- User photographs the paper word list
- Option to use an existing photo from the library

**Step 2 — Review & Edit**
- App uses on-device OCR to extract French words
- Extracted words shown as an editable list
- User can:
  - Delete a word (OCR error)
  - Edit a word (OCR error)
  - Add a missing word manually
- Tap **Save List**

**Step 3 — Naming**
- Auto-name: "Liste du [date]"
- User can rename before saving

---

### 3. Practice Session

Triggered from Home by tapping a word list → **Start Practice**.

**Session flow:**

1. Words are shuffled randomly
2. For each word, the app:
   - Plays an audio pronunciation (text-to-speech, French locale)
   - Shows a replay button
   - Shows the word's category hint if available (e.g. *noun*, *verb*) — optional, toggled in settings
   - Presents a text input field
3. Pupil types the spelling and taps **Next** (or presses Return)
4. The app records the answer silently — **no immediate right/wrong feedback**
5. This continues until all words are exhausted

**End of session — Results Screen:**
- Score shown (e.g. "14 / 17 correct")
- Two sections: **Correct** (green) and **Incorrect** (red)
- Each incorrect entry shows: what the pupil typed → correct spelling
- Incorrect words are automatically added to the Review Bank
- If a word was already in the Review Bank and answered correctly here, it is **not** yet removed (only Revisit sessions trigger removal — see below)
- Buttons: **Practice Again**, **Back to Home**

---

### 4. Revisit Session

Triggered from Home → **Start Revisit**.

- Works identically to a Practice Session, but the word pool is drawn from the Review Bank (across all lists)
- Session size: all Review Bank words, or capped at 20 if the bank is large (configurable in settings)
- Words answered **correctly** in this session are removed from the Review Bank
- Words answered **incorrectly** remain in the Review Bank
- End screen shows the same Correct/Incorrect breakdown, plus: "X words removed from your review list"

---

### 5. Word List Detail

Accessible by long-pressing a list on Home.

- View all words in the list
- Each word shows a badge if it is currently in the Review Bank
- Options: **Rename**, **Delete List**, **View Original Photo**

---

## Data Model

| Entity | Fields |
|---|---|
| `WordList` | id, name, createdAt, photoThumbnail, words[] |
| `Word` | id, listId, text, audioLocale |
| `SessionResult` | id, listId, date, answers[] |
| `Answer` | wordId, typed, correct |
| `ReviewBank` | wordId, addedAt, missCount |

---

## Key Design Decisions

**No immediate feedback during a session.** The pupil must commit to their spelling without getting hints partway through — this mirrors a real dictation exam.

**Revisit is the only gate for removing words from the Review Bank.** Getting a word right during a regular Practice Session does not remove it; the pupil must demonstrate recall specifically in a Revisit context.

**OCR is editable before saving.** French accents (é, è, ê, ç, etc.) are error-prone in OCR; the edit step is a first-class part of the import flow, not an afterthought.

**Audio is TTS, French locale.** No network dependency; uses AVSpeechSynthesizer with `fr-FR` voice.

---

## Out of Scope (v1)

- Teacher-side account or sharing
- Syncing across devices
- Handwriting recognition (typed input only)
- Images or illustrations for words
- Translation display
