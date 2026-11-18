# Manual checks — speech: pronunciation, replay, sentences (TASK-005)

Build and install first:

```sh
./Scripts/make-app.sh
open /Applications/EngHelper.app
```

Turn the system sound on and set the output volume where you can hear
it. Speech uses the built-in macOS voice — no network is needed for
any check below.

## BEH-24: The word is spoken once when the card appears

1. Click the menu bar icon, type a word (e.g. `serendipity`) and press
   Enter.
2. **Expect:** as soon as the card appears, the macOS voice says the
   word once — without clicking anything.
3. Leave the card on screen, move the mouse over the popover, resize
   nothing, just wait a few seconds.
4. **Expect:** the word is not repeated while the card stays on
   screen.
5. Click a word in the saved list.
6. **Expect:** that word is spoken once as its card opens.

- [ ] PASS

## BEH-25: The replay button speaks the word again

1. With a card on screen, press the ↻ button next to the word.
2. **Expect:** the same word is spoken again, once.
3. Press ↻ twice more, letting each finish.
4. **Expect:** one pronunciation per press — two more, no extras.
5. Look up a longer word (e.g. `incomprehensibility`) and press ↻
   again while the voice is still mid-word.
6. **Expect:** the pronunciation restarts from the beginning — no
   overlap, and no second playback queued after the first.

- [ ] PASS

## BEH-26: The sentences field reads pasted text aloud and saves nothing

1. Note the current contents of
   `~/Library/Application Support/EngHelper/vocabulary.json`
   (or that it does not exist yet).
2. Paste four sentences into the Sentences field, e.g.:
   `It was late. The rain had stopped. A door opened somewhere.
   Nobody came in.`
3. Press `Read aloud`.
4. **Expect:** all four sentences are spoken, one after another, to
   the end of the text.
5. Open `vocabulary.json` again.
6. **Expect:** it is unchanged — no entry came from the sentences
   text.

- [ ] PASS

## Result

All three checks green → together with
`SentenceSplitterTests.testSplitsUpToFourSentencesInOrder` the
TASK-005 group check passes.
