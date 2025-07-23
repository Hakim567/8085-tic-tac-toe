# 8085-tic-tac-toe
Simple tic tac toe game designed in  assembly 8085 using my1sim85 for NMJ21704 Microprocessor Systems using PPI & miniMV

Rules of the game:
  - 2 players take turns drawing on a 3x3 board, each player has their own symbol.
  - No placing on already occupied space
  - First player to match their 3 symbols either horizontally, vertically or diagonally wins!

<img width="1159" height="648" alt="image" src="https://github.com/user-attachments/assets/d6a43559-113e-4ee2-84a9-649fa1aba39d" />

---
### Setup
  1. Load ASM file
  2. Assemble, generate and build system
  3. Reset build to default
  4. Remove any initial PPI's except Interrupt (if you're using it)
  5. Use the 'Add PPI' on build menu and add additional PPI's by default they are:
     | Address port       | Available ports | Function            | Available by default? |
     | -------------      | -------------   | -------------       | -------------         |
     | 80H                | PA@80           | LED_PORT            | ✅                    |
     |                    | PB@81           | KEYPAD_PORT         | ✅                    | 
     |                    | PC@82           | SEVENSEG_FIRST_PORT | ✅                    |
     | 90H                | PA@90           | SEVENSEG_SECOND_PORT| ❌                    |
     |                    | PB@91           | SEVENSEG_THIRD_PORT | ❌                    |
     |                    | PC@92           | SEVENSEG_FOURTH_PORT| ❌                    |

  6. Apply port address upon PPI by right clicking the modules (careful to not misclick the inside of the modules as you can also individually assign port bits by clicking individual parts)  
    <img width="268" height="147" alt="image" src="https://github.com/user-attachments/assets/2c124199-0a5b-4fb1-864d-3ab4075ae2e0" />  
  7. Simulate and run
 
### Viewing board on miniMV
  1. Click miniMV
  2. Load address of matrix board, default is 2040  
    <img width="101" height="119" alt="image" src="https://github.com/user-attachments/assets/9bc446fa-1f09-4ff6-9310-87b350a1a129" />
    <img width="99" height="120" alt="image" src="https://github.com/user-attachments/assets/5579aec6-3653-4e78-a2c2-9ded4344568c" />  
    1A is player 1, 2B is player 2

 ⚠️ NOTE: for some reason on my1sim85-0.9.4 the third horizontal line will NOT update, I have no clue why that happens but it doesn't happen on my1sim85-0.6.2 ¯\\\_(ツ)\_/¯
