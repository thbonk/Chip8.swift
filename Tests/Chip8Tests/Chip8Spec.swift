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
        let url = Bundle.module.url(forResource: "testdata/test_opcode.ch8", withExtension: nil)!
        let vm = Chip8()
        
        try vm.loadCode(from: url)
        
        vm.start()
      }
    }
  }
}
