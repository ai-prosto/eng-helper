## Checks

#### BEH-01: Parser builds a word card with IPA, gloss and meanings grouped by part of speech
Feed a canned dictionaryapi.dev payload to the parser. The resulting card carries the word,
the first non-empty phonetic text as IPA, the first definition of the first meaning as gloss,
and definitions grouped by part of speech in first-seen order.
- **checked_by**: `kind: pytest` `target: Tests/EngHelperKitTests/WordCardParserTests.swift::testBuildsCardWithIPAGlossAndGroupedMeanings`
**Criteria:** FR-03/1

#### BEH-02: Examples are kept when the payload has them and left absent when it doesn't
Parse a payload where some definitions have an example and others have none or a blank one.
Definitions with an example expose its text; the rest expose no example at all.
- **checked_by**: `kind: pytest` `target: Tests/EngHelperKitTests/WordCardParserTests.swift::testExamplePresentOnlyWhenPayloadHasOne`
**Criteria:** FR-03/2

#### BEH-03: The lookup requests dictionaryapi.dev with no API key
Ask the Free Dictionary client to fetch a word and inspect the request it would send: a GET to
`https://api.dictionaryapi.dev/api/v2/entries/en/<percent-encoded word>` with no key, token or
identifying header.
- **checked_by**: `kind: pytest` `target: Tests/EngHelperKitTests/WordLookupTests.swift::testRequestsFreeDictionaryURLWithoutKey`
**Criteria:** FR-03/3

#### BEH-04: Lookup failures become distinct offline / not-found / bad-response errors
Run the lookup with a fake transport that throws a no-connection error, then one that returns
HTTP 404, then one that returns unparseable bytes. Each produces the matching lookup error and
no card.
- **checked_by**: `kind: pytest` `target: Tests/EngHelperKitTests/WordLookupTests.swift::testMapsTransportFailuresToLookupErrors`
**Criteria:** FR-09/1, FR-09/2

#### BEH-05: A payload with no usable gloss is treated as not found
Run the lookup against a payload whose definitions are empty or blank. The lookup raises the
not-found error instead of returning a card with an empty gloss.
- **checked_by**: `kind: pytest` `target: Tests/EngHelperKitTests/WordLookupTests.swift::testEmptyGlossPayloadIsNotFound`
**Criteria:** FR-09/3

#### BEH-06: Saving a card writes vocabulary.json and creates the folder when missing
Point the store at a temp directory that does not exist yet and save a card. The EngHelper
folder is created and the entry lands in `vocabulary.json` inside it; the same resolution is
used for `~/Library/Application Support/EngHelper/`.
- **checked_by**: `kind: pytest` `target: Tests/EngHelperKitTests/VocabularyStoreTests.swift::testCreatesFolderAndWritesVocabularyFile`
**Criteria:** FR-06/1, FR-06/3

#### BEH-07: The saved entry holds the whole card
Save a card with IPA and several parts of speech, reload the file and compare: the entry holds
the word, the short gloss, a date added, the IPA transcription and the meanings grouped by part
of speech with their examples.
- **checked_by**: `kind: pytest` `target: Tests/EngHelperKitTests/VocabularyStoreTests.swift::testEntryStoresWordGlossDateIPAAndMeanings`
**Criteria:** FR-06/2

#### BEH-08: The file on disk is valid, readable JSON
After two saves, decode the raw file bytes with a plain JSON decoder: it parses as a
pretty-printed JSON array of entries, as an editor would show it.
- **checked_by**: `kind: pytest` `target: Tests/EngHelperKitTests/VocabularyStoreTests.swift::testFileIsValidPrettyPrintedJSONArray`
**Criteria:** FR-06/4

#### BEH-09: A failed lookup leaves the file untouched
With one entry already saved, run a lookup that fails (no connection, then unknown word) and
follow the success-only save path. The file bytes are unchanged and no entry with an empty
gloss appears.
- **checked_by**: `kind: pytest` `target: Tests/EngHelperKitTests/VocabularyStoreTests.swift::testFailedLookupWritesNothing`
**Criteria:** FR-06/5, FR-09/1, FR-09/2, FR-09/3

#### BEH-10: A word already saved stays one entry, matched ignoring case, with its first date
Save "Apple", then save "apple" again later. The file holds exactly one entry for it and the
original date added is unchanged.
- **checked_by**: `kind: pytest` `target: Tests/EngHelperKitTests/VocabularyStoreTests.swift::testCaseInsensitiveDuplicateKeepsOneEntryAndFirstDate`
**Criteria:** FR-07/1, FR-07/2, FR-07/4

#### BEH-11: Word forms are separate entries
Save "run" and then "running". Both are present as two independent entries.
- **checked_by**: `kind: pytest` `target: Tests/EngHelperKitTests/VocabularyStoreTests.swift::testWordFormsAreSeparateEntries`
**Criteria:** FR-07/3

#### BEH-12: Entries come back newest first with their glosses
Save three cards with increasing dates and ask the store for its entries newest first. They
arrive in reverse date order, each carrying its word and gloss.
- **checked_by**: `kind: pytest` `target: Tests/EngHelperKitTests/VocabularyStoreTests.swift::testEntriesNewestFirst`
**Criteria:** FR-08/1

#### BEH-13: A stored entry rebuilds its full card without any transport call
Save a card, reload the store from disk with a transport that fails if used, and rebuild the
card from the entry. The card matches the saved one and the transport was never called.
- **checked_by**: `kind: pytest` `target: Tests/EngHelperKitTests/VocabularyStoreTests.swift::testEntryRebuildsCardWithoutNetwork`
**Criteria:** FR-08/2

#### BEH-14: The app lives in the menu bar only
Launch the built EngHelper.app. An icon appears in the menu bar, while the Dock shows no icon
and no window opens.
- **checked_by**: `kind: manual` `target: docs/manual/popover-checks.md`
**Criteria:** FR-01/1

#### BEH-15: Clicking the icon opens a popover ready for typing
Click the menu bar icon. The popover opens with the word field focused, so typed characters go
straight into it without clicking first.
- **checked_by**: `kind: manual` `target: docs/manual/popover-checks.md`
**Criteria:** FR-01/2

#### BEH-16: Typing a word and pressing Enter looks it up and saves it
Type "serendipity" and press Enter. The lookup runs, the card appears, and the entry is in
`~/Library/Application Support/EngHelper/vocabulary.json`.
- **checked_by**: `kind: manual` `target: docs/manual/popover-checks.md`
**Criteria:** FR-01/3, FR-06/1

#### BEH-17: The card reads word, IPA, gloss, then meanings per part of speech
Look up a word whose entry mixes definitions with and without examples. The card shows word,
IPA, gloss, then a section per part of speech; definitions without an example show no empty
example line.
- **checked_by**: `kind: manual` `target: docs/manual/popover-checks.md`
**Criteria:** FR-03/1, FR-03/2

#### BEH-18: Failures show one short line and change nothing
With Wi-Fi off look up a word, then with Wi-Fi on look up "qwertyx". Each time the popover
shows a short error line instead of a card, and `vocabulary.json` is byte-identical afterwards.
- **checked_by**: `kind: manual` `target: docs/manual/popover-checks.md`
**Criteria:** FR-09/1, FR-09/2

#### BEH-19: The saved list shows words newest first and reopens cards offline
With several words saved and Wi-Fi off, open the popover: the list shows words with glosses,
newest at the top; clicking one reopens its full card; the list offers no edit, delete or
search control.
- **checked_by**: `kind: manual` `target: docs/manual/popover-checks.md`
**Criteria:** FR-08/1, FR-08/2, FR-08/3

#### BEH-20: Option+Shift+D looks up the selected word
Select a word in TextEdit and press Option+Shift+D. The popover opens with that word already
looked up and its card shown.
- **checked_by**: `kind: manual` `target: docs/manual/hotkey-checks.md`
**Criteria:** FR-02/1

#### BEH-21: The hotkey works while the app is in the background
With Safari frontmost and EngHelper not activated, select a word in a page and press
Option+Shift+D. The popover appears with the word looked up.
- **checked_by**: `kind: manual` `target: docs/manual/hotkey-checks.md`
**Criteria:** FR-02/2

#### BEH-22: The hotkey with no selection opens an empty field
Click an empty area so nothing is selected and press Option+Shift+D. The popover opens with an
empty, focused word field and no lookup is started.
- **checked_by**: `kind: manual` `target: docs/manual/hotkey-checks.md`
**Criteria:** FR-02/3

#### BEH-23: Pasted text splits into its sentences, in order, in full
Split a four-sentence text with the sentence splitter. It returns four non-empty sentences in
reading order covering the whole text, and a single sentence returns one piece.
- **checked_by**: `kind: pytest` `target: Tests/EngHelperKitTests/SentenceSplitterTests.swift::testSplitsUpToFourSentencesInOrder`
**Criteria:** FR-05/2

#### BEH-24: The word is spoken once when the card appears
Look up a word with the sound on. The macOS voice says it once, without clicking anything, and
it is not repeated while the card stays on screen.
- **checked_by**: `kind: manual` `target: docs/manual/speech-checks.md`
**Criteria:** FR-04/1

#### BEH-25: The replay button speaks the word again
Press the replay button on a shown card. The same word is spoken again, each press once.
- **checked_by**: `kind: manual` `target: docs/manual/speech-checks.md`
**Criteria:** FR-04/2

#### BEH-26: The sentences field reads pasted text aloud and saves nothing
Paste four sentences into the sentences field and press "Read aloud". All four are spoken, one
after another to the end, and `vocabulary.json` has no entry from this text.
- **checked_by**: `kind: manual` `target: docs/manual/speech-checks.md`
**Criteria:** FR-05/1, FR-05/3

## Tasks

#### DT-01: Package skeleton and the dictionary lookup core · type: implement · owner: dev
scenarios: [BEH-01, BEH-02, BEH-03, BEH-04, BEH-05]
depends_on: []
parallel_group: solo
**Design decisions:** D-01, D-09, D-10, D-18, D-19
Create the Swift Package pinned to macOS 14 with the `EngHelperKit` library target: card models,
the transport protocol, the Free Dictionary client, the DTO, the parser, the lookup errors and
`WordLookup`. Tests use the fake transport and JSON fixtures; no storage, speech or UI here.

#### DT-02: Vocabulary storage, duplicate rules and list ordering · type: implement · owner: dev
scenarios: [BEH-06, BEH-07, BEH-08, BEH-09, BEH-10, BEH-11, BEH-12, BEH-13]
depends_on: [DT-01]
parallel_group: solo
**Design decisions:** D-14, D-15, D-16, D-17, D-19, D-20
Add the `Storage` part of the kit: the Application Support path resolution, the Codable entry
with its lowercased key, atomic pretty-printed JSON writes, `saveIfNew` with date preservation,
`entries(newestFirst:)` and rebuilding a card from an entry. The store takes its directory as a
parameter so tests stay in temp folders.

#### DT-03: Menu bar shell with the popover, card, error and list zones · type: implement · owner: dev
scenarios: [BEH-14, BEH-15, BEH-16, BEH-17, BEH-18, BEH-19]
depends_on: [DT-01, DT-02]
parallel_group: solo
**Design decisions:** D-02, D-03, D-04, D-05, D-11, D-15, D-17, D-18
Build the `EngHelperApp` target: accessory-policy app, status item with the popover, the stacked
word / sentences / list layout, focused field with Enter submit, card and one-line error views,
the read-only newest-first list reopening stored cards, the save bound to the card transition,
and `Scripts/make-app.sh` producing the LSUIElement bundle.

#### DT-04: Global hotkey, selection capture and the Accessibility grant · type: implement · owner: dev
scenarios: [BEH-20, BEH-21, BEH-22]
depends_on: [DT-03]
parallel_group: solo
**Design decisions:** D-06, D-07, D-08
Register Option+Shift+D through Carbon, read the focused element's selected text with the
pasteboard fallback, and show the popover prefilled — empty field and no lookup when the
selection is blank. Prompt for Accessibility on first use and show the hint with the Privacy
pane button when the grant is missing.

#### DT-05: Speech: automatic word pronunciation, replay and the sentences zone · type: implement · owner: dev
scenarios: [BEH-23, BEH-24, BEH-25, BEH-26]
depends_on: [DT-03]
parallel_group: solo
**Design decisions:** D-12, D-13, D-19
Add the sentence splitter to the kit and the system speaker to the app: speak the word once per
card presentation, wire the replay button to the same call, and read the sentences field aloud
sentence after sentence. This zone never reaches the store.
