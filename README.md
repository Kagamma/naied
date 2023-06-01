### NaiED

A small text editor for DOS real mode, written in Free Pascal. The project is meant to bring back memories of the old DOS days.

### Features
- Fast enough to run on 8086 machine
- Supports Long File Names (thanks to Free Pascal)
- Strings larger than 255 bytes (thanks to Free Pascal, although we limit it to 16KB)
- Handle file bigger than 64KB
- Highlight symbols and trailing spaces, enable / disable it by pressing `Ctrl-Shift-H`
- 32KB clipboard with support for Windows clipboard
- Common navigation methods: Arrow keys to move cursor, `Ctrl-C/V/X` for Copy/Paste/Cut, selecting blocks of text with `Shift+Arrow keys`, `Ctrl-S` to save the file, `Esc` to quit the editor
- Search: Use `Ctrl-F` or `Ctrl-Shift-F` for case-sensitive search, and `F3` to search for the next occurrence.
- Replace: Use `Ctrl-R` or `Ctrl-Shift-R` for case-sensitive replace, and `F4` to replace the next occurrence.

### Limitations
- No undo/redo functionality
- No mouse support
- Inability to handle files that exceed conventional memory limits
- Inability to work with multiple files

### How to build

You need a Free Pascal cross-compiler for msdos-8086, with Compact memory model (although larger models should compile just fine)

### Screenshots

![naied in dosbox-x](/img/naied.PNG)

