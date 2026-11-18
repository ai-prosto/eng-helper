# Eng Helper

A lightweight macOS menu bar app for learning English vocabulary.
It reads English text aloud, pronounces and explains individual words, and
quizzes you on recently added words with a simple spaced-repetition routine.

> Status: design stage. This README describes the intended behavior and
> architecture; the Xcode project has not been created yet.

## Features

### 1. Speak text
- Read aloud short English passages (1–4 sentences).
- Input via the menu bar popover, or by selecting text in **any** app and
  pressing a global hotkey (default `⌥⇧S`).
- Also available from the macOS **Services** menu (right-click → Services →
  *Speak with Eng Helper*).

### 2. Explain a word
- Select a single word (or type it) and press the hotkey (default `⌥⇧D`).
- A card appears with:
  - pronunciation (played automatically, replay button),
  - IPA transcription,
  - all common meanings grouped by part of speech, each with an example,
  - a short one-line gloss used later in quizzes.
- Every explained word is saved to your vocabulary list.

### 3. Review quizzes
- **Three times a day** (default 09:00, 14:00, 20:00, configurable) the app
  sends a system notification: *"Time to review — 8 words"*.
- Clicking it opens a quiz window built from the **most recently added
  active words** (default set size: 10).
- Each question shows a word (optionally spoken) and **4 definitions**;
  pick the correct one.
- Wrong options are taken from other words in your own vocabulary; the LLM
  generates extra distractors only when the list is too small.
- If the Mac was asleep or you were away, missed sessions collapse into a
  single pending review instead of piling up.

### Repetition rules
| Event | Effect |
|---|---|
| Correct answer | `streak += 1` |
| Wrong answer | `streak = 0` |
| `streak` reaches **5** | word is marked **mastered** and removed from reviews |

Mastered words stay in the history and can be reactivated manually.

## Architecture

```
┌──────────────────────── Eng Helper.app (menu bar, Login Item) ───────────────────────┐
│                                                                                      │
│  UI (SwiftUI)                 Services                       Storage                 │
│  ├─ MenuBarExtra popover      ├─ SpeechService (TTS)         └─ SwiftData / SQLite   │
│  ├─ Word card panel           ├─ DictionaryService             ├─ words              │
│  ├─ Quiz window               │   ├─ dictionaryapi.dev         ├─ reviews            │
│  └─ Settings                  │   └─ LLM (JSON output)         └─ sessions           │
│                               ├─ QuizEngine (SRS rules)                              │
│  Input                        ├─ Scheduler (timers +                                 │
│  ├─ Global hotkeys            │   UNUserNotificationCenter)                          │
│  ├─ Selected-text capture     └─ AudioCache                                          │
│  └─ NSServices provider                                                              │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

No separate daemon: the app itself runs in the background as a Login Item
and owns the review schedule.

### Text-to-speech
- **Default:** `AVSpeechSynthesizer` — free and offline. Download a premium
  English voice (e.g. *Zoe*, *Evan*) in *System Settings → Accessibility →
  Spoken Content* for much better quality.
- **Optional:** cloud TTS (OpenAI `gpt-4o-mini-tts`) for more natural speech.
  Generated audio is cached on disk by text hash.

### Word explanations
- Pronunciation data and IPA from the free
  [Free Dictionary API](https://dictionaryapi.dev/) when available.
- Meanings, examples, and the short quiz gloss from an LLM (OpenAI or
  Anthropic API) using a strict JSON response schema.
- Results are cached in the database; a word is never looked up twice.

Example stored payload:

```json
{
  "word": "serendipity",
  "ipa": "/ˌser.ənˈdɪp.ə.ti/",
  "short_gloss": "finding something good by chance",
  "senses": [
    {
      "pos": "noun",
      "definition": "The occurrence of fortunate events by chance.",
      "example": "Meeting her there was pure serendipity."
    }
  ]
}
```

### Data model

| Entity | Fields |
|---|---|
| `Word` | `id`, `text` (unique), `payload` (JSON), `addedAt`, `streak`, `status` (`active` \| `mastered`) |
| `Review` | `wordId`, `answeredAt`, `correct` |
| `Session` | `id`, `scheduledAt`, `completedAt` |

### Selected-text capture
The global hotkey reads the current selection via the Accessibility API
(`AXSelectedText`), falling back to a simulated `⌘C` with clipboard restore.
This requires granting Accessibility permission on first launch.

## Requirements
- macOS 14 (Sonoma) or later
- Xcode 16+, Swift 5.10+
- API key for the LLM provider (stored in the Keychain)
- Optional: API key for cloud TTS

## Permissions
- **Accessibility** — to read selected text in other apps.
- **Notifications** — for review reminders.
- **Network** — dictionary and LLM requests.

## Settings
- Hotkeys for *Speak* and *Explain*
- Voice and speech rate; TTS engine (system / cloud)
- Review times (default 09:00 / 14:00 / 20:00)
- Quiz set size (default 10)
- Mastery threshold (default 5 correct in a row)
- LLM provider and API key
- Launch at login

## Roadmap
1. Menu bar shell, `AVSpeechSynthesizer` playback, text input
2. Word lookup (dictionary API + LLM), word card, persistence
3. Global hotkeys and selected-text capture; Services menu
4. Quiz engine and repetition rules
5. Scheduler with notifications and missed-session handling
6. Cloud TTS with audio cache; settings window
7. Stats view (words added, mastered, accuracy)

## License
TBD
