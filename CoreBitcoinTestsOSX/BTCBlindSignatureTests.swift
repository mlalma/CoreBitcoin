//
//  BTCBlindSignatureTests.swift
//  CoreBitcoin
//
//  Created by Robert S Mozayeni on 5/21/15.
//  Copyright (c) 2015 Oleg Andreev. All rights reserved.
//

import Cocoa
import XCTest

class BTCBlindSignatureTests: XCTestCase {
    
    func testCoreAlgorithm() {
        
        let api = BTCBlindSignature()
        
        let a = BTCBigNumber(unsignedBigEndian: BTCHash256("a".data(using: String.Encoding.utf8, allowLossyConversion: false)) as Data!)
        let b = BTCBigNumber(unsignedBigEndian: BTCHash256("b".data(using: String.Encoding.utf8, allowLossyConversion: false)) as Data!)
        let c = BTCBigNumber(unsignedBigEndian: BTCHash256("c".data(using: String.Encoding.utf8, allowLossyConversion: false)) as Data!)
        let d = BTCBigNumber(unsignedBigEndian: BTCHash256("d".data(using: String.Encoding.utf8, allowLossyConversion: false)) as Data!)
        let p = BTCBigNumber(unsignedBigEndian: BTCHash256("p".data(using: String.Encoding.utf8, allowLossyConversion: false)) as Data!)
        let q = BTCBigNumber(unsignedBigEndian: BTCHash256("q".data(using: String.Encoding.utf8, allowLossyConversion: false)) as Data!)
        
        let PQ = api.bob_P_and_Q_(for_p: p, q: q) as! [BTCCurvePoint]
        let P = PQ.first!
        let Q = PQ.last!
        
        XCTAssertNotNil(P, "sanity check")
        XCTAssertNotNil(Q, "sanity check")
        
        let KT = api.alice_K_and_T_(for_a: a, b: b, c: c, d: d, p: P, q: Q) as! [BTCCurvePoint]
        let K = KT.first!
        let T = KT.last!
        
        XCTAssertNotNil(K, "sanity check")
        XCTAssertNotNil(T, "sanity check")
        
        // In real life we'd use T in a destination script and keep K.x around for redeeming it later.
        // ...
        // It's time to redeem funds! Lets do it by asking Bob to sign stuff for Alice.
        
        let hash = BTCHash256("some transaction".data(using: String.Encoding.utf8, allowLossyConversion: false))
        
        // Alice computes and sends to Bob.
        let blindedHash = api.aliceBlindedHash(forHash: BTCBigNumber(unsignedBigEndian: hash! as Data), a: a, b: b)
        
        XCTAssertNotNil(blindedHash, "sanity check")
        
        // Bob computes and sends to Alice.
        let blindedSig = api.bobBlindedSignature(forHash: blindedHash, p: p, q: q)
        
        XCTAssertNotNil(blindedSig, "sanity check")
        
        // Alice unblinds and uses in the final signature.
        let unblindedSignature = api.aliceUnblindedSignature(forSignature: blindedSig, c: c, d: d)
        
        XCTAssertNotNil(unblindedSignature, "sanity check")
        
        let finalSignature = api.aliceComplete(forKx: K.x, unblindedSignature: unblindedSignature)
        
        XCTAssertNotNil(finalSignature, "sanity check")
        
        let pubkey: BTCKey = BTCKey(curvePoint: T)
        XCTAssertTrue(pubkey.isValidSignature(finalSignature, hash: hash! as Data), "should have created a valid signature after all that trouble")
        
    }
    
    
    func testConvenienceAPI() {
        let aliceKeychain: BTCKeychain = BTCKeychain(seed: "Alice".data(using: String.Encoding.utf8, allowLossyConversion: false))
        let bobKeychain: BTCKeychain = BTCKeychain(seed: "Bob".data(using: String.Encoding.utf8, allowLossyConversion: false))
        let bobPublicKeychain = BTCKeychain(extendedKey: bobKeychain.extendedPublicKey)
        
        XCTAssertNotNil(aliceKeychain, "sanity check")
        XCTAssertNotNil(bobKeychain, "sanity check")
        XCTAssertNotNil(bobPublicKeychain, "sanity check")
        
        let alice: BTCBlindSignature = BTCBlindSignature(clientKeychain: aliceKeychain, custodianKeychain: bobPublicKeychain)
        let bob: BTCBlindSignature = BTCBlindSignature(custodianKeychain: bobKeychain)
        
        XCTAssertNotNil(alice, "sanity check")
        XCTAssertNotNil(bob, "sanity check")
        
        for j: uint32 in 0...31 {
            let i: uint32 = j
            // This will be Alice's pubkey that she can use in a destination script.
            let pubkey: BTCKey = alice.publicKey(at: i)
            XCTAssertNotNil(pubkey, "sanity check")
            
//            println("pubkey = \(pubkey)")
            
            // This will be a hash of Alice's transaction.
            let hash = BTCHash256("transaction \(i)".data(using: String.Encoding.utf8, allowLossyConversion: false))
            
//            println("hash = \(hash)")
            
            // Alice will send this to Bob.
            let blindedHash = alice.blindedHash(forHash: hash! as Data, index: i)
            XCTAssertNotNil(blindedHash, "sanity check")
            
            // Bob computes the signature for Alice and sends it back to her.
            let blindSig = bob.blindSignature(forBlindedHash: blindedHash)
            XCTAssertNotNil(blindSig, "sanity check")
            
            // Alice receives the blind signature and computes the complete ECDSA signature ready to use in a redeeming transaction.
            let finalSig = alice.unblindedSignature(forBlindSignature: blindSig, verifyHash: hash! as Data)
            XCTAssertNotNil(finalSig, "sanity check")
            
            XCTAssertTrue(pubkey.isValidSignature(finalSig, hash: hash! as Data),
                          "Check that the resulting signature is valid for our original hash and pubkey.")
        }
    }
}
