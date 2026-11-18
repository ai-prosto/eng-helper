# EngHelper — design

A macOS menu bar app with one popover: type or capture a word, see its card,
hear it, keep it in a local JSON list. Built as a Swift Package: all logic that
can be tested without a UI lives in a library target, the menu bar shell is a
thin executable.

## Structure

### Package

```
Package.swift                    // platforms: [.macOS(.v14)]
Sources/
  EngHelperKit/                  // library target — unit-tested
    Models/
      WordCard.swift             // WordCard, Meaning, Definition
      VocabularyEntry.swift      // Codable on-disk entry
    Lookup/
      DictionaryTransport.swift  // protocol: fetch(word) async throws -> Data
      FreeDictionaryClient.swift // URLSession implementation
      DictionaryDTO.swift        // Decodable mirror of dictionaryapi.dev JSON
      WordCardParser.swift       // DTO -> WordCard
      LookupError.swift          // offline / notFound / badResponse
      WordLookup.swift           // transport + parser -> WordCard
    Storage/
      StoragePaths.swift         // ~/Library/Application Support/EngHelper
      VocabularyStore.swift      // load, saveIfNew, entries(newestFirst:)
      AtomicWrite.swift          // temp file + rename
    Speech/
      Speaking.swift             // protocol: speak(text), speakSequence([String])
      SentenceSplitter.swift     // text -> [String]
  EngHelperApp/                  // executable target — AppKit + SwiftUI shell
    main.swift                   // NSApplication, .accessory policy
    AppDelegate.swift
    StatusItemController.swift   // NSStatusItem + NSPopover
    HotKeyMonitor.swift          // Carbon RegisterEventHotKey
    SelectionReader.swift        // Accessibility selected text
    SystemSpeaker.swift          // AVSpeechSynthesizer: Speaking
    PopoverModel.swift           // @MainActor ObservableObject, state machine
    UI/
      PopoverRootView.swift
      WordCardView.swift
      SentencesView.swift
      VocabularyListView.swift
Tests/EngHelperKitTests/
  WordCardParserTests.swift      // canned dictionaryapi.dev payloads
  VocabularyStoreTests.swift     // temp-directory stores
  SentenceSplitterTests.swift
  Fixtures/*.json
Scripts/make-app.sh              // wrap binary into EngHelper.app
```

### Commands

- `swift build` / `swift test` — build and run the library tests.
- `./Scripts/make-app.sh` — produce `EngHelper.app` (release binary +
  `Info.plist` with `LSUIElement=1`, ad-hoc signed) and copy it to
  `/Applications`. This is how the app is actually run.

### Data

One file, `~/Library/Application Support/EngHelper/vocabulary.json`: a JSON
array of entries, newest appended at the end, pretty-printed.

```json
[
  {
    "word": "serendipity",
    "key": "serendipity",
    "gloss": "the occurrence and development of events by chance in a happy way",
    "dateAdded": "2026-11-18T09:14:03Z",
    "ipa": "/ˌsɛɹənˈdɪpɪti/",
    "meanings": [
      {
        "partOfSpeech": "noun",
        "definitions": [
          { "definition": "The occurrence of a fortunate discovery by accident.",
            "example": "A fortunate stroke of serendipity brought them together." },
          { "definition": "An unsought, unintended discovery." }
        ]
      }
    ]
  }
]
```

`example` is absent when the dictionary had none; `key` is the lowercased word
used for duplicate matching; `ipa` may be absent when the API returns no
phonetic text.

### Flow

`PopoverModel` holds `phase: .idle | .loading | .card(WordCard) | .error(String)`
plus the independent `sentencesText`. Lookup path: input (typed Enter, or hotkey
selection) → `WordLookup.card(for:)` → on success `phase = .card`, and the same
transition calls `VocabularyStore.saveIfNew(card)` and `speaker.speak(word)`
once → `WordCardView` renders. On failure `phase = .error`, nothing is written
or spoken. List path: tap entry → `phase = .card(entry.card)` with no transport
call; the save step is skipped because the entry is already the source.

## Decisions

#### D-01: Swift Package with a tested library target and a thin app target
`EngHelperKit` holds parsing, storage, duplicate rules and sentence splitting;
`EngHelperApp` holds only AppKit/SwiftUI/AVFoundation glue. Logic is reachable
from `swift test` without launching a UI, as the brief requires.
**Functions:** FR-01, FR-02, FR-03, FR-04, FR-05, FR-06, FR-07, FR-08, FR-09

#### D-02: Platform — macOS 14+, shipped as an LSUIElement .app bundle
`Package.swift` pins `.macOS(.v14)`. A bare SwiftPM executable has no bundle, so
`Scripts/make-app.sh` wraps it in `EngHelper.app` with `LSUIElement=1` and an
ad-hoc signature; this also gives the app a stable identity so the
Accessibility grant persists across launches. `main.swift` additionally calls
`setActivationPolicy(.accessory)`, so there is no Dock icon and no main window.
**Functions:** FR-01, FR-02

#### D-03: NSStatusItem + NSPopover, not SwiftUI MenuBarExtra
The hotkey must open the popover while the app is in the background, and macOS 14
has no public API to open a `MenuBarExtra` programmatically. `StatusItemController`
owns an `NSStatusItem` whose button toggles an `NSPopover` containing an
`NSHostingView(rootView: PopoverRootView())`, and exposes `show(prefill:)` for
the hotkey path.
**Functions:** FR-01, FR-02

#### D-04: One popover, three stacked zones
`PopoverRootView` is a fixed-width VStack: the word field with the card or error
below it, a divider, the sentences zone, a divider, the saved-words list (the
list scrolls, the popover height stays bounded). Everything the brief asks for
lives in the same popover.
**Functions:** FR-01, FR-03, FR-05, FR-08

#### D-05: Input focus and Enter wiring
The word field uses `@FocusState` set true in `onAppear`, and
`StatusItemController` calls `makeFirstResponder` on the hosting view when the
popover is shown, so the field is ready for typing on every open. `onSubmit`
starts the lookup, so Enter is the only needed gesture.
**Functions:** FR-01

#### D-06: Carbon RegisterEventHotKey for Option+Shift+D
`HotKeyMonitor` registers `kVK_ANSI_D` with `optionKey|shiftKey` through
`RegisterEventHotKey`. It is system-wide and fires regardless of which app is
frontmost, and unlike a CGEvent tap it needs no extra permission of its own.
**Functions:** FR-02

#### D-07: Selection read via Accessibility, with a copy fallback
`SelectionReader.selectedText()` asks the system-wide `AXUIElement` for
`kAXFocusedUIElement` and its `kAXSelectedTextAttribute`; if that is unavailable
(many browsers and video players) it synthesizes ⌘C, reads
`NSPasteboard.general`, and restores the previous pasteboard contents. Whitespace-
trimmed empty result → the popover opens with an empty field, no lookup.
**Functions:** FR-02

#### D-08: Authorization — none in the app, one OS permission prompt
There are no accounts, logins or tokens anywhere; the dictionary API needs no
key. The only gate is macOS Accessibility: on first hotkey use the app calls
`AXIsProcessTrustedWithOptions` with the prompt option, and the popover shows a
one-line hint with a button opening the Privacy & Security pane when the grant
is missing. Typed lookups work without it.
**Functions:** FR-02

#### D-09: Network — Free Dictionary API behind a transport protocol
`FreeDictionaryClient` does a plain `URLSession` GET to
`https://api.dictionaryapi.dev/api/v2/entries/en/<percent-encoded word>` with a
10-second timeout and no key, no headers identifying me. It conforms to
`DictionaryTransport`, so tests inject canned fixture bytes. This is the only
network call in the project; speech, storage and the list never touch the
network.
**Functions:** FR-03, FR-09

#### D-10: Parser maps the API payload to a WordCard
`WordCardParser` decodes the array of entries and merges them into one
`WordCard`: `ipa` = first non-empty `phonetic`/`phonetics[].text`; `gloss` =
first definition text of the first meaning; `meanings` = definitions grouped by
`partOfSpeech` in first-seen order, each definition carrying `example: String?`
left nil when the response has none or it is blank. Grouping and gloss choice
are pure functions, so fixtures pin them in tests.
**Functions:** FR-03

#### D-11: Card view renders the brief's order and omits absent examples
`WordCardView` lays out, top to bottom: word, IPA, gloss, then a section per
part of speech with its numbered definitions. The example `Text` is inside
`if let example`, so a definition without one renders no empty line.
**Functions:** FR-03

#### D-12: Speech through AVSpeechSynthesizer with the system voice
`SystemSpeaker` conforms to `Speaking` and uses `AVSpeechSynthesizer` with
`AVSpeechSynthesisVoice(language:)` for the system's English locale — the
built-in macOS voice, fully local and offline. The `.card` transition speaks the
word once (guarded by a flag per presentation, so re-renders don't repeat it),
and the card's ↻ replay button calls the same `speak(word)`.
**Functions:** FR-04

#### D-13: Sentences zone is speech-only and never reaches storage
`SentencesView` holds a multi-line `TextEditor` bound to
`PopoverModel.sentencesText` and a "Read aloud" button. The button runs
`SentenceSplitter.split` (NaturalLanguage `NLTokenizer` at `.sentence` unit) and
enqueues one `AVSpeechUtterance` per sentence, so the whole text is read
sentence after sentence to the end. This state is separate from the lookup phase
and no code path passes it to `VocabularyStore`.
**Functions:** FR-05

#### D-14: Storage — one pretty-printed JSON array, written atomically
`StoragePaths` resolves `~/Library/Application Support/EngHelper/` via
`FileManager.url(for: .applicationSupportDirectory, create: true)` and creates
it with `createDirectory(withIntermediateDirectories: true)` if missing.
`VocabularyStore` encodes `[VocabularyEntry]` with
`.prettyPrinted + .sortedKeys + .withoutEscapingSlashes` and ISO-8601 dates, and
writes via temp file + `replaceItemAt`, so the file on disk is always valid JSON
openable in any editor.
**Functions:** FR-06

#### D-15: The save is bound to card presentation
`PopoverModel` calls `store.saveIfNew(card)` inside the single transition that
sets `phase = .card(card)` for a fresh lookup. There is no other write path, so
a lookup that never produced a card cannot write, and the entry stores word,
gloss, `dateAdded = Date()`, IPA and the full grouped meanings with examples —
the same data the card showed.
**Functions:** FR-06, FR-09

#### D-16: Duplicates matched on the lowercased word, no stemming
`VocabularyEntry.key = word.lowercased()` (after whitespace trimming);
`saveIfNew` looks for an existing entry with the same key. If found it keeps
that entry's `dateAdded` and its position, refreshing only the card payload; if
not, it appends. No lemmatization anywhere, so "running" and "run" have
different keys and stay separate entries, while "Apple" and "apple" collapse to
exactly one.
**Functions:** FR-07

#### D-17: List is newest-first, read-only, and reopens cards offline
`VocabularyListView` shows `store.entries(newestFirst: true)` — sorted by
`dateAdded` descending with later array position breaking ties — as word plus
gloss. Tapping a row sets `phase = .card(entry.card)` built from the stored
fields, with no transport call. The view offers no edit, delete or search
affordance in this version.
**Functions:** FR-08

#### D-18: Failures are short messages and nothing else
`WordLookup` maps `URLError.notConnectedToInternet`/`cannotFindHost` to
`.offline`, HTTP 404 or an unparseable/empty-definition payload to `.notFound`,
anything else to `.badResponse`; a parsed card whose gloss is empty after
trimming is also `.notFound`, so no entry with an empty gloss can be written.
`PopoverModel` renders one line — "No network — try again", "No dictionary entry
for 'x'" — and never calls the store or the speaker on this path.
**Functions:** FR-09

#### D-19: Tests use canned responses and temp-directory stores
`FakeTransport` returns fixture bytes or a thrown error, so parser, gloss/IPA
choice, example omission, duplicate and date-preservation rules, newest-first
ordering, sentence splitting and the "failure writes nothing" rule are all
covered by `swift test` with no network and no touching of the real Application
Support folder (`VocabularyStore` takes its directory as an init parameter).
**Functions:** FR-03, FR-05, FR-06, FR-07, FR-08, FR-09

#### D-20: Users — single local user, no multi-user machinery
One person on one Mac: no accounts, profiles, sync, export or migration; the
vocabulary file sits in the user's own Library with default permissions and the
app keeps no other state. This is why a single JSON array read fully into
memory is enough.
**Functions:** FR-06, FR-08

## Open questions

- Which English voice and locale when the Mac has several installed — the design
  takes the system locale's default voice; a fixed choice (e.g. en-US Samantha)
  would be more predictable.
- On re-lookup of a word already in the file, D-16 keeps `dateAdded` and refreshes
  the stored card payload. Leaving the old entry completely untouched would also
  satisfy FR-07 — which is wanted?
- The brief sizes the sentences field at 1–4 sentences; the design reads whatever
  is pasted in full rather than truncating or refusing longer text. Is a visible
  limit wanted?
- How long the saved list may grow before the popover list needs paging or a
  height cap beyond plain scrolling.
