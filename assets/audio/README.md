# Audio — ToxicHunter

Drop files here with **exactly** these names. Any of `.ogg` (preferred), `.mp3`
or `.wav` works. Open the project in the Godot editor once after adding files
so they get imported. Missing files are fine: music is silent and SFX fall back
to the built-in synthesised sounds.

## Music — `assets/audio/music/`

| File | Plays on | Suggested track (free) |
|---|---|---|
| `bgm_title.ogg` | attach + level select | Kevin MacLeod – *Monkeys Spinning Monkeys* (cheerful, kid-friendly) |
| `bgm_gameplay.ogg` | gameplay | Kevin MacLeod – *Sneaky Snitch* (sneaky pizzicato, Pink Panther feel) |
| `bgm_gameplay_2.ogg` | gameplay (random pick) | Kevin MacLeod – *Spy Glass* or *Hitman* (spy / secret-agent feel) |
| `bgm_gameplay_3.ogg` | gameplay (optional) | Kevin MacLeod – *Investigations* (jazzy detective) |
| `bgm_result.ogg` | summary (optional) | any jingle from Kenney *Music Jingles*; falls back to `bgm_title` |

Music loops automatically.

## Sound effects — `assets/audio/sfx/`

Each file replaces the synthesised cue of the same name.

| File | When | Suggested source (CC0) |
|---|---|---|
| `tap.ogg` | any button click | Kenney *Interface Sounds* – a short click |
| `hover.ogg` | mouse over button / item | Kenney *UI Audio* – soft rollover |
| `correct.ogg` | found a toxic item | Kenney *Interface Sounds* – a "confirmation" chime |
| `wrong.ogg` | picked a safe item | Kenney *Interface Sounds* – a soft "error" |
| `tick.ogg` | last 10 seconds | Kenney *Interface Sounds* – a tick |
| `reveal.ogg` | item card pops up | Kenney *Interface Sounds* – a whoosh / "maximize" |
| `win.ogg` | round finished | Kenney *Music Jingles* – a short win jingle |

Keep SFX short (< 1 s, except `win`) and peak around -6 dB so they sit over the music.

## Licences / credits

* Kevin MacLeod (incompetech.com) tracks are **CC BY 4.0** — credit is required, e.g.
  `"Sneaky Snitch" Kevin MacLeod (incompetech.com) — Licensed under Creative Commons: By Attribution 4.0`
  Put one line per track in the game's credits / README.
* Kenney packs are **CC0** — no credit needed (appreciated).
* Do **not** use the real Pink Panther theme or James Bond theme — both are
  copyrighted and need a paid licence.
