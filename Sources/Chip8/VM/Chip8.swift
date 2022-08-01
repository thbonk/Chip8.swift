//
//  Chip8.swift
//  Chip8
//
//  Created by Thomas Bonk on 24.01.21.
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

public class Chip8 {
  
  // MARK: - Public Type aliases
  
  public typealias ErrorHandler = (Error) -> Void
  
  
  // MARK: - Public Constants
  
  public static let MemorySize = 4096
  public static let GfxScreenWidth = 64
  public static let GfxScreenHeight = 32
  public static let GfxMemorySize = GfxScreenWidth * GfxScreenHeight
  public static let StackSize = 16
  public static let RamStartAddress = 0x200
  public static let MaxRomSize = MemorySize - RamStartAddress
  public static let Keys = 16
  
  
  // MARK: - Public Properties
  
  public internal(set) var stopFlag: Bool
  
  public internal(set) var opcode: UInt16
  public internal(set) var memory: [UInt8]
  public internal(set) var V: [UInt8]
  public internal(set) var I: UInt16
  public internal(set) var pc: UInt16
  
  public internal(set) var gfx: [UInt8]
  
  public internal(set) var delayTimer: UInt8
  public internal(set) var soundTimer: UInt8
  
  public internal(set) var stack: [UInt16]
  public internal(set) var sp: UInt16
  
  public internal(set) var key: [Bool]
  
  
  // MARK: - Private Properties
  
  internal var drawFlag: Bool
  internal var debugger: Chip8Debugger?
  internal var debugMode = false
  internal var errorHandler: ErrorHandler?
  
  internal let fontset: [UInt8] = [
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80  // F
  ]
  
  
  // MARK: - Initialization
  
  public init(debugger: Chip8Debugger? = nil) {
    stopFlag = false
    opcode = 0
    memory = Array(repeating: 0, count: Chip8.MemorySize)
    V = Array(repeating: 0, count: 16)
    I = 0
    pc = UInt16(Chip8.RamStartAddress)
    
    gfx = Array(repeating: 0, count: Chip8.GfxMemorySize)
    
    delayTimer = 0
    soundTimer = 0
    drawFlag = false
    
    stack = Array(repeating: 0, count: Chip8.StackSize)
    sp = 0
    
    // Load fontset
    for i in 0..<fontset.count {
      memory[i] = fontset[i]
    }
    
    key = Array(repeating: false, count: Chip8.Keys)
    
    self.debugger = debugger
    self.debugger?.vm = self
    self.debugMode = (self.debugger != nil)
  }
  
  
  // MARK: - Public Methods
  
  public func loadCode(from url: URL) throws {
    try loadCode(data: try Data(contentsOf: url))
  }
  
  public func loadCode(data: Data) throws {
    let code = [UInt8](data)
    
    if code.count > memory.count - Chip8.RamStartAddress {
      // ROM is too big, throw error
      throw Chip8Error.RomTooLarge(maxRomSize: Chip8.MaxRomSize,romSize: code.count)
    }
    
    for addr in 0..<code.count {
      memory[addr + Chip8.RamStartAddress] = code[addr]
    }
  }
  
  @available(macOS 10.12, *)
  public func start(errorHandler: ErrorHandler? = nil) {
    self.errorHandler = errorHandler
    self.stopFlag = false
    
    while !self.stopFlag {
      emulate()
    }
  }
  
  public func stop() {
    self.stopFlag = true
  }
  
  
  // MARK: - Private Methods
  
  private func emulate() {
    do {
      if self.debugMode {
        debugger?.step(vm: self)
      }
      try emulateCycle()
      
      if drawFlag {
        drawGraphics()
      }
      
      setKeys()
      updateTimers()
    } catch {
      errorHandler?(error)
      stop()
    }
  }
  
  private func drawGraphics() {
    // TODO CALL OS exit to draw graphics
    // Draw
    for y in 0..<Chip8.GfxScreenHeight {
      var line = ""
      for x in 0..<Chip8.GfxScreenWidth {
        if(gfx[(y * 64) + x] == 0) {
          line = line + "0"
        } else {
          line = line + " "
        }
      }
      print(line)
    }
    print("\n\n\n")
  }
  
  private func setKeys() {
    // TODO CALL OS exit to set pressed keys
  }
  
  private func updateTimers() {
    if delayTimer > 0 {
      delayTimer -= 1
    }
    
    if soundTimer > 0 {
      if soundTimer == 1 {
        // TODO CALL OS exit to play a beep
        print("BEEP!\n")
      }
      soundTimer -= 1
    }
  }
  
  private func emulateCycle() throws {
    opcode = memory[pc.int].uint16 << 8 | memory[pc.int + 1].uint16
    
    switch opcode & 0xF000 {
      case 0x0000:
        switch opcode & 0x000F {
          case 0x0000: // 0x00E0: CLS - Clear screen
            CLS()
            break
            
          case 0x000E: // 0x00EE: RET - return from subroutine
            RET()
            break
            
          default:
            throw Chip8Error.InvalidOpcode(opcode)
        }
        
      case 0x1000: // 0x1nnn: JP nnn - Jump to address nnn
        JP(nnn: opcode & 0x0FFF)
        break
        
      case 0x2000: // 0x2nnn CALL nnn - Call subroutine at nnn
        CALL(nnn: opcode & 0x0FFF)
        break
        
      case 0x3000: // 0x3xkk SE Vx, kk - Skip next instruction if Vx = kk
        SE(x: (opcode & 0x0F00) >> 8, kk: opcode & 0x00FF)
        break
        
      case 0x4000: // 0x4xkk SE Vx, kk - Skip next instruction if Vx != kk
        SNE(x: (opcode & 0x0F00) >> 8, kk: opcode & 0x00FF)
        break
        
      case 0x5000: // 5xy0 SE Vx, Vy - Skip next instruction if Vx = Vy.
        SE(x: (opcode & 0x0F00) >> 8, y: (opcode & 0x00F0) >> 4)
        break
        
      case 0x6000: // 6xkk LD Vx, kk - Set Vx = kk.
        LD(x: (opcode & 0x0F00) >> 8, kk: (opcode & 0x00FF).uint8)
        break
        
      case 0x7000: // 7xkk ADD Vx, kk - Set Vx = Vx + kk
        ADD(x: (opcode & 0x0F00) >> 8, kk: (opcode & 0x00FF).uint8)
        break
        
      case 0x8000:
        switch opcode & 0x000F {
          case 0x0000: // 8xy0 LD Vx, Vy - Set Vx = Vy
            LD(x: (opcode & 0x0F00) >> 8, y: (opcode & 0x0F0) >> 4)
            break
            
          case 0x0001: // 8xy1 OR Vx, Vy - Set Vx = Vx OR Vy
            OR(x: (opcode & 0x0F00) >> 8, y: (opcode & 0x0F0) >> 4)
            break
            
          case 0x0002: // 0xy2 AND Vx, Vy - Set Vx = Vx AND Vy
            AND(x: (opcode & 0x0F00) >> 8, y: (opcode & 0x0F0) >> 4)
            break
            
          case 0x0003: // 0xy2 XOR Vx, Vy - Set Vx = Vx XOR Vy
            XOR(x: (opcode & 0x0F00) >> 8, y: (opcode & 0x0F0) >> 4)
            break
            
          case 0x0004: // 0x8XY4 Adds VY to VX - VF is set to 1 when there's a carry, and to 0 when there isn't
            ADD(x: (opcode & 0x0F00) >> 8, y: (opcode & 0x0F0) >> 4)
            break
            
          case 0x0005: // 0x8XY5 Vx = Vx - Vy. VF is set to 0 when there's a borrow, and 1 when there isn't
            SUB(x: (opcode & 0x0F00) >> 8, y: (opcode & 0x0F0) >> 4)
            break
            
          case 0x0006: // 0x8XY6 Shifts VX right by one. VF is set to the value of the least significant bit of VX before the shift
            SHR(x: (opcode & 0x0F00) >> 8)
            break
            
          case 0x0007: // 0x8XY7: Sets VX to VY minus VX. VF is set to 0 when there's a borrow, and 1 when there isn't
            SUBN(x: (opcode & 0x0F00) >> 8, y: (opcode & 0x00F0) >> 4)
            break
            
          case 0x000E: // 0x8XYE: Shifts VX left by one. VF is set to the value of the most significant bit of VX before the shift
            SHL(x: (opcode & 0x0F00) >> 8)
            break
            
          default:
            throw Chip8Error.InvalidOpcode(opcode)
        }
        break
        
      case 0x9000: // 0x9XY0: Skips the next instruction if VX doesn't equal VY
        SNE(x: (opcode & 0x0F00) >> 8, y: (opcode & 0x00F0) >> 4)
        break
        
      case 0xA000: // ANNN: Sets I to the address NNN
        LD(addr: opcode & 0x0FFF)
        break
        
      case 0xB000: // BNNN: Jumps to the address NNN plus V0
        JPv0(addr: opcode & 0x0FFF)
        break
        
      case 0xC000: // CXNN: Sets VX to a random number and NN
        RND(x: (opcode & 0x0F00) >> 8, kk: (opcode & 0x00FF).uint8)
        break
        
      case 0xD000:
        // DXYN: Draws a sprite at coordinate (VX, VY) that has a width of 8 pixels and a height of N pixels.
        // Each row of 8 pixels is read as bit-coded starting from memory location I;
        // I value doesn't change after the execution of this instruction.
        // VF is set to 1 if any screen pixels are flipped from set to unset when the sprite is drawn,
        // and to 0 if that doesn't happen
        DRW(x: (opcode & 0x0F00) >> 8, y: (opcode & 0x00F0) >> 4, height: opcode & 0x000F)
        break
        
      case 0xE000:
        switch opcode & 0x00FF {
          case 0x009E: // EX9E: Skips the next instruction if the key stored in VX is pressed
            SKP(x: (opcode & 0x0F00) >> 8)
            break
            
          case 0x00A1: // EXA1: Skips the next instruction if the key stored in VX isn't pressed
            SKNP(x: (opcode & 0x0F00) >> 8)
            break
            
          default:
            throw Chip8Error.InvalidOpcode(opcode)
        }
        break
        
      case 0xF000:
        switch opcode & 0x00FF {
          case 0x0007: // FX07: Sets VX to the value of the delay timer
            LDdt(x: (opcode & 0x0F00) >> 8, set: false)
            break
            
          case 0x000A: // FX0A: A key press is awaited, and then stored in VX
            LDk(x: (opcode & 0x0F00) >> 8)
            break
            
          case 0x0015: // FX15: Sets the delay timer to VX
            LDdt(x: (opcode & 0x0F00) >> 8, set: true)
            break
            
          case 0x0018: // FX18: Sets the sound timer to VX
            LDst(x: (opcode & 0x0F00) >> 8)
            break
            
          case 0x001E: // FX1E: Adds VX to I
            ADDi(x: (opcode & 0x0F00) >> 8)
            break
            
          case 0x0029:
            // FX29: Sets I to the location of the sprite for the character in VX.
            // Characters 0-F (in hexadecimal) are represented by a 4x5 font
            LDf(x: (opcode & 0x0F00) >> 8)
            break
            
          case 0x0033:
            // FX33: Stores the Binary-coded decimal representation of VX at the addresses I,
            // I plus 1, and I plus 2
            LDb(x: (opcode & 0x0F00) >> 8)
            break
            
          case 0x0055: // FX55: Stores V0 to VX in memory starting at address I
            LDi(x: (opcode & 0x0F00) >> 8, store: true)
            break
            
          case 0x0065: // FX65: Fills V0 to VX with values from memory starting at address I
            LDi(x: (opcode & 0x0F00) >> 8, store: false)
            break
            
          default:
            throw Chip8Error.InvalidOpcode(opcode)
        }
        break
        
      default:
        throw Chip8Error.InvalidOpcode(opcode)
    }
  }
}
