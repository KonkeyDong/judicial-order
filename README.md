# judicial-order

A Shining Force-inspired game written in Odin.

Made for education, not selling purposes. Gameplay is implemented without Unity, Godot, or any other engine. See the state machine diagram in `/State` for how the game flows. If you are lost, start with `/State/EndTurn.cs`.

## Run the Program

```bash
odin run src
odin run src -- --logger debug
```

`--logger` / `-l` / `-d` set the log level: `debug`, `info` (default), `warning`, `error`.

## Controls

* Arrow keys to move/select.
* `Z`, `C` to select; `X` to cancel.
* `F1` toggles debug log level (and debug overlays).
* `Ctrl` + `+` / `-` to resize the window.
