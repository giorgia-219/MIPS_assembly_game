# Technical Remarks and Implementation Details


### Game flow
The program follows a continuous execution loop, divided into four main functional phases:

1. **Initialization (*main & generate_reward*)**

Procedural Setup: The game uses syscall 42 to generate random X/Y coordinates for both the player and the reward.

Collision Avoidance: A validation check ensures the reward does not spawn on the player's starting position; if it does, the generator re-runs until a unique coordinate is found.

2. **Rendering (*print_grid & print_score*)**

Environment Generation: The program loops through a 7x7 coordinate map, drawing walls (#), the player (P), and the reward (R) based on current memory values.

MMIO Display: Characters are sent individually to the Transmitter Data Register.

Dynamic UI: The score is converted from an integer to ASCII on-the-fly and displayed above the grid.

3. **Input Processing (*wait & check_direction*)**

Real-Time Polling: Instead of pausing, the program enters a "Wait Loop" (the speed controller).

Keyboard Interception: It checks the Receiver Control Register for a "Ready" bit. If a key (W/A/S/D) is pressed, the movement direction updates; otherwise, the player continues moving in the last recorded direction.

4. **Logic & Collision (*move_player*)**

Wall Detection: If the new coordinates match a boundary (0 or 6), the program jumps to the game_over routine.

Reward Collection: If player coordinates match reward coordinates:

Score: +5 points.

Difficulty Scaling: The speed variable is decreased (reducing wait loop cycles).

Regeneration: A new reward is spawned, and the screen refreshes.



### Low level architecture

I had restrictions on syscalls and high-level abstractions, and I had to find alternative solutions.

- **I/O (syscall 12/4):** Instead of using syscall 12 (Read Char) or syscall 4 (Print String), I manually polled the Receiver and Transmitter registers (0xffff0000 range).

- **Wait (syscall 32):** Timing is handled via a long wait loop that wastes CPU time rather than syscall 32. This allowed for the Speed Extension, where difficulty scales by reducing loop cycles as the player's score increases.



### Logic & Data-Management

**Coordinate Systems:** To reduce the amount of comparisons, I initially stored locations as a single-integer position (0–24). When moving left or right, the amount would shift by 1, when moving up or down it would shift by 5. To then get the location, I used div and mfhi/mflo.
I however switched to an X/Y coordinate system, so that I could use the bell character (ASCII 7) to move the cursor to a specific coordinate. This avoids re-printing the entire grid every time the player moves.

**Manual Integer-to-ASCII:** To display scores up to 100, I implemented a custom algorithm that isolates digits and applies a 48-offset to align with ASCII character codes.



### Challenges & Iterations

**MMIO Printing Delays**: I encountered a race condition where the "GAME OVER" screen behaved unexpectedly due to a 5-instruction hardware delay in the MMIO simulator. I solved this by injecting "No-Op" instructions to allow the hardware to catch up.
