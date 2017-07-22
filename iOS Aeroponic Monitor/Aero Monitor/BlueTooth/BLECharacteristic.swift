//
//  BLECharacteristic.swift
//  Aero Monitor
//
//  Created by DoodleBytes Development on 6/7/17.
//  Copyright © 2017 DoodleBytes Development. All rights reserved.
//

import Foundation
import CoreBluetooth




class BLECharacteristic: NSObject {
    weak var manager: BLEManager? = nil 
    weak var peripheral: BLEPeripheral? = nil 
    weak var service: BLEService? = nil 
    
    var subsribe: Bool = false {
        didSet {
            
        }
    }
    
    var uuid: CBUUID?
    var characteristic: CBCharacteristic? {
        get {
            guard let uuid: CBUUID = self.uuid else { return nil }
            if let rawCharacteristics: [CBUUID: CBCharacteristic] = self.service?.rawCharacteristics {
                return rawCharacteristics[uuid]
            }
            return nil 
        }
    }
    
    var canWrite: Bool { 
        guard let characteristic: CBCharacteristic = self.characteristic else { return false }
        return characteristic.properties.contains(.write) 
    }
    var canWriteWithoutResponse: Bool { 
        guard let characteristic: CBCharacteristic = self.characteristic else { return false }
        return characteristic.properties.contains(.writeWithoutResponse) 
    }
    var canRead: Bool { 
        guard let characteristic: CBCharacteristic = self.characteristic else { return false }
        return characteristic.properties.contains(.read) 
    }
    var canNotify: Bool { 
        guard let characteristic: CBCharacteristic = self.characteristic else { return false }
        return characteristic.properties.contains(.notify) 
    }
    
    override init() {
        super.init()
        
    }
    
    convenience init( coreService characteristic: CBCharacteristic ) {
        self.init()
        
        self.uuid = characteristic.uuid
    }
    
    override var description: String {
        guard let properties: CBCharacteristicProperties = self.characteristic?.properties else { return "<BLECharacteristic: \(String(describing: self.uuid?.uuidString))>" }
        var ps: String = "<BLECharacteristic: \(String(describing: self.uuid?.uuidString)) properties: ( "
        if properties.contains(.broadcast) { ps += "broadcast " }
        if properties.contains(.read) { ps += "read " }
        if properties.contains(.writeWithoutResponse) { ps += "writeWithoutResponse " }
        if properties.contains(.write) { ps += "write " }
        if properties.contains(.notify) { ps += "notify " }
        if properties.contains(.indicate) { ps += "indicate " }
        if properties.contains(.authenticatedSignedWrites) { ps += "authenticatedSignedWrites " }
        if properties.contains(.extendedProperties) { ps += "extendedProperties " }
        if properties.contains(.notifyEncryptionRequired) { ps += "notifyEncryptionRequired " }
        if properties.contains(.indicateEncryptionRequired) { ps += "indicateEncryptionRequired " }
        ps += ")>"
        return ps
    }
    
    
    
    
    
    
    
    
    
    
    func setReadCompletion(_ completion: @escaping ((_ data: Data?) -> Void) ) {
        guard let characteristic: CBCharacteristic = self.characteristic else { return }
        self.peripheral?.readCallbacks[characteristic.uuid] = completion
    }
    
    
    func read( completion: @escaping ((_ data: Data?) -> Void) ) {
        guard let characteristic: CBCharacteristic = self.characteristic else { 
            print("BLECharacteristic.read ERROR: NO CBCharacteristic")
            return 
        }
        guard let peripheral: CBPeripheral = self.peripheral?.peripheral else { 
            print("BLECharacteristic.read ERROR: NO CBPeripheral")
            return 
        }
        
        peripheral.setNotifyValue(true, for: characteristic)
        
        self.peripheral?.read(characteristic, completion: completion)
    }
    
    
    func write( value data: Data? ) {
        guard let data: Data = data else { return } 
        guard let characteristic: CBCharacteristic = self.characteristic else { return }
        guard let peripheral: CBPeripheral = self.peripheral?.peripheral else { return }
        
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
    }

    
    func sendCommand( command cmd: UInt8, data: UInt32 ) {
        guard let characteristic: CBCharacteristic = self.characteristic else { return }
        guard let peripheral: CBPeripheral = self.peripheral?.peripheral else { return }
        
        var bytes: Data = Data(bytes: [cmd])
        var data: UInt32 = data
        withUnsafePointer(to: &data) { 
            (d: UnsafePointer<UInt32>) -> Void in
            bytes.append(UnsafeBufferPointer(start: d, count: 1))
        }
        peripheral.writeValue(bytes, for: characteristic, type: .withoutResponse)
    }
    
    
}



/*
 
 
 public static var broadcast: CBCharacteristicProperties { get }
 
 public static var read: CBCharacteristicProperties { get }
 
 public static var writeWithoutResponse: CBCharacteristicProperties { get }
 
 public static var write: CBCharacteristicProperties { get }
 
 public static var notify: CBCharacteristicProperties { get }
 
 public static var indicate: CBCharacteristicProperties { get }
 
 public static var authenticatedSignedWrites: CBCharacteristicProperties { get }
 
 public static var extendedProperties: CBCharacteristicProperties { get }
 
 @available(iOS 6.0, *)
 public static var notifyEncryptionRequired: CBCharacteristicProperties { get }
 
 @available(iOS 6.0, *)
 public static var indicateEncryptionRequired: CBCharacteristicProperties { get }
 
 
 */














