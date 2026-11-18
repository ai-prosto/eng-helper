# Manual checks — global hotkey and selection capture (TASK-004)

Build and install first:

```sh
./Scripts/make-app.sh
open /Applications/EngHelper.app
```

## Accessibility grant (one-time setup, design D-08)

1. With EngHelper freshly installed, press Option+Shift+D anywhere.
2. **Expect:** macOS shows its Accessibility prompt (first use only),
   and the popover opens with the one-line hint
   `Selection capture needs Accessibility access.` plus an
   `Open Settings` button.
3. Click the button.
4. **Expect:** System Settings opens on Privacy & Security →
   Accessibility. Enable EngHelper there.
5. **Expect:** typed lookups in the popover work even before the
   grant is given.

After granting, quit and relaunch EngHelper once, then run the checks
below. Rebuilding the app (`make-app.sh`) keeps the grant — the bundle
is ad-hoc signed with a stable identity.

## BEH-20: Option+Shift+D looks up the selected word

1. Open TextEdit, type a word (e.g. `serendipity`) and double-click it
   so it is selected.
2. Press Option+Shift+D.
3. **Expect:** the EngHelper popover opens with `serendipity` already
   in the word field and its card shown — word, IPA, gloss, meanings.
4. **Expect:** the word landed in
   `~/Library/Application Support/EngHelper/vocabulary.json`.

- [ ] PASS

## BEH-21: The hotkey works while the app is in the background

1. Open Safari and bring it frontmost; do not click the EngHelper icon
   — EngHelper stays in the background.
2. Select a word in a web page and press Option+Shift+D.
3. **Expect:** the popover appears with that word looked up and its
   card shown.
4. **Expect:** the clipboard still holds whatever it held before the
   keystroke (the copy fallback restores it).

- [ ] PASS

## BEH-22: The hotkey with no selection opens an empty field

1. Click an empty area of the desktop or a document so nothing is
   selected.
2. Press Option+Shift+D.
3. **Expect:** the popover opens with an empty word field, already
   focused — typing lands in it immediately.
4. **Expect:** no loading spinner, no card and no error line appear —
   no lookup was started.

- [ ] PASS

## Result

All three checks green → the TASK-004 group check passes.
