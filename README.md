# Sudoku

A fully accessible, single-file Sudoku web game. The entire application — HTML, CSS, and JavaScript — lives in `sudoku.html` with zero dependencies and no build step.

## Features

- **Puzzle generator** — Generates puzzles with a guaranteed unique solution, backed by a backtracking solver.
- **Three difficulty levels** — Easy, Medium, and Hard, controlled by the number of given cells.
- **Notes (pencil marks)** — Add candidate digits to a cell; placing a digit auto-clears related notes in the same row, column, and box.
- **Conflict detection** — Duplicate digits in a row, column, or box are highlighted in real time.
- **Cell highlighting** — The selected cell, its related cells (row/column/box), and matching digits are visually emphasized.
- **Undo** — Step back through the last 20 actions.
- **Timer with pause** — Automatically pauses when you switch tabs or press Pause.
- **Auto-save** — In-progress games are stored in `localStorage` and restored on reload.
- **Digit counts** — Each number on the pad shows how many of that digit are placed (e.g. `4/9`) and disables when all nine are used.
- **Win detection** — Validates the completed board against the solution and shows a completion dialog with your time.

## Accessibility

- Full keyboard play, including arrow-key grid navigation.
- ARIA grid roles, per-cell accessible labels, and a live-region announcer for state changes.
- Respects `prefers-color-scheme` (light/dark) and `prefers-reduced-motion`.
- Visible focus rings and touch targets sized at a minimum of 44×44px.

## Getting Started

No installation or build is required. Open the file directly:

```bash
# Open in your default browser
open sudoku.html        # macOS
xdg-open sudoku.html    # Linux
start sudoku.html       # Windows
```

Or serve it locally if you prefer:

```bash
python3 -m http.server 8000
# then visit http://localhost:8000/sudoku.html
```

## How to Play

The goal of Sudoku is to fill the 9×9 grid so that every row, every column, and
each of the nine 3×3 boxes contains the digits 1 through 9 exactly once.

### Controls

| Action            | Mouse / Touch              | Keyboard                     |
| ----------------- | -------------------------- | ---------------------------- |
| Select a cell     | Click a cell               | Arrow keys                   |
| Enter a digit     | Click a number on the pad  | `1`–`9`                      |
| Erase a cell      | Click **Erase**            | `Backspace`, `Delete`, or `0`|
| Toggle notes mode | Click **Notes**            | `N`                          |
| Undo              | Click **Undo**             | `Ctrl`/`Cmd` + `Z`           |
| Pause / resume    | Click **Pause**            | `Esc`                        |
| New game          | Click **New Game**         | —                            |

Given (pre-filled) cells cannot be edited. Starting a new game while a game is in
progress prompts for confirmation before discarding your current board.

## Project Structure

```
.
├── sudoku.html      # The complete application (markup, styles, and game logic)
└── kirocrew/
    └── connect.sh   # Unrelated workshop onboarding script (not part of the game)
```

## Technical Notes

- **No dependencies** — Pure HTML/CSS/JavaScript; runs entirely in the browser.
- **Puzzle generation** — Fills the three diagonal 3×3 boxes, solves the rest via
  backtracking to produce a full solution, then removes cells one at a time while
  verifying the puzzle still has a single unique solution.
- **State persistence** — The full game state (board, solution, givens, notes,
  timer, difficulty) is serialized to `localStorage` under the key `sudoku-game-v1`.

## Browser Support

Works in any modern browser that supports the native `<dialog>` element,
CSS custom properties, and `localStorage` (recent versions of Chrome, Edge,
Firefox, and Safari).
