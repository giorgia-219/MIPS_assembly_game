# MIPS Assembly Arcade Game

A retro-style arcade game developed in MIPS assembly.

<img width="1378" height="524" alt="demo" src="https://github.com/user-attachments/assets/8a99ddb1-58c0-4a3e-bc20-df9d21888e09" />



### Gameplay & Logic

The game takes place on a 7x7 grid bounded by walls. You represent the player (P) and your goal is to collect rewards (R) to increase your score.
- goal: collect rewards to reach a score of 100. Each reward is worth 5 points.
- controls: use the standard keys W,A,S,D to move Up, Left, Down and Right.
- game over: the game ends if the player collides with the walls or you reach the score of 100.
- randomized spawning: every time you spawn or collect a reward, a new pseudo-random location for the entities is computed, ensuring they are within bounds and don't overlap.


### Constant motion extention

Once you choose an initial direction, the player moves automatically.
- continuous movement: you must anticipate turns before hitting walls
- dynamic speed: as the score increases, the player moves faster and faster, increasing the difficulty.


### How to run
  1. Download MARS (https://github.com/dpetersanderson/MARS.git)
  2. Launch MARS and load the source
  3. Assemble
  4. Setup the display
    • Tools --> Keyboard and Display MMIO Simulator
    • In the tool window, click Connect to MIPS
  5. Press the Run icon (the green play button)
  6. Click inside the keyboard text area of the MMIO Simulator tool to enter commands (W/A/S/D)


## 📂 Additional Resources
- [Technical Remarks & Implementation Details](./dev.md)