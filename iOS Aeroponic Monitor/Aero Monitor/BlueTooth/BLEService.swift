//
//  BLEService.swift
//  Aero Monitor
//
//  Created by DoodleBytes Development on 6/7/17.
//  Copyright © 2017 DoodleBytes Development. All rights reserved.
//

import Foundation
import CoreBluetooth


class BLEService: NSObject {
    weak var manager: BLEManager? = nil 
    weak var peripheral: BLEPeripheral? = nil 

    var uuid: CBUUID?
    var service: CBService? {
        get {
            guard let uuid: CBUUID = self.uuid else { return nil }
            if let rawServices: [CBUUID: CBService] = self.peripheral?.rawServices {
                return rawServices[uuid]
            }
            return nil 
        }
    }
    
    var rawCharacteristics: [CBUUID: CBCharacteristic] {
        var c: [CBUUID: CBCharacteristic] = [:]
        if let rc: [CBCharacteristic] = self.service?.characteristics {
            for char: CBCharacteristic in rc {
                c[char.uuid] = char 
            }
        }
        return c 
    }
    
    var characteristics: [CBUUID: BLECharacteristic] = [CBUUID: BLECharacteristic]()
    subscript( uuid: CBUUID ) -> BLECharacteristic? {
        get {
            return self.characteristics[uuid]
        }
        set(v) {
            self.characteristics[uuid] = v 
        }
    }
    
    override init() {
        super.init()
        
    }
    
    convenience init( coreService service: CBService ) {
        self.init()
        
        self.uuid = service.uuid
    }

    
}













