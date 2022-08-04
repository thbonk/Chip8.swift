//
//  Chip8Spec.swift
//  Chip8Tests
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
import Quick
import Nimble

@testable import Chip8

final class Chip8Spec: QuickSpec {

  public override func spec() {
    describe("Loading a ROM into memory") {
      it("Initializing RAM with ROM data is successful") {
        let data = Data(repeating: 0x1F, count: 2048)
        let vm = Chip8()
        
        try vm.loadCode(data: data)
        
        let code = [UInt8](data)
        
        for i in 0..<code.count {
          expect(vm.memory[i + Chip8.RamStartAddress]).to(equal(code[i]))
        }
      }
      
      it("Initializing RAM with ROM file is successful") {
        let url = Bundle.module.url(forResource: "testdata/dummy.rom", withExtension: nil)!
        let vm = Chip8()
        
        try vm.loadCode(from: url)
        
        let data = try Data(contentsOf: url)
        let code = [UInt8](data)
        
        for i in 0..<code.count {
          expect(vm.memory[i + Chip8.RamStartAddress]).to(equal(code[i]))
        }
      }
      
      it("Initializing RAM with ROM that is to large throws exception") {
        let data = Data(repeating: 0x1F, count: 5000)
        let vm = Chip8()
        
        expect {
          try vm.loadCode(data: data)
        }.to(throwError())
      }
      
      it("Initializing RAM with ROM file that is to large throws exception") {
        let url = Bundle.module.url(forResource: "testdata/large_dummy.rom", withExtension: nil)!
        let vm = Chip8()
        
        expect {
          try vm.loadCode(from: url)
        }.to(throwError())
      }
    }
    
    describe("Exceuting Test ROM") {
      it("Running test ROM is successful") {
        class Debugger: Chip8Debugger {
          var previousPC = -2
          var instructions = 0
          
          override func step(vm: Chip8) {
            instructions += 1
            if previousPC == vm.pc {
              vm.stop()
            }
            
            previousPC = vm.pc.int
          }
        }
        
        class DebuggerPlatform: PlatformIntegration {
          var screen: String = ""
          
          func displayGraphics(vm: Chip8) {
            screen = ""
            
            for y in 0..<Chip8.GfxScreenHeight {
              var line = ""
              for x in 0..<Chip8.GfxScreenWidth {
                if(vm.gfx[(y * 64) + x] == 0) {
                  line = line + "0"
                } else {
                  line = line + " "
                }
              }
              screen = screen + line + "\n"
            }
          }
          
          func setKeys(vm: Chip8) {
            
          }
        }
        
        let url = Bundle.module.url(forResource: "testdata/test_opcode.ch8", withExtension: nil)!
        let debugger = Debugger()
        let platform = DebuggerPlatform()
        let vm = Chip8(platform: platform, debugger: debugger)
        
        try vm.loadCode(from: url)
        vm.start()
        
        let expectedScreen = """
0000000000000000000000000000000000000000000000000000000000000000
0   0 0 00   0 0 000000   0   00   0 0 00000   00  0   0 0 00000
00  00 000 0 0  0000000 0 0  000 0 0  000000   00 00 0 0  000000
000 0 0 00 0 0 0 000000 0 0 0000 0 0 0 00000 0 000 0 0 0 0 00000
0   0 0 00   0 0 000000   0   00   0 0 00000   00 00   0 0 00000
0000000000000000000000000000000000000000000000000000000000000000
0 0 0 0 00   0 0 000000   0   00   0 0 00000   0   0   0 0 00000
0   00 000 0 0  0000000   0 0 00 0 0  000000   0 000 0 0  000000
000 0 0 00 0 0 0 000000 0 0 0 00 0 0 0 00000 0 0   0 0 0 0 00000
000 0 0 00   0 0 000000   0   00   0 0 00000   0   0   0 0 00000
0000000000000000000000000000000000000000000000000000000000000000
00  0 0 00   0 0 000000   0  000   0 0 00000   0   0   0 0 00000
00 000 000 0 0  0000000   00 000 0 0  000000   0  00 0 0  000000
000 0 0 00 0 0 0 000000 0 00 000 0 0 0 00000 0 0 000 0 0 0 00000
00 00 0 00   0 0 000000   0   00   0 0 00000   0   0   0 0 00000
0000000000000000000000000000000000000000000000000000000000000000
0   0 0 00   0 0 000000   0   00   0 0 00000   00  0   0 0 00000
000 00 000 0 0  0000000   000 00 0 0  000000 0000 00 0 0  000000
000 0 0 00 0 0 0 000000 0 0  000 0 0 0 00000  0000 0 0 0 0 00000
000 0 0 00   0 0 000000   0   00   0 0 00000 0000 00   0 0 00000
0000000000000000000000000000000000000000000000000000000000000000
0   0 0 00   0 0 000000   0   00   0 0 00000   0   0   0 0 00000
0   00 000 0 0  0000000   00  00 0 0  000000 0000  0 0 0  000000
000 0 0 00 0 0 0 000000 0 000 00 0 0 0 00000  0000 0 0 0 0 00000
0   0 0 00   0 0 000000   0   00   0 0 00000 000   0   0 0 00000
0000000000000000000000000000000000000000000000000000000000000000
00 00 0 00   0 0 000000   0 0 00   0 0 00000  00 0 0   0 0 00000
0 0 00 000 0 0  0000000   0   00 0 0  0000000 000 00 0 0  000000
0   0 0 00 0 0 0 000000 0 000 00 0 0 0 000000 00 0 0 0 0 0 00000
0 0 0 0 00   0 0 000000   000 00   0 0 00000   0 0 0   0 0 00000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000

"""
        
        expect(platform.screen).to(equal(expectedScreen))
      }
    }
  }
}
