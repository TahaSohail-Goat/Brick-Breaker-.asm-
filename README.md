# Brick Breaker

A classic Brick Breaker game written in 16-bit x86 Assembly language.

The game runs in DOS text mode and writes directly to video memory at `0B800h` for fast screen updates. It includes a title screen, player name input, menu navigation, instructions, high score display, multiple levels, score tracking, lives, and powerups.

## Features

- Colorful brick layout
- Three playable levels
- Paddle and ball collision
- Score counter
- Lives system
- Extra life bonus after breaking bricks
- Falling powerups
- Player name input
- Instructions screen
- High score screen
- Win and game over screens

## Controls

| Key | Action |
| --- | --- |
| Left Arrow | Move paddle left |
| Right Arrow | Move paddle right |
| Up / Down Arrow | Navigate menu |
| Enter | Select menu option / continue |
| Esc | Quit current game |

## Requirements

To assemble and run this project, use a DOS-compatible assembler environment such as:

- DOSBox
- MASM or TASM
- DOS linker, such as `LINK`

## Build and Run

### Using MASM

```dos
masm BrickBreaker.asm;
link BrickBreaker.obj;
BrickBreaker.exe
```

### Using TASM

```dos
tasm BrickBreaker.asm
tlink BrickBreaker.obj
BrickBreaker.exe
```

If you are using DOSBox, mount the project folder first:

```dos
mount c c:\path\to\Brick_Breaker
c:
```

Then run the assembler commands from inside the mounted folder.

## Project File

- `BrickBreaker.asm` - Main Assembly source code for the complete game.

## Notes

This project uses `.MODEL SMALL`, BIOS keyboard interrupts, DOS exit interrupts, and direct text-mode video memory access, so it is intended for a DOS or DOSBox-style environment.
