//
//  BTCTransactionTests.swift
//  CoreBitcoin
//
//  Created by Robert S Mozayeni on 8/10/15.
//  Copyright (c) 2015 Oleg Andreev. All rights reserved.
//

import Cocoa
import XCTest

class BTCTransactionTests: XCTestCase {
    
    enum BTCAPI: UInt {
        case Chain
        case Blockchain
    }
    
    
    func testFees() {
        
        let TransactionDefaultFeeRate: BTCAmount = 10000 //Because Xcode is having trouble with BTCTransactionDefaultFeeRate
        
        XCTAssertEqual(BTCTransaction().estimatedFee, TransactionDefaultFeeRate, "smallest tx must have a fee == default fee rate")
        XCTAssertEqual(BTCTransaction().estimatedFee(withRate: 12345), 12345, "smallest tx must have a fee == fee rate")
        XCTAssertEqual(BTCTransaction().estimatedFee(withRate: 0), 0, "zero fee rate should always yield zero fee")
        
        let tx = BTCTransaction()
        for _ in 0 ..< 10 {
            let txin = BTCTransactionInput()
            txin.previousIndex = 0
            txin.signatureScript = BTCScript()
            txin.signatureScript.appendData(BTCDataWithUTF8CString("A very long text simulating a signature script inside the transaction input."))
            tx.addInput(txin)
        }
        
        XCTAssertEqual(tx.data.count, 1200, "Must be over 1K")
        XCTAssertEqual(tx.estimatedFee, 2 * TransactionDefaultFeeRate, "Must have double the fee rate if there is more than 1000 bytes")
        XCTAssertEqual(tx.estimatedFee(withRate: 123), 246, "Must have double the fee rate if there is more than 1000 bytes")
        XCTAssertEqual(tx.estimatedFee(withRate: 0), 0, "Must have zero fee for zero rate.")
    }
    
    func transactionSpendingFromPrivateKey(privateKey: NSData, destinationAddress: BTCPublicKeyAddress, changeAddress: BTCPublicKeyAddress, amount: BTCAmount, fee: BTCAmount, api: BTCAPI) -> (BTCTransaction?, Error?) {
        
        // 1. Get a private key, destination address, change address and amount
        // 2. Get unspent outputs for that key (using both compressed and non-compressed pubkey)
        // 3. Take the smallest available outputs to combine into the inputs of new transaction
        // 4. Prepare the scripts with proper signatures for the inputs
        // 5. Broadcast the transaction
        
        let key: BTCKey = BTCKey(privateKey: privateKey as Data!)
        
        var errorOut: Error?
        
        
        var getUTXOs: [BTCTransactionOutput]?
        
        switch api {
        case .Blockchain:
            let bci = BTCBlockchainInfo()
            do {
                getUTXOs = try bci.unspentOutputs(withAddresses: [key.compressedPublicKeyAddress]) as? [BTCTransactionOutput]
            }
            catch {
                errorOut = error
            }
        case .Chain:
            let chain: BTCChainCom = BTCChainCom(token: "Free API Token form chain.com")
            do {
                getUTXOs = try chain.unspentOutputs(with: key.compressedPublicKeyAddress) as? [BTCTransactionOutput]
            }
            catch {
                errorOut = error
            }
        }
        
        print("UTXOs for \(key.compressedPublicKeyAddress): \(String(describing: getUTXOs)) \(String(describing: errorOut))")
        
        // Can't download unspent outputs - return with error.
        guard let utxos = getUTXOs?.sorted (by: { $0.value < $1.value }) else { return (nil, errorOut) }
        
        // Find enough outputs to spend the total amount.
        let totalAmount: BTCAmount = amount + fee
        let dustThreshold: BTCAmount = 100000  // don't want less than 1mBTC in the change.
        
        // We need to avoid situation when change is very small. In such case we should leave smallest coin alone and add some bigger one.
        // Ideally, we need to maintain more-or-less binary distribution of coins: having 0.001, 0.002, 0.004, 0.008, 0.016, 0.032, 0.064, 0.128, 0.256, 0.512, 1.024 etc.
        // Another option is to spend a coin which is 2x bigger than amount to be spent.
        // Desire to maintain a certain distribution of change to closely match the spending pattern is the best strategy.
        // Yet another strategy is to minimize both current and future spending fees. Thus, keeping number of outputs low and change sum above "dust" threshold.
        
        // For this test we'll just choose the smallest output.
        
        // 1. Sort outputs by amount
        // 2. Find the output that is bigger than what we need and closer to 2x the amount.
        // 3. If not, find a bigger one which covers the amount + reasonably big change (to avoid dust), but as small as possible.
        // 4. If not, find a combination of two outputs closer to 2x amount from the top.
        // 5. If not, find a combination of two outputs closer to 1x amount with enough change.
        // 6. If not, find a combination of three outputs.
        // Maybe Monte Carlo method is a way to go.
        
        
        // Another way:
        // Find the minimum number of txouts by scanning from the biggest one.
        // Find the maximum number of txouts by scanning from the lowest one.
        // Scan with a minimum window increasing it if needed if no good enough change can be found.
        // Yet another option: finding combinations so the below-the-dust change can go to miners.
        
        
        var getTxouts: [BTCTransactionOutput]?
        
        for txout in utxos {
            if txout.value > (totalAmount + dustThreshold) && txout.script.isPayToPublicKeyHashScript {
                getTxouts = [txout]
                break
            }
        }
        
        // We support spending just one output for now.
        guard let txouts = getTxouts else { return (nil, nil) }
        
        // Create a new transaction
        let tx = BTCTransaction()
        
        var spentCoins = BTCAmount(0)
        
        // Add all outputs as inputs
        for txout in txouts {
            let txin = BTCTransactionInput()
            txin.previousHash = txout.transactionHash
            txin.previousIndex = txout.index
            tx.addInput(txin)
            
            print("txhash: http://blockchain.info/rawtx/\(BTCHexFromData(txout.transactionHash))")
            print("txhash: http://blockchain.info/rawtx/\(BTCHexFromData(BTCReversedData(txout.transactionHash))) (reversed)")
            
            spentCoins += txout.value
        }
        
        print(String(format: "Total satoshis to spend:       %lld", spentCoins))
        print(String(format: "Total satoshis to destination: %lld", amount))
        print(String(format: "Total satoshis to fee:         %lld", fee))
        print(String(format: "Total satoshis to change:      %lld", spentCoins - (amount + fee)))
        
        // Add required outputs - payment and change
        let paymentOutput = BTCTransactionOutput(value: amount, address: destinationAddress)
        let changeOutput = BTCTransactionOutput(value: (spentCoins - (amount + fee)), address: changeAddress)
        
        // Idea: deterministically-randomly choose which output goes first to improve privacy.
        tx.addOutput(paymentOutput)
        tx.addOutput(changeOutput)
        
        for i in 0 ..< txouts.count {
            // Normally, we have to find proper keys to sign this txin, but in this
            // example we already know that we use a single private key.
            
            let txout = txouts[i] // output from a previous tx which is referenced by this txin.
            let txin = tx.inputs[i] as! BTCTransactionInput
            
            let sigScript: BTCScript = BTCScript()
            
            let d1 = tx.data
            
            let hashType = BTCSignatureHashType.SIGHASH_ALL
            
            
            let getHash: Data?
            do {
                getHash = try tx.signatureHash(for: txout.script, inputIndex: UInt32(i), hashType: hashType)
            } catch {
                errorOut = error
                getHash = nil
            }
            
            let d2 = tx.data
            
            XCTAssertEqual(d1, d2, "Transaction must not change within signatureHashForScript!")
            
            // 134675e153a5df1b8e0e0f0c45db0822f8f681a2eb83a0f3492ea8f220d4d3e4
            guard let hash = getHash else { return (nil, errorOut) }
            print(String(format: "Hash for input %d: \(BTCHexFromData(hash))", i))
            let signatureForScript: NSData = key.signature(forHash: hash, hashType: hashType)! as NSData
            sigScript.appendData(signatureForScript as Data!)
            sigScript.appendData(key.publicKey as Data!)
            
            let sig = signatureForScript.subdata(with: NSRange(location: 0, length: signatureForScript.length - 1))
            // trim hashtype byte to check the signature.
            XCTAssertTrue(key.isValidSignature(sig, hash: hash), "Signature must be valid")
            
            txin.signatureScript = sigScript
        }
        
        // Validate the signatures before returning for extra measure.
        
        do {
            let sm: BTCScriptMachine = BTCScriptMachine(transaction: tx, inputIndex: 0)
            
            do {
                try sm.verify(withOutputScript: (txouts.first as BTCTransactionOutput!).script.copy() as! BTCScript)
            } catch {
                print("Error: \(error)")
                XCTFail("should verify first output")
            }
            
            
        }
        
        // Transaction is signed now, return it.
        
        return (tx, errorOut)
    }
    
    
    func spendCoinTestWithAPI(api: BTCAPI) { //Not prefixed with `test` because we don't want Xcode to try and call it
        let privStr = ""
        let str: UnsafeMutablePointer<Int8> = UnsafeMutablePointer<Int8>(mutating: (privStr as NSString).utf8String!)
        
        // For safety I'm not putting a private key in the source code, but copy-paste here from Keychain on each run.
        print("Please paste a private key for coin spend test, or 'x' to skip this test.\n")
        gets(str)
        
        if str.pointee == 120 { //Skips test if 'x' is entered instead of private key
            return
        }
        
        let privateKey: Data = BTCDataWithHexCString(str)
        print("Private key: \(String(describing: privateKey))")
        
        let key: BTCKey = BTCKey(privateKey: privateKey)
        
        print("Address: \(key.compressedPublicKeyAddress)")
        
        XCTAssertEqual("1TipsuQ7CSqfQsjA9KU5jarSB1AnrVLLo", key.compressedPublicKeyAddress.string, "WARNING: incorrect private key is supplied")
        
        
        let (transaction, error) = self.transactionSpendingFromPrivateKey(privateKey: privateKey as NSData,
                                                                          destinationAddress: BTCPublicKeyAddress(string: "1A3tnautz38PZL15YWfxTeh8MtuMDhEPVB")!, changeAddress: key.compressedPublicKeyAddress, amount: 100000, fee: 0, api: api)
        
        XCTAssertNotNil(transaction, "Can't make a transaction: \(String(describing: error))")
        
        print("transaction = \(String(describing: transaction?.dictionary))")
        print("transaction in hex:\n------------------\n\(BTCHexFromData(transaction?.data))\n------------------\n")
        
        print("Sending in 5 sec...")
        sleep(5)
        print("Sending...")
        sleep(1)
        
        let req = BTCChainCom(token: "Free API Token form chain.com").requestForTransactionBroadcast(with: transaction!.data)
        let data = try? NSURLConnection.sendSynchronousRequest(req! as URLRequest, returning: nil)
        
        print("Broadcast result: data = \(String(describing: data))")
        print("string = \(String(describing: NSString(data: data!, encoding: String.Encoding.utf8.rawValue)))")
        
        
    }
    
//    func testSpendCoins() {
//        spendCoinTestWithAPI(.Chain)
//        spendCoinTestWithAPI(.Blockchain)
//    }

}

