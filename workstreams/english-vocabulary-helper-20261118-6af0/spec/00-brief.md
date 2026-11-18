## Goals

### G-01: New words I meet don't get lost
I come across unfamiliar English words during the day and want them kept in one place with a short meaning and the date. "Better" means: after a lookup the word is already in my vocabulary list without extra effort, and I can re-read the list later. Spaced-repetition quizzes are a later version, out of scope now.

### G-02: I hear how the word sounds in real speech
Reading a gloss isn't enough — I want to hear the word and hear it inside sentences I ran into. "Better" means: pronunciation comes without me clicking anything, and I can paste a few sentences and have them read aloud.

## Functions

### FR-01: Menu bar app with a popover for typing a word
**Goals:** G-01
**Acceptance criteria:**
- the app lives in the macOS menu bar and has no Dock icon or main window
- clicking the menu bar icon opens a popover with an input field focused, ready for typing
- typing a word and pressing Enter starts the lookup
**Owner's words:** A macOS menu bar app. I click its icon and type the word in the popover

### FR-02: Global hotkey on a selected word
**Goals:** G-01
**Acceptance criteria:**
- pressing Option+Shift+D while a word is selected in any app opens the popover with that word already looked up
- the hotkey works when the app is not frontmost
- if nothing is selected, the popover opens with an empty input field
**Owner's words:** select a word in any app and press a global hotkey (Option+Shift+D)

### FR-03: Word card from the online dictionary
**Goals:** G-01
**Acceptance criteria:**
- the card shows, top to bottom: the word, IPA transcription, the short gloss, then meanings grouped by part of speech
- a meaning shows an example sentence when the dictionary response has one, and no empty example line when it doesn't
- the data comes from the Free Dictionary API (dictionaryapi.dev); no API key is needed
**Owner's words:** A word card: the word, IPA transcription, the short gloss on top, then the meanings grouped by part of speech, each with an example when the dictionary has one

### FR-04: Pronunciation plays by itself, with replay
**Goals:** G-02
**Acceptance criteria:**
- when the card appears, the word is spoken once automatically through the macOS built-in voice
- the card has a replay button that speaks the word again
**Owner's words:** Pronunciation plays automatically, with a replay button

### FR-05: Read 1–4 pasted sentences aloud
**Goals:** G-02
**Acceptance criteria:**
- the popover has a separate text field for pasting sentences and a button that reads the pasted text aloud with the macOS built-in voice
- text of up to 4 sentences is read in full, sentence after sentence
- nothing pasted into this field is saved to the vocabulary list
**Owner's words:** The same popover has a field to paste 1-4 sentences and a button to read them aloud.

### FR-06: Automatic save of the full card to a local JSON list
**Goals:** G-01
**Acceptance criteria:**
- as soon as a card is shown, an entry is written to ~/Library/Application Support/EngHelper/vocabulary.json
- the entry holds the word, the short gloss, the date added and the full card data: IPA transcription and the meanings grouped by part of speech with their examples
- the folder ~/Library/Application Support/EngHelper/ is created if it doesn't exist
- the file is valid JSON I can open in any editor
- no save happens unless a card was shown
**Owner's words:** The word is saved automatically when the card is shown

### FR-07: A word already saved isn't duplicated
**Goals:** G-01
**Acceptance criteria:**
- looking up a word that is already in the file shows the card as usual and leaves the file with exactly one entry for that word
- matching ignores case: "Apple" and "apple" are the same entry
- word forms are separate entries: "running" is saved apart from "run"
- the original date added stays unchanged
**Owner's words:** Duplicates are matched ignoring case ("Apple" = "apple"); word forms like "running" are separate words

### FR-08: List view in the app, newest first, cards reopen from the file
**Goals:** G-01
**Acceptance criteria:**
- the app shows the saved words with their glosses, ordered newest first
- clicking a word in the list reopens its full card from the saved entry, with no network request
- the list is otherwise read-only: no editing, deleting or search in this version
**Owner's words:** both: file on disk, plus a view in the app; clicking a word in the list reopens its card from the file, with no network request

### FR-09: Failed lookup saves nothing
**Goals:** G-01
**Acceptance criteria:**
- with no network, the popover shows a short error message and the JSON file is unchanged
- for a word the dictionary doesn't have, the popover shows a short error message and the JSON file is unchanged
- no entry with an empty gloss is ever written
**Owner's words:** show a short error, save nothing

## Context

- Users: only me
- Authorization: none
- Network: yes — HTTP requests to dictionaryapi.dev for lookups; speech is local, so everything except the lookup works offline
- Local system: writes and reads ~/Library/Application Support/EngHelper/vocabulary.json (word, short gloss, date added, IPA, meanings with examples), creating the folder if missing; reads the current text selection from other apps when the hotkey is pressed; uses the macOS built-in speech voice
- Platform: macOS 14+ (menu bar app)
- Other: Built as a Swift Package (macOS 14+), with the lookup parsing, JSON storage and duplicate rules in a library target covered by swift test; network calls are behind a protocol so tests use canned responses. Words arrive two ways: typed by me, or copy-pasted / selected from a browser or subtitles. Spaced repetition is explicitly deferred to a later version. The global hotkey and reading the selection will need macOS Accessibility permission.
