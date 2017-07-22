//
//  ControllerDetailTableViewController.swift
//  Aero Monitor
//
//  Created by DoodleBytes Development on 6/21/17.
//  Copyright © 2017 DoodleBytes Development. All rights reserved.
//

import UIKit
import CoreBluetooth


let k_log_item_cell_id = "LogItemCell"

class ControllerDetailTableViewController: AbstractPeripheralTableViewController {
    
    @IBOutlet weak var controllerName: UITextField?
    
    @IBOutlet weak var controllerUUID: UILabel?
    
    var logHistory: [HistoryItem] = []
    
    var activityIndicator: UIActivityIndicatorView?
    func showActivityIndicator() {
        DispatchQueue.main.async {
            if self.activityIndicator == nil {
                self.activityIndicator = self.view.activityIndicatorView
            }
            self.activityIndicator?.isHidden = false 
            self.activityIndicator?.startAnimating()
        }
    }
    
    func hideActivityIndicator() {
        DispatchQueue.main.async {
            self.activityIndicator?.stopAnimating()
        }
    }

    override func updateUI() {
        if let peripheral: BLEPeripheral = self.peripheral {
            self.updatingUI = true;
            
            self.controllerName?.text = peripheral.name
            self.controllerUUID?.text = peripheral.identifier.uuidString 

            self.showActivityIndicator()
            self.logHistory = []
            peripheral.getCurrentData(completion: { 
                (data: Data) in
                
                //if !self.updatingUI { return }

                let item: HistoryItem = data.withUnsafeBytes() { 
                    (ptr: UnsafePointer<HistoryItem>) -> HistoryItem in
                    return ptr.pointee
                }
                
                print("item: <\(item)>")
                
                if item.isValid {
                    self.logHistory.append(item)
                } else {
                    // we're done being sent data
                    self.updatingUI = false;
                    self.hideActivityIndicator()
                    self.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    @IBAction func doSpray( _ sender: UIButton ) {
        self.peripheral?.triggerSpray()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(updateUI), for: .valueChanged)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.updateUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.logHistory.count
    }
    
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let h: [HistoryItem] = self.logHistory
        let i: Int = indexPath.row 
        let cell = tableView.dequeueReusableCell(withIdentifier: k_log_item_cell_id, for: indexPath)
        if h.count == 0 || i >= h.count { return cell }
        
        if let logItemCell: LogItemCell = cell as? LogItemCell {
            logItemCell.peripheral = self.peripheral
            logItemCell.logItem = h[i]
        }
     
        return cell
     }
    
}





let k_leaf_sensor_service: CBUUID = CBUUID(string: "E0020000-6ACD-420E-AFA9-6B467BD818DD")   //CBUUID(string: "E0020001-6ACD-420E-AFA9-6B467BD818DD")
let k_leaf_sensor_command: CBUUID = CBUUID(string: "E0020003-6ACD-420E-AFA9-6B467BD818DD")
let k_leaf_sensor_data: CBUUID = CBUUID(string: "E0020002-6ACD-420E-AFA9-6B467BD818DD")


let k_send_log_command: UInt8 = 1
let k_send_values_command: UInt8 = 2

let k_command_open_valve: UInt8 = 10
let k_set_current_timestamp: UInt8 = 15



extension BLECharacteristic {
    
    
    
}





struct FlagOptions: OptionSet {
    let rawValue: UInt8
    
    static let inUse = FlagOptions(rawValue: 1)
    static let leafSensorConnected = FlagOptions(rawValue: 1<<1)
    static let leafSensorTriggered = FlagOptions(rawValue: 1<<2)
    
    static let day = FlagOptions(rawValue: 1<<5)
    static let partCloudy = FlagOptions(rawValue: 1<<6)
    static let cloudy = FlagOptions(rawValue: 1<<7)    
}

struct HistoryItem {
    var _flags: FlagOptions = FlagOptions(rawValue: 0)
    
    var _interval: UInt8 = 0 //minutes * 4
    var _leaf_sensor_value: UInt16 = 0
    var _root_temp: UInt8 = 0 // degrees C
    var _leaf_temp: UInt8 = 0 // degreas C
    
    // return interval in seconds converted from minutes*4
    var interval: TimeInterval {
        let seconds: Double = 60.0 * Double(self._interval) / 4.0
        return TimeInterval(seconds)
    }
    
    var isValid: Bool {
        return self._flags.contains(.inUse)
    }
    
    var isLeafSensorConnected: Bool {
        return self._flags.contains(.leafSensorConnected)
    }
    
    var isLeafSensorTriggered: Bool {
        return self._flags.contains(.leafSensorTriggered)
    }

    
    /*
     * Full Sun:  > 96 
     * Part Shade: < 96 & > 70 
     * Shade: < 70
     * Dark: 0
    
    #define k_flag_light_day_bit 5
    #define k_flag_light_part_cloudy_bit 6
    #define k_flag_light_cloudy_bit 7
     
    #define k_threshold_full_sun 96
    #define k_threshold_part_shade 70
     */

    var weatherIcon: UIImage? {
        if self._flags.contains(.cloudy) { return UIImage(named: "Cloudy") }
        if self._flags.contains(.partCloudy) { return UIImage(named: "PartCloudy") }
        if self._flags.contains(.day) { return UIImage(named: "Sun") }
        return UIImage(named: "Dark") 
    }
    
    var leafSensorValue: Double {
        return 100.0 * Double(self._leaf_sensor_value) / 65534.0
    }
    
    var root: Double {
        return ((100.0 * (Double(self._root_temp) / 255.0)) * 1.8) + 32.0
    }
    
    var leaf: Double {
        return ((100.0 * (Double(self._leaf_temp) / 255.0)) * 1.8) + 32.0
    }
}



extension BLEPeripheral {
    
    var commandCharacteristic: BLECharacteristic? {
        guard let service: BLEService = self[k_leaf_sensor_service] else { return nil }
        return service[k_leaf_sensor_command]
    }
    
    var dataCharacteristic: BLECharacteristic? {
        guard let service: BLEService = self[k_leaf_sensor_service] else { return nil }
        return service[k_leaf_sensor_data]
    }
    
    func getLogHistory( completion: @escaping ((_ data: Data) -> Void) ) {
        guard let service: BLEService = self[k_leaf_sensor_service] else { return }
        guard let command_characteristic: BLECharacteristic = service[k_leaf_sensor_command] else { return }
        guard let data_characteristic: BLECharacteristic = service[k_leaf_sensor_data] else { return }
        
        data_characteristic.setReadCompletion({ 
            (data: Data?) in
            
            if let data = data {
                completion(data)
            }
        })
        
        command_characteristic.sendCommand(command: k_send_log_command, data: 0)
    }
    
    func getCurrentData( completion: @escaping ((_ data: Data) -> Void) ) {
        guard let service: BLEService = self[k_leaf_sensor_service] else { return }
        guard let command_characteristic: BLECharacteristic = service[k_leaf_sensor_command] else { return }
        guard let data_characteristic: BLECharacteristic = service[k_leaf_sensor_data] else { return }
        
        data_characteristic.setReadCompletion({ 
            (data: Data?) in
            
            if let data = data {
                completion(data)
            }
        })
        
        command_characteristic.sendCommand(command: k_send_values_command, data: 0)
    }
    
    
    func triggerSpray() {
        guard let command_characteristic: BLECharacteristic = self.commandCharacteristic else { return }
        command_characteristic.sendCommand(command: k_command_open_valve, data: 30)
    }
    
    func updateDeviceTimeStamp() {
        guard let command_characteristic: BLECharacteristic = self.commandCharacteristic else { return }
        let t: UInt32 = UInt32(Date.timeIntervalSinceReferenceDate)
        print("updateDeviceTimeStamp() sending: \(t)");
        command_characteristic.sendCommand(command: k_set_current_timestamp, data: t)
    }
    
    
}



//let data = string.data(using: .utf8)


/*
 
 var value = input
 let data = withUnsafePointer(to: &value) {
 Data(bytes: UnsafePointer($0), count: MemoryLayout.size(ofValue: input))
 } 
 
 */


let greenColor: UIColor = UIColor(red:100.0/255.0, green:160.0/255.0, blue:100.0/255.0, alpha: 1)
let greyColor: UIColor = UIColor(red:100.0/255.0, green:100.0/255.0, blue:100.0/255.0, alpha: 1)

class LogItemCell: UITableViewCell {
    @IBOutlet weak var leafSensorIcon: UIImageView?
    @IBOutlet weak var lightLevelIcon: UIImageView?
    @IBOutlet weak var intervalLabel: UILabel?
    @IBOutlet weak var temperatureLabel: UILabel?
    
    var peripheral: BLEPeripheral? = nil
    var logItem: HistoryItem? = nil  {
        didSet {
            if let logItem = self.logItem {
                if logItem.isLeafSensorConnected { self.leafSensorIcon?.image = UIImage(named: "LeafIcon") }
                else { self.leafSensorIcon?.image = nil }
                
                let intervalSeconds: Int = Int(logItem.interval) % 60
                let intervalMinutes: Int = Int(logItem.interval / 60)
                self.intervalLabel?.text = String(format: "sensor (%3.2f) interval %d:%d", logItem.leafSensorValue, intervalMinutes, intervalSeconds)
                self.intervalLabel?.textColor = logItem.isLeafSensorTriggered ? greenColor : greyColor
                
                self.lightLevelIcon?.image = logItem.weatherIcon
                self.temperatureLabel?.text = String(format: "temp (leaf: %3.1f  root: %3.1f)", logItem.leaf, logItem.root)
                
            }
        }
    }
}















