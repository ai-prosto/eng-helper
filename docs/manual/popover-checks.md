# Manual checks — menu bar shell and popover (TASK-003)

Build and install first:

```sh
./Scripts/make-app.sh
open /Applications/EngHelper.app
```

The vocabulary file referred to below is
`~/Library/Application Support/EngHelper/vocabulary.json`.

## BEH-14: The app lives in the menu bar only

1. Launch `/Applications/EngHelper.app`.
2. **Expect:** a book icon appears in the menu bar.
3. **Expect:** the Dock shows no EngHelper icon and no window opens.

- [ ] PASS

## BEH-15: Clicking the icon opens a popover ready for typing

1. Click the menu bar icon.
2. **Expect:** a popover opens under the icon.
3. Without clicking anything, type a few letters.
4. **Expect:** the characters land in the word field — it was already
   focused.

- [ ] PASS

## BEH-16: Typing a word and pressing Enter looks it up and saves it

1. Open the popover, type `serendipity`, press Enter.
2. **Expect:** a brief loading state, then the word card appears.
3. Open the vocabulary file in a text editor.
4. **Expect:** it contains an entry for `serendipity` with gloss, date,
   IPA and meanings.

- [ ] PASS

## BEH-17: The card reads word, IPA, gloss, then meanings per part of speech

1. Look up a word whose entry mixes definitions with and without
   examples (e.g. `bank` or `run`).
2. **Expect:** from top to bottom: the word, its IPA, the short gloss,
   then one section per part of speech with numbered definitions.
3. **Expect:** definitions that have an example show it in quotes;
   definitions without one show no empty example line.

- [ ] PASS

## BEH-18: Failures show one short line and change nothing

1. Note the current contents (or modification time) of the vocabulary
   file.
2. Turn Wi-Fi off and look up any word.
3. **Expect:** one short line — `No network — try again` — and no card.
4. Turn Wi-Fi on and look up `qwertyx`.
5. **Expect:** one short line — `No dictionary entry for “qwertyx”` —
   and no card.
6. **Expect:** the vocabulary file is byte-identical to before (same
   contents, unchanged modification time).

- [ ] PASS

## BEH-19: The saved list shows words newest first and reopens cards offline

1. Save several words (e.g. `apple`, then `river`, then `cloud`), then
   turn Wi-Fi off.
2. Close and reopen the popover.
3. **Expect:** the saved list shows each word with its gloss, newest at
   the top (`cloud`, `river`, `apple`).
4. Click one of the rows.
5. **Expect:** its full card opens instantly, with Wi-Fi still off.
6. **Expect:** the list offers no edit, delete or search control.

- [ ] PASS

## Result

All six checks green → the TASK-003 group check passes.
