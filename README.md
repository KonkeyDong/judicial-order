# judicial-order

A Shining Force-inspired game written in Odin.

Made for education, not selling purposes. Gameplay is implemented without Unity, Godot, or any other engine. See the state machine diagram in `/State` for how the game flows. If you are lost, start with `/State/EndTurn.cs`.

## Run the Program

```bash
odin run src
odin run src -- --help
odin run src -- --logger debug
odin run src -- --sprite-demo
```

`-h` / `--help` prints the options and exits.

`--logger` / `-l` / `-d` set the log level: `debug`, `info` (default), `warning`, `error`, `fatal`. `--logger=LEVEL` is the same option.

`--sprite-demo` opens a sprite viewer on a gray checker, so transparent pixels stay visible. The Characters menu lists each battle sprite, and the Animation menu chooses Idle or Attack. The chosen sheet loops in the center. Sara’s idle sheet is the default. The flag can be combined with `--logger`.

## Controls

* Arrow keys to move/select.
* `Z`, `C` to select; `X` to cancel.
* `F1` toggles debug log level (and debug overlays).
* `Ctrl` + `+` / `-` to resize the window.
