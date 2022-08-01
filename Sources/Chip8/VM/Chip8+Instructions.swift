//
//  Chip8+Instructions.swift
//  Chip8
//
//  Created by Thomas Bonk on 28.07.22.
//  Copyright 2021 Thomas Bonk <thomas@meandmymac.de>
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

extension Chip8 {
  /*
   00E0 - CLS
   Clear the display.
   */
  public func CLS() {
    for i in 0..<gfx.count {
      gfx[i] = 0x0
    }
    drawFlag = true
    pc += 2
  }
  
  /*
   00EE - RET
   Return from a subroutine.

   The interpreter sets the program counter to the address at the top of the stack,
   then subtracts 1 from the stack pointer.
   */
  public func RET() {
    sp -= 1
    pc = stack[sp.int]
    pc += 2
  }
  
  /*
   1nnn - JP addr
   Jump to location nnn.

   The interpreter sets the program counter to nnn.
   */
  public func JP(nnn: UInt16) {
    pc = nnn
  }
  
  /*
   2nnn - CALL addr
   Call subroutine at nnn.

   The interpreter puts the current PC on the top of the stack then increments the stack pointer,
   The PC is then set to nnn.
   */
  public func CALL(nnn: UInt16) {
    stack[sp.int] = pc
    sp += 1
    pc = nnn
  }
  
  /*
   3xkk - SE Vx, kk
   Skip next instruction if Vx = kk.

   The interpreter compares register Vx to kk, and if they are equal, increments the program counter by 2.
   */
  public func SE(x: UInt16, kk: UInt16) {
    if V[x.int] == kk {
      pc += 4
    } else {
      pc += 2
    }
  }
  
  /*
   4xkk - SNE Vx, kk
   Skip next instruction if Vx != kk.

   The interpreter compares register Vx to kk, and if they are not equal, increments the program
   counter by 2.
   */
  public func SNE(x: UInt16, kk: UInt16) {
    if V[x.int] != kk {
      pc += 4
    } else {
      pc += 2
    }
  }
  
  /*
   5xy0 - SE Vx, Vy
   Skip next instruction if Vx = Vy.

   The interpreter compares register Vx to register Vy, and if they are equal,
   increments the program counter by 2.
   */
  public func SE(x: UInt16, y: UInt16) {
    if V[x.int] == V[y.int] {
      pc += 4
    } else {
      pc += 2
    }
  }
  
  /*
   6xkk - LD Vx, byte
   Set Vx = kk.

   The interpreter puts the value kk into register Vx.
   */
  public func LD(x: UInt16, kk: UInt8) {
    V[x.int] = kk
    pc += 2
  }
  
  /*
   7xkk - ADD Vx, byte
   Set Vx = Vx + kk.

   Adds the value kk to the value of register Vx, then stores the result in Vx.
   */
  public func ADD(x: UInt16, kk: UInt8) {
    let r = x.int
    
    V[r] = V[r] &+ kk
    pc += 2
  }
  
  /*
   8xy0 - LD Vx, Vy
   Set Vx = Vy.

   Stores the value of register Vy in register Vx.
   */
  public func LD(x: UInt16, y: UInt16) {
    V[x.int] = V[y.int]
    pc += 2
  }
  
  /*
   8xy1 - OR Vx, Vy
   Set Vx = Vx OR Vy.

   Performs a bitwise OR on the values of Vx and Vy, then stores the result in Vx.
   */
  public func OR(x: UInt16, y: UInt16) {
    V[x.int] |= V[y.int]
    pc += 2
  }
  
  /*
   8xy2 - AND Vx, Vy
   Set Vx = Vx AND Vy.

   Performs a bitwise AND on the values of Vx and Vy, then stores the result in Vx.
   */
  public func AND(x: UInt16, y: UInt16) {
    V[x.int] &= V[y.int]
    pc += 2
  }
  
  /*
   8xy3 - XOR Vx, Vy
   Set Vx = Vx XOR Vy.

   Performs a bitwise exclusive OR on the values of Vx and Vy, then stores the result in Vx.
   */
  public func XOR(x: UInt16, y: UInt16) {
    V[x.int] ^= V[y.int]
    pc += 2
  }
  
  /*
   8xy4 - ADD Vx, Vy
   Set Vx = Vx + Vy, set VF = carry.

   The values of Vx and Vy are added together. If the result is greater than 8 bits (i.e., > 255,)
   VF is set to 1, otherwise 0. Only the lowest 8 bits of the result are kept, and stored in Vx.
   */
  public func ADD(x: UInt16, y: UInt16) {
    let r1 = x.int
    let r2 = y.int
    
    V[0xF] = (V[r2] > (0xFF - V[r1])).uint8
    V[r1] = V[r1] &+ V[r2]
    pc += 2
  }
  
  /*
   8xy5 - SUB Vx, Vy
   Set Vx = Vx - Vy, set VF = NOT borrow.

   If Vx > Vy, then VF is set to 1, otherwise 0. Then Vy is subtracted from Vx, and the results
   stored in Vx.
   */
  public func SUB(x: UInt16, y: UInt16) {
    let r1 = x.int
    let r2 = y.int
    
    V[0xF] = (!(V[r2] > (V[r1]))).uint8
    V[r1] = V[r1] &- V[r2]
    pc += 2
  }
  
  /*
   8xy6 - SHR Vx {, Vy}
   Set Vx = Vx SHR 1.

   If the least-significant bit of Vx is 1, then VF is set to 1, otherwise 0. Then Vx is divided by 2.
   */
  public func SHR(x: UInt16) {
    let r = x.int
    
    V[0x0F] = V[r] & 0x01
    V[r] >>= 1
    pc += 2
  }
  
  /*
   8xy7 - SUBN Vx, Vy
   Set Vx = Vy - Vx, set VF = NOT borrow.
   */
  public func SUBN(x: UInt16, y: UInt16) {
    let r1 = x.int
    let r2 = y.int
    
    V[0x0F] = (V[r1] <= V[r2]).uint8
    V[r1] = V[r2] &- V[r1]
    pc += 2
  }
  
  /*
   8xyE - SHL Vx {, Vy}
   Set Vx = Vx SHL 1.

   If the most-significant bit of Vx is 1, then VF is set to 1, otherwise to 0. Then Vx is multiplied by 2.
   */
  public func SHL(x: UInt16) {
    let r = x.int
    
    V[0x0F] = V[r] >> 7
    V[r] <<= 1
    pc += 2
  }
  
  /*
   9xy0 - SNE Vx, Vy
   Skip next instruction if Vx != Vy.

   The values of Vx and Vy are compared, and if they are not equal, the program counter is increased by 2.
   */
  public func SNE(x: UInt16, y: UInt16) {
    pc += (V[x.int] != V[y.int]) ? 4 : 2
  }
  
  /*
   Annn - LD I, addr
   Set I = nnn.

   The value of register I is set to nnn.
   */
  public func LD(addr: UInt16) {
    I = addr
    pc += 2
  }
  
  /*
   Bnnn - JP V0, addr
   Jump to location nnn + V0.

   The program counter is set to nnn plus the value of V0.
   */
  public func JPv0(addr: UInt16) {
    pc = V[0].uint16 + addr
  }
  
  /*
   Cxkk - RND Vx, byte
   Set Vx = random byte AND kk.

   The interpreter generates a random number from 0 to 255, which is then ANDed with the value kk.
   The results are stored in Vx. See instruction 8xy2 for more information on AND.
   */
  public func RND(x: UInt16, kk: UInt8) {
    V[x.int] = UInt8.random(in: 0...255) & kk
    pc += 2
  }
  
  /*
   Dxyn - DRW Vx, Vy, nibble
   Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision.

   The interpreter reads n bytes from memory, starting at the address stored in I.
   These bytes are then displayed as sprites on screen at coordinates (Vx, Vy). Sprites are
   XORed onto the existing screen. If this causes any pixels to be erased, VF is set to 1,
   otherwise it is set to 0. If the sprite is positioned so part of it is outside the
   coordinates of the display, it wraps around to the opposite side of the screen. See
   instruction 8xy3 for more information on XOR, and section 2.4, Display, for more information
   on the Chip-8 screen and sprites.
   */
  public func DRW(x: UInt16, y: UInt16, height: UInt16) {
    // TODO This method consumes a lot of time and should be optimized
    
    let xpos = V[x.int].int
    let ypos = V[y.int].int
    let h = height.int
    var pixel: UInt8
    
    V[0x0F] = 0
    
    for yline in 0..<h {
      pixel = memory[I.int + yline]
      
      for xline in 0..<8 {
        if (pixel & (0x80 >> xline)) != 0 {
          if gfx[xpos + xline + ((ypos + yline) * Chip8.GfxScreenWidth)] == 1 {
            V[0x0F] = 1
          }
          
          gfx[xpos + xline + ((ypos + yline) * Chip8.GfxScreenWidth)] ^= 1
        }
      }
    }
    
    drawFlag = true
    pc += 2
  }
  
  /*
   Ex9E - SKP Vx
   Skip next instruction if key with the value of Vx is pressed.

   Checks the keyboard, and if the key corresponding to the value of Vx is currently in the
   down position, PC is increased by 2.
   */
  public func SKP(x: UInt16) {
    pc += key[V[x.int].int] ? 4 : 2
  }
  
  /*
   ExA1 - SKNP Vx
   Skip next instruction if key with the value of Vx is not pressed.

   Checks the keyboard, and if the key corresponding to the value of Vx is currently in
   the up position, PC is increased by 2.
   */
  public func SKNP(x: UInt16) {
    pc += key[V[x.int].int] ? 4 : 2
  }
  
  /*
   set == false: x07 - LD Vx, DT
   Set Vx = delay timer value.

   The value of DT is placed into Vx.
   
   set == true: Fx15 - LD DT, Vx
   Set delay timer = Vx.

   DT is set equal to the value of Vx.
   */
  public func LDdt(x: UInt16, set: Bool) {
    if set {
      delayTimer = V[x.int]
    } else {
      V[x.int] = delayTimer
    }
    pc += 2
  }
  
  /*
   Fx0A - LD Vx, K
   Wait for a key press, store the value of the key in Vx.

   All execution stops until a key is pressed, then the value of that key is stored in Vx.
   */
  public func LDk(x: UInt16) {
    var keyPress = false
    
    for i in 0..<key.count {
      if key[i] {
        V[x.int] = i.uint8
        keyPress = true
      }
    }
    
    // If we didn't received a keypress, skip this cycle and try again.
    if !keyPress {
      return
    }
        
    pc += 2
  }
  
  /*
   Fx18 - LD ST, Vx
   Set sound timer = Vx.

   ST is set equal to the value of Vx.
   */
  public func LDst(x: UInt16) {
    soundTimer = V[x.int]
    pc += 2
  }
  
  /*
   Fx1E - ADD I, Vx
   Set I = I + Vx.

   The values of I and Vx are added, and the results are stored in I.
   */
  public func ADDi(x: UInt16) {
    let r = x.int
    
    V[0xF] = ((I + V[r].uint16) > 0xFFF).uint8
    I = I &+ V[r].uint16
    pc += 2
  }
  
  /*
   Fx29 - LD F, Vx
   Set I = location of sprite for digit Vx.

   The value of I is set to the location for the hexadecimal sprite corresponding to the
   value of Vx. See section 2.4, Display, for more information on the Chip-8 hexadecimal font.
   */
  public func LDf(x: UInt16) {
    I = V[x.int].uint16 * 0x5
    pc += 2
  }
  
  /*
   Fx33 - LD B, Vx
   Store BCD representation of Vx in memory locations I, I+1, and I+2.

   The interpreter takes the decimal value of Vx, and places the hundreds digit in memory
   at location in I, the tens digit at location I+1, and the ones digit at location I+2.
   */
  public func LDb(x: UInt16) {
    let r = x.int
    let a = I.int
    
    memory[a]     = V[r] / 100
    memory[a + 1] = (V[r] % 100) / 10
    memory[a + 2] = V[r] % 10
    
    pc += 2
  }
  
  /*
   store == true: Fx55 - LD [I], Vx
   Store registers V0 through Vx in memory starting at location I.

   The interpreter copies the values of registers V0 through Vx into memory, starting at the address in I.
   
   store == false: Fx65 - LD Vx, [I]
   Read registers V0 through Vx from memory starting at location I.

   The interpreter reads values from memory starting at location I into registers V0 through Vx.
   */
  public func LDi(x: UInt16, store: Bool) {
    let a = I.int
    
    if store {
      for i in 0...x.int {
        memory[a + i] = V[i]
      }
      
      // On the original interpreter, when the operation is done, I = I + X + 1.
      I += x + 1
    } else {
      for i in 0...x.int {
        V[i] = memory[a + i]
      }
      
      // On the original interpreter, when the operation is done, I = I + X + 1.
      // TODO check whether this is right
      I += x + 1
    }
    pc += 2
  }
}
