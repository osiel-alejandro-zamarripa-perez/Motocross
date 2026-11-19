<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements a 4-player VGA motorcycle racing game (`tt_um_KK_VGA01`) running at a 640x480 @ 60Hz video resolution. 

The architecture is divided into five main modules:
- VGA Sync Generator (`hvsync_generator`): Generates standard `hsync`, `vsync`, and pixel coordinate counters (`pix_x`, `pix_y`).
- Track Generator (`track_gen`): Dynamically renders selectable race tracks (`uio_in[1:0]`) and finish line patterns.
- Direction Decoder (`dir_steer`): Converts 2-bit directional inputs per player (`ui_in[7:0]`) into 2's complement velocity vectors (`+100` / `-100`).
- Sequencer (`motor_handler`): Schedules physics updates exclusively during the VGA vertical blanking interval (VBLANK) to prevent visual tearing.
- Physics Engine (`motor_core`): Computes sub-pixel coordinates (`xp`, `yp`), handles speed levels (`uio_in[3:2]`), and detects collisions against track boundaries.

## How to test

1. Connect a Tiny VGA Pmod to the dedicated output port (`uo[7:0]`) and a clock source of 25.175 MHz to `clk`.
2. Set `rst_n` low to reset the system, then set `rst_n` high to start the video output and game logic.
3. Use `uio[1:0]` to select one of the four available race tracks and `uio[3:2]` to set the game speed.
4. Control each motorcycle direction using pairs of bits on `ui[7:0]` (`ui[1:0]` for Player 1, `ui[3:2]` for Player 2, `ui[5:4]` for Player 3, and `ui[7:6]` for Player 4). Pulse `uio[4]` high to trigger a soft gameplay reset.

## External hardware

- Tiny VGA Pmod connected to `uo[7:0]` for RGB222 video output (`R1, G1, B1, VSYNC, R0, G0, B0, HSYNC`).
- Switches or pushbuttons connected to `ui[7:0]` (player steering) and `uio[4:0]` (track selection, speed, and gameplay reset).
