//
//  BLEPeripheral.swift
//  Aero Monitor
//
//  Created by DoodleBytes Development on 6/6/17.
//  Copyright © 2017 DoodleBytes Development. All rights reserved.
//

import Foundation
import CoreBluetooth


class BLEPeripheral: NSObject, CBPeripheralDelegate {
    
    weak var manager: BLEManager? = nil 
    
    var peripheral: CBPeripheral!
    var name: String = ""
    var identifier: UUID!
    
    var hasTargetService: Bool {
        if let services: [CBService] = self.peripheral.services {
            for service in services {
                if serviceUUIDs.contains(service.uuid) { return true }
            }
        }
        return false 
    }    
    
    override init() {
        super.init()
        
    }
    
    convenience init( corePeripheral peripheral: CBPeripheral ) {
        self.init()
        
        self.peripheral = peripheral
        if let n: String = peripheral.name {
            self.name = n
        }
        self.identifier = peripheral.identifier
        
        peripheral.delegate = self 
    }
    
    
    
    
    var connected: Bool = false {
        didSet {
            if self.connected {
                self.peripheral.discoverServices(nil)
            }
        }
    }
    
    
    var rawServices: [CBUUID: CBService] {
        var s: [CBUUID: CBService] = [:]
        if let rs: [CBService] = self.peripheral.services {
            for svc: CBService in rs {
                s[svc.uuid] = svc 
            }
        }
        return s 
    }
    
    
    var services: [CBUUID: BLEService] = [CBUUID: BLEService]() 
    subscript( uuid: CBUUID ) -> BLEService? {
        get {
            return self.services[uuid]
        }
        set(v) {
            self.services[uuid] = v 
        }
    }
    
    
    
    var readCallbacks: [CBUUID: ((_ data: Data?) -> Void)] = [:] 
    func read( _ characteristic: CBCharacteristic, completion: @escaping ((_ data: Data?) -> Void) ) {  
        self.readCallbacks[characteristic.uuid] = completion 
        peripheral.readValue(for: characteristic)
        completion(characteristic.value)
    }
    
    
    
    /*!
     *  @method peripheralDidUpdateName:
     *
     *  @param peripheral	The peripheral providing this update.
     *
     *  @discussion			This method is invoked when the @link name @/link of <i>peripheral</i> changes.
     */
    //@available(iOS 6.0, *)
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        print("\n\nBLEPeripheral.peripheralDidUpdateName(_ peripheral: \(peripheral))\n")
    }
    
    
    /*!
     *  @method peripheral:didModifyServices:
     *
     *  @param peripheral			The peripheral providing this update.
     *  @param invalidatedServices	The services that have been invalidated
     *
     *  @discussion			This method is invoked when the @link services @/link of <i>peripheral</i> have been changed.
     *						At this point, the designated <code>CBService</code> objects have been invalidated.
     *						Services can be re-discovered via @link discoverServices: @/link.
     */
    //@available(iOS 7.0, *)
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("\n\nBLEPeripheral.peripheral(_ peripheral: \(peripheral), didModifyServices invalidatedServices: [CBService])\n")
    }
    
    
    /*!
     *  @method peripheralDidUpdateRSSI:error:
     *
     *  @param peripheral	The peripheral providing this update.
     *	@param error		If an error occurred, the cause of the failure.
     *
     *  @discussion			This method returns the result of a @link readRSSI: @/link call.
     *
     *  @deprecated			Use {@link peripheral:didReadRSSI:error:} instead.
     */
    //@available(iOS, introduced: 5.0, deprecated: 8.0)
    public func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
        
    }
    
    
    /*!
     *  @method peripheral:didReadRSSI:error:
     *
     *  @param peripheral	The peripheral providing this update.
     *  @param RSSI			The current RSSI of the link.
     *  @param error		If an error occurred, the cause of the failure.
     *
     *  @discussion			This method returns the result of a @link readRSSI: @/link call.
     */
    //@available(iOS 8.0, *)
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        
    }
    
    
    /*!
     *  @method peripheral:didDiscoverServices:
     *
     *  @param peripheral	The peripheral providing this information.
     *	@param error		If an error occurred, the cause of the failure.
     *
     *  @discussion			This method returns the result of a @link discoverServices: @/link call. If the service(s) were read successfully, they can be retrieved via
     *						<i>peripheral</i>'s @link services @/link property.
     *
     */
    //@available(iOS 5.0, *)
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("\n\n-------------------------------------------------------\nBLEPeripheral.peripheral(_ peripheral: \(peripheral), didDiscoverServices error: \(error))\n")
        if let services: [CBService] = self.peripheral.services {
            for service in services {
                print("    Service: \(service)")
                if service.uuid == k_leaf_sensor_service { 
                    let bleService: BLEService = BLEService(coreService: service)
                    bleService.manager = self.manager
                    bleService.peripheral = self 
                    self[service.uuid] = bleService
                    self.peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
        print("-------------------------------------------------------\n\n")
    }
    
    
    /*!
     *  @method peripheral:didDiscoverIncludedServicesForService:error:
     *
     *  @param peripheral	The peripheral providing this information.
     *  @param service		The <code>CBService</code> object containing the included services.
     *	@param error		If an error occurred, the cause of the failure.
     *
     *  @discussion			This method returns the result of a @link discoverIncludedServices:forService: @/link call. If the included service(s) were read successfully, 
     *						they can be retrieved via <i>service</i>'s <code>includedServices</code> property.
     */
    //@available(iOS 5.0, *)
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        
    }
    
    
    /*!
     *  @method peripheral:didDiscoverCharacteristicsForService:error:
     *
     *  @param peripheral	The peripheral providing this information.
     *  @param service		The <code>CBService</code> object containing the characteristic(s).
     *	@param error		If an error occurred, the cause of the failure.
     *
     *  @discussion			This method returns the result of a @link discoverCharacteristics:forService: @/link call. If the characteristic(s) were read successfully, 
     *						they can be retrieved via <i>service</i>'s <code>characteristics</code> property.
     */
    //@available(iOS 5.0, *)
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("\n\n-------------------------------------------------------\nBLEPeripheral.peripheral(_ peripheral: \(peripheral), didDiscoverCharacteristicsFor service: \(service), error: \(error))\n")
        if let bleService: BLEService = self[service.uuid] {
            if let characteristics: [CBCharacteristic] = service.characteristics {
                for characteristic in characteristics {
                    let bleCharacteristic: BLECharacteristic = BLECharacteristic(coreService: characteristic)
                    bleService[characteristic.uuid] = bleCharacteristic
                    bleService.manager = self.manager
                    bleService.peripheral = self 
                    
                    bleCharacteristic.manager = self.manager
                    bleCharacteristic.peripheral = self 
                    bleCharacteristic.service = bleService 
                    
                    if( bleCharacteristic.canNotify ) {
                        self.peripheral.setNotifyValue(true, for: characteristic)
                    }
                    
                    print("        characteristic: \(bleCharacteristic.description)")
                    self.peripheral.discoverDescriptors(for: characteristic)
                }
            }
        }
        print("-------------------------------------------------------\n\n")
    }
    
    
    /*!
     *  @method peripheral:didUpdateValueForCharacteristic:error:
     *
     *  @param peripheral		The peripheral providing this information.
     *  @param characteristic	A <code>CBCharacteristic</code> object.
     *	@param error			If an error occurred, the cause of the failure.
     *
     *  @discussion				This method is invoked after a @link readValueForCharacteristic: @/link call, or upon receipt of a notification/indication.
     */
    //@available(iOS 5.0, *)
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("\n\nBLEPeripheral.peripheral(_ peripheral: \(peripheral), didUpdateValueFor characteristic: \(characteristic), error: Error?)\n")
        
        if let callback: ((_ data: Data?) -> Void) = self.readCallbacks[characteristic.uuid] {
            callback(characteristic.value)
        }

    }
    
    
    /*!
     *  @method peripheral:didWriteValueForCharacteristic:error:
     *
     *  @param peripheral		The peripheral providing this information.
     *  @param characteristic	A <code>CBCharacteristic</code> object.
     *	@param error			If an error occurred, the cause of the failure.
     *
     *  @discussion				This method returns the result of a {@link writeValue:forCharacteristic:type:} call, when the <code>CBCharacteristicWriteWithResponse</code> type is used.
     */
    //@available(iOS 5.0, *)
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("\n\nBLEPeripheral.peripheral(_ peripheral: \(peripheral),  didWriteValueFor characteristic: CBCharacteristic, error: Error?)\n")
    }
    
    
    /*!
     *  @method peripheral:didUpdateNotificationStateForCharacteristic:error:
     *
     *  @param peripheral		The peripheral providing this information.
     *  @param characteristic	A <code>CBCharacteristic</code> object.
     *	@param error			If an error occurred, the cause of the failure.
     *
     *  @discussion				This method returns the result of a @link setNotifyValue:forCharacteristic: @/link call. 
     */
    //@available(iOS 5.0, *)
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("\n\nBLEPeripheral.peripheral(_ peripheral: \(peripheral), didUpdateNotificationStateFor characteristic: \(characteristic), error: Error?)\n")
    }
    
    
    /*!
     *  @method peripheral:didDiscoverDescriptorsForCharacteristic:error:
     *
     *  @param peripheral		The peripheral providing this information.
     *  @param characteristic	A <code>CBCharacteristic</code> object.
     *	@param error			If an error occurred, the cause of the failure.
     *
     *  @discussion				This method returns the result of a @link discoverDescriptorsForCharacteristic: @/link call. If the descriptors were read successfully, 
     *							they can be retrieved via <i>characteristic</i>'s <code>descriptors</code> property.
     */
    //@available(iOS 5.0, *)
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("\n\n-------------------------------------------------------\nBLEPeripheral.peripheral(_ peripheral: \(peripheral), didDiscoverDescriptorsFor characteristic: \(characteristic), error: \(error))\n")
        if let descriptors: [CBDescriptor] = characteristic.descriptors {
            for descriptor in descriptors {
                print("            descriptor: \(descriptor)")
            }
        }
        print("-------------------------------------------------------\n\n")
    }
    
    
    /*!
     *  @method peripheral:didUpdateValueForDescriptor:error:
     *
     *  @param peripheral		The peripheral providing this information.
     *  @param descriptor		A <code>CBDescriptor</code> object.
     *	@param error			If an error occurred, the cause of the failure.
     *
     *  @discussion				This method returns the result of a @link readValueForDescriptor: @/link call.
     */
    //@available(iOS 5.0, *)
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("\n\nBLEPeripheral.peripheral(_ peripheral: \(peripheral), didUpdateValueFor descriptor: CBDescriptor, error: Error?)\n")
    }
    
    
    /*!
     *  @method peripheral:didWriteValueForDescriptor:error:
     *
     *  @param peripheral		The peripheral providing this information.
     *  @param descriptor		A <code>CBDescriptor</code> object.
     *	@param error			If an error occurred, the cause of the failure.
     *
     *  @discussion				This method returns the result of a @link writeValue:forDescriptor: @/link call.
     */
    //@available(iOS 5.0, *)
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("\n\nBLEPeripheral.peripheral(_ peripheral: \(peripheral), didWriteValueFor descriptor: CBDescriptor, error: Error?)\n")
    }
    
    
    
    
    
}
























