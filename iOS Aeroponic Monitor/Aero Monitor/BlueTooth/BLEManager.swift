//
//  BLEManager.swift
//  Aero Monitor
//
//  Created by DoodleBytes Development on 6/5/17.
//  Copyright © 2017 DoodleBytes Development. All rights reserved.
//

import Foundation
import CoreBluetooth


var serviceUUIDs: [CBUUID] = [CBUUID]() {
    didSet {
        
    }
}
var serviceIDs: [String] = [String]() {
    didSet {
        var us: [CBUUID] = [CBUUID]()
        for s in serviceIDs {
            let uuid: CBUUID = CBUUID(string: s)
            us.append(uuid)
        }
        serviceUUIDs = us 
    }
}



class BLEManager: NSObject, CBCentralManagerDelegate {
    
    static let sharedManager: BLEManager = BLEManager()
    
    var uiCallback: ((_ manager: BLEManager, _ peripherals: [BLEPeripheral], _ selected: BLEPeripheral?) -> Void)?
    
    
    var cbCentral: CBCentralManager!
    var peripherals: [UUID: BLEPeripheral] = [UUID: BLEPeripheral]()
    
    var peripheralsArray: [BLEPeripheral] {
        var elements: [BLEPeripheral] = [BLEPeripheral]()
        for (_, peripheral) in self.peripherals {
            elements.append(peripheral)
        }
        return elements 
    }
    var selectedPeripheral: BLEPeripheral? = nil 
    
    override init() {
        super.init() 
        
        self.cbCentral = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
        
    /*!
     *  @method centralManagerDidUpdateState:
     *
     *  @param central  The central manager whose state has changed.
     *
     *  @discussion     Invoked whenever the central manager's state has been updated. Commands should only be issued when the state is
     *                  <code>CBCentralManagerStatePoweredOn</code>. A state below <code>CBCentralManagerStatePoweredOn</code>
     *                  implies that scanning has stopped and any connected peripherals have been disconnected. If the state moves below
     *                  <code>CBCentralManagerStatePoweredOff</code>, all <code>CBPeripheral</code> objects obtained from this central
     *                  manager become invalid and must be retrieved or discovered again.
     *
     *  @see            state
     *
     */
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            
        case .poweredOn: 
            print("centralManagerDidUpdateState()   powered on")
            print("    ids: \(serviceUUIDs)")
            self.cbCentral.scanForPeripherals(withServices: serviceUUIDs, options: nil)
            break 
            
        case .poweredOff: 
            print("centralManagerDidUpdateState()   powered off")
            break 
            
        case .unsupported: 
            print("centralManagerDidUpdateState()   unsupported")
            break 
            
        case .unknown: 
            print("centralManagerDidUpdateState()   unknown")
            break 
            
        case .unauthorized: 
            print("centralManagerDidUpdateState()   unauthorized")
            break
            
        case .resetting: 
            print("centralManagerDidUpdateState()   resetting")
            break 
            
        }
    }
    
    
    /*!
     *  @method centralManager:willRestoreState:
     *
     *  @param central      The central manager providing this information.
     *  @param dict			A dictionary containing information about <i>central</i> that was preserved by the system at the time the app was terminated.
     *
     *  @discussion			For apps that opt-in to state preservation and restoration, this is the first method invoked when your app is relaunched into
     *						the background to complete some Bluetooth-related task. Use this method to synchronize your app's state with the state of the
     *						Bluetooth system.
     *
     *  @seealso            CBCentralManagerRestoredStatePeripheralsKey;
     *  @seealso            CBCentralManagerRestoredStateScanServicesKey;
     *  @seealso            CBCentralManagerRestoredStateScanOptionsKey;
     *
     */
//    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
//        
//    }
    
    
    /*!
     *  @method centralManager:didDiscoverPeripheral:advertisementData:RSSI:
     *
     *  @param central              The central manager providing this update.
     *  @param peripheral           A <code>CBPeripheral</code> object.
     *  @param advertisementData    A dictionary containing any advertisement and scan response data.
     *  @param RSSI                 The current RSSI of <i>peripheral</i>, in dBm. A value of <code>127</code> is reserved and indicates the RSSI
     *								was not available.
     *
     *  @discussion                 This method is invoked while scanning, upon the discovery of <i>peripheral</i> by <i>central</i>. A discovered peripheral must
     *                              be retained in order to use it; otherwise, it is assumed to not be of interest and will be cleaned up by the central manager. For
     *                              a list of <i>advertisementData</i> keys, see {@link CBAdvertisementDataLocalNameKey} and other similar constants.
     *
     *  @seealso                    CBAdvertisementData.h
     *
     */
    
    let k_ignored_peripherals: [UUID] = [
        UUID(uuidString: "F9574ED2-5BEA-419A-8F56-64F226819ACD")!
    ]
    
    
    private func checkForServices() {
        if self.isScanning {
            self.isScanning = false 
            self.cbCentral.stopScan()
            print("STOPPED SCANNING")
            for (identifier, peripheral) in self.peripherals {
                if !peripheral.connected {
                    print("CONNECTING: \(identifier)")
                    self.cbCentral.connect(peripheral.peripheral, options: nil)
                }
            }
            self.uiCallback?(self, self.peripheralsArray, self.selectedPeripheral)
            
            DispatchQueue.main.asyncAfter(deadline: .now()+10.0, execute: {
                self.cbCentral.scanForPeripherals(withServices: nil, options: nil)
            })
        }
    }
    
    var isScanning: Bool = true 
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("centralManager(central: \(central), didDiscover peripheral: \(peripheral), advertisementData: \(advertisementData), rssi RSSI: \(RSSI))")
        
        if let _: BLEPeripheral = self.peripherals[peripheral.identifier] {
            DispatchQueue.main.asyncAfter(deadline: .now()+2.0, execute: {
                self.checkForServices()
            })
        } else {
            let p: BLEPeripheral = BLEPeripheral(corePeripheral: peripheral)
            p.manager = self 
            self.peripherals[peripheral.identifier] = p 
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()+10.0, execute: {
            self.checkForServices()
        })
    }
    
    
    /*!
     *  @method centralManager:didConnectPeripheral:
     *
     *  @param central      The central manager providing this information.
     *  @param peripheral   The <code>CBPeripheral</code> that has connected.
     *
     *  @discussion         This method is invoked when a connection initiated by {@link connectPeripheral:options:} has succeeded.
     *
     */
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let p: BLEPeripheral = self.peripherals[peripheral.identifier] {
            p.connected = true
            p.manager = self 
            print("CONNECTED: \(peripheral.identifier)")
        }
    }
    
    
    /*!
     *  @method centralManager:didFailToConnectPeripheral:error:
     *
     *  @param central      The central manager providing this information.
     *  @param peripheral   The <code>CBPeripheral</code> that has failed to connect.
     *  @param error        The cause of the failure.
     *
     *  @discussion         This method is invoked when a connection initiated by {@link connectPeripheral:options:} has failed to complete. As connection attempts do not
     *                      timeout, the failure of a connection is atypical and usually indicative of a transient issue.
     *
     */
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
    }
    
    
    /*!
     *  @method centralManager:didDisconnectPeripheral:error:
     *
     *  @param central      The central manager providing this information.
     *  @param peripheral   The <code>CBPeripheral</code> that has disconnected.
     *  @param error        If an error occurred, the cause of the failure.
     *
     *  @discussion         This method is invoked upon the disconnection of a peripheral that was connected by {@link connectPeripheral:options:}. If the disconnection
     *                      was not initiated by {@link cancelPeripheralConnection}, the cause will be detailed in the <i>error</i> parameter. Once this method has been
     *                      called, no more methods will be invoked on <i>peripheral</i>'s <code>CBPeripheralDelegate</code>.
     *
     */
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let p: BLEPeripheral = self.peripherals[peripheral.identifier] {
            p.connected = false
            p.manager = nil 
            self.peripherals.removeValue(forKey: peripheral.identifier)
            print("DISCONNECTED: \(peripheral.identifier)")
        }
    }
    
}















