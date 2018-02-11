//
//  BTCBigNumberTests.swift
//  CoreBitcoin
//
//  Created by Robert S Mozayeni on 11/27/15.
//  Copyright © 2015 Oleg Andreev. All rights reserved.
//

import XCTest

class BTCBigNumberTests: XCTestCase {
    
    func testBigNumber() {
        XCTAssertEqual(BTCBigNumber(), BTCBigNumber.zero(), "default bignum should be zero")
        XCTAssertNotEqual(BTCBigNumber(), BTCBigNumber.one(), "default bignum should not be one")
        XCTAssertEqual("0", BTCBigNumber().string(inBase: 10), "default bignum should be zero")
        XCTAssertEqual(BTCBigNumber(int32: 0), BTCBigNumber.zero(), "0 should be equal to itself")
        
        XCTAssertEqual(BTCBigNumber.one(), BTCBigNumber.one(), "1 should be equal to itself")
        XCTAssertEqual(BTCBigNumber.one(), BTCBigNumber(uInt32: 1), "1 should be equal to itself")
        
        XCTAssertEqual(BTCBigNumber.one().string(inBase: 16), "1", "1 should be correctly printed out")
        XCTAssertEqual(BTCBigNumber(uInt32: 1).string(inBase: 16), "1", "1 should be correctly printed out")
        XCTAssertEqual(BTCBigNumber(uInt32: 0xdeadf00d).string(inBase: 16), "deadf00d", "0xdeadf00d should be correctly printed out")
        
        XCTAssertEqual(BTCBigNumber(uInt64: 0xdeadf00ddeadf00d).string(inBase: 16),
                       "deadf00ddeadf00d", "0xdeadf00ddeadf00d should be correctly printed out")
        
        XCTAssertEqual(BTCBigNumber(string: "0b1010111", base: 2).string(inBase: 2), "1010111", "0b1010111 should be correctly parsed")
        XCTAssertEqual(BTCBigNumber(string: "0x12346789abcdef", base: 16).string(inBase: 16),
                       "12346789abcdef", "0x12346789abcdef should be correctly parsed")
        
        
        do {
            let bn: BTCBigNumber = BTCBigNumber(uInt64: 0xdeadf00ddeadbeef)
            let data: Data = bn.signedLittleEndian
            XCTAssertEqual("efbeadde0df0adde00", BTCHexFromData(data),
                           "littleEndianData should be little-endian with trailing zero byte")
            let bn2: BTCBigNumber = BTCBigNumber(signedLittleEndian: data)
            XCTAssertEqual("deadf00ddeadbeef", bn2.hexString,
                           "converting to and from data should give the same result")
        }
        
    }
    
    func testNegativeZero() {
        
        let zeroBN: BTCBigNumber = BTCBigNumber.zero()
        let negativeZeroBN: BTCBigNumber = BTCBigNumber(signedLittleEndian: BTCDataFromHex("80"))
        let zeroWithEmptyDataBN: BTCBigNumber = BTCBigNumber(signedLittleEndian: NSData() as Data!)
        
//        print("negativeZeroBN.data = \(negativeZeroBN.data)") //-data is deprecated
        
        XCTAssertNotNil(zeroBN, "must exist")
        XCTAssertNotNil(negativeZeroBN, "must exist")
        XCTAssertNotNil(zeroWithEmptyDataBN, "must exist")
        
//        print("negative zero: %lld", negativeZeroBN.int64value)
        
        XCTAssertEqual(zeroBN.mutableCopy().add(BTCBigNumber(int32: 1)), BTCBigNumber.one(), "0 + 1 == 1")
        XCTAssertEqual(negativeZeroBN.mutableCopy().add(BTCBigNumber(int32: 1)), BTCBigNumber.one(), "0 + 1 == 1")
        XCTAssertEqual(zeroWithEmptyDataBN.mutableCopy().add(BTCBigNumber(int32: 1)), BTCBigNumber.one(), "0 + 1 == 1")
        
        // In BitcoinQT script.cpp, there is check (bn != bnZero).
        // It covers negative zero alright because "bn" is created in a way that discards the sign.
        XCTAssertNotEqual(zeroBN, negativeZeroBN, "zero should != negative zero")
    
    }
    
    func testExperiments() {
        
        //return //Was in the Objective-C version
        
        do {
            //let bn = BTCBigNumber.zero()
            let bn: BTCBigNumber = BTCBigNumber(unsignedBigEndian: BTCDataFromHex("00"))
            print("bn = %@ %@ (%@) 0x%@ b36:%@", bn, bn.unsignedBigEndian, bn.decimalString,
                  bn.string(inBase: 16), bn.string(inBase: 36))
        }
            
        do {
            //let bn = BTCBigNumber.one()
            let bn: BTCBigNumber = BTCBigNumber(unsignedBigEndian: BTCDataFromHex("01"))
            print("bn = %@ %@ (%@) 0x%@ b36:%@", bn, bn.unsignedBigEndian, bn.decimalString,
                  bn.string(inBase: 16), bn.string(inBase: 36))
        }
        
        do {
            let bn: BTCBigNumber = BTCBigNumber(uInt32: 0xdeadf00d)
            print("bn = %@ (%@) 0x%@ b36:%@", bn, bn.decimalString,
                  bn.string(inBase: 16), bn.string(inBase: 36))
        }
        
        do {
            let bn: BTCBigNumber = BTCBigNumber(int32: -16)
            print("bn = %@ (%@) 0x%@ b36:%@", bn, bn.decimalString,
                  bn.string(inBase: 16), bn.string(inBase: 36))
        }
        
        do {
            let base: UInt = 17
            let bn: BTCBigNumber = BTCBigNumber(string: "123", base: base)
            print("bn = %@", bn.string(inBase: base))
        }
        
        do {
            let base: UInt = 12
            let bn: BTCBigNumber = BTCBigNumber(string: "0b123", base: base)
            print("bn = %@", bn.string(inBase: base))
        }
        
        do {
            let bn: BTCBigNumber = BTCBigNumber(uInt64: 0xdeadf00ddeadbeef)
            let data: Data = bn.signedLittleEndian
            let bn2: BTCBigNumber = BTCBigNumber(signedLittleEndian: data)
            print("bn = %@", bn2.hexString)
        }
    }
    
    
}
