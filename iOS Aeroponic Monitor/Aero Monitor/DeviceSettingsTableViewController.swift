//
//  DeviceSettingsTableViewController.swift
//  Aero Monitor
//
//  Created by DoodleBytes Development on 7/7/17.
//  Copyright © 2017 DoodleBytes Development. All rights reserved.
//

import UIKit


let k_picker_open_height: CGFloat = 216
let k_picker_closed_height: CGFloat = 0

let k_time_unit_seconds: Int = 1
let k_time_unit_minutes: Int = 60

/*
 
 typedef struct settings_t {
     uint16_t default_connected_spray_interval = 8; minutes, should be in range of 1 to 20 minutes
     uint16_t default_disconnected_spray_interval = 3; minutes, should be in range of 1 to 20 minutes
     uint16_t spray_duration = 3;  seconds, should be small like 3 to 5 seconds
     uint16_t startup_spray_duration = 20;  seconds, should be bigger like 30 to 300 seconds
     int8_t root_temperature_pin = 2;
     int8_t air_temperature_pin = 3;
     int8_t leaf_sensor_pin = 1;
     int8_t light_sensor_pin = 4;
 };
 
 */
struct settings_t {
    var default_connected_spray_interval: UInt16
    var default_disconnected_spray_interval: UInt16
    var spray_duration: UInt16
    var startup_spray_duration: UInt16
    var root_temperature_pin: Int8
    var air_temperature_pin: Int8
    var leaf_sensor_pin: Int8
    var light_sensor_pin: Int8
}

enum TimeUnits {
    case SECONDS
    case MINUTES
}



class PickerDataSource: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    var timeUnits: TimeUnits = .SECONDS
    var minTime: Int = 1
    var maxTime: Int = 10
    
    func rowForValue( value: TimeInterval ) -> Int {
        return Int(value) - self.minTime
    }
    
    var selectionCallback: ((_ time: TimeInterval) -> Void)?
    
    // returns the number of 'columns' to display.
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    // returns the # of rows in each component..
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.maxTime - self.minTime
    }
    
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch self.timeUnits {
        case .SECONDS: 
            return "\(self.minTime + row) Seconds"
        case .MINUTES: 
            return "\(self.minTime + row) Minutes"
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch self.timeUnits {
        case .SECONDS: 
            let t: TimeInterval = TimeInterval(self.minTime + row)
            self.selectionCallback?(t)
            break
        case .MINUTES: 
            let t: TimeInterval = TimeInterval(self.minTime + row)
            self.selectionCallback?(t)
            break
        }
    }
    
}

class DeviceSettingsTableViewController: AbstractPeripheralViewController {
    var settingsLoaded: Bool = false
    var settings: settings_t = settings_t(
        
        default_connected_spray_interval: 8,
        default_disconnected_spray_interval: 3,
        spray_duration:  3,
        startup_spray_duration:  20,
        root_temperature_pin:  2,
        air_temperature_pin:  3,
        leaf_sensor_pin:  1,
        light_sensor_pin: 4
        
        ) {
        didSet {
            print("DeviceSettingsTableViewController.settings.didSet \(self.settings)")
            self.isLoading = false;
            self.settingsLoaded = true
            self.normalSprayDurationValue = TimeInterval(self.settings.spray_duration)
            self.normalSprayIntervalValue = TimeInterval(self.settings.default_connected_spray_interval)
            self.disconnectedSprayIntervalValue = TimeInterval(self.settings.default_disconnected_spray_interval)
            self.startupSprayDurationValue = TimeInterval(self.settings.startup_spray_duration)
        }
    }
    
    
    
    override func updateUI() {
        if let peripheral: BLEPeripheral = self.peripheral {
            self.updatingUI = true;
            
            self.isLoading = true;
            peripheral.getCurrentSettings(completion: { 
                (data: Data) in
                
                if !self.updatingUI { return }
                
                let item: settings_t = data.withUnsafeBytes() { 
                    (ptr: UnsafePointer<settings_t>) -> settings_t in
                    return ptr.pointee
                }
                self.settings = item
                
            })
        }
    }
    
    
    
    //MARK: - NORMAL SPRAY DURATION
    @IBOutlet weak var loadingSettingsIndicator: UIActivityIndicatorView?
    @IBOutlet weak var loadingSettingsLabel: UILabel?
    var isLoading: Bool = false {
        didSet {
            if self.isLoading {
                self.loadingSettingsLabel?.isHidden = false 
                self.loadingSettingsIndicator?.isHidden = false 
                self.loadingSettingsIndicator?.startAnimating()
            } else {
                self.loadingSettingsLabel?.isHidden = true 
                self.loadingSettingsIndicator?.isHidden = true  
                self.loadingSettingsIndicator?.stopAnimating()
            }
        }
    }
    

    //MARK: - NORMAL SPRAY DURATION
    var normalSprayDurationValue: TimeInterval = 0 {
        didSet {
            self.normalSprayDurationField?.text = "Duration: \(self.normalSprayDurationValue) Sec"
            self.normalSprayDurationPicker?.selectRow(self.normalSprayDurationManager.rowForValue(value: self.normalSprayDurationValue), inComponent: 0, animated: true)
        }
    }
    let normalSprayDurationManager: PickerDataSource = PickerDataSource()
    @IBOutlet weak var normalSprayDurationButton: UIButton?
    @IBOutlet weak var normalSprayDurationField: UILabel?
    @IBOutlet weak var normalSprayDurationPickerContainer: UIView?
    @IBOutlet weak var normalSprayDurationPickerContainerHeight: NSLayoutConstraint?
    @IBOutlet weak var normalSprayDurationPicker: UIPickerView?
    var normalSprayDurationPickerSelected: Bool = false {
        didSet {
            if self.normalSprayDurationPickerSelected {
                // container closed so open it
                self.normalSprayDurationButton?.setTitle("Done", for: .normal)
                self.normalSprayDurationPicker?.isHidden = false
                self.normalSprayDurationPickerContainerHeight?.constant = k_picker_open_height
            } else {
                // container open so close it
                self.normalSprayDurationButton?.setTitle("Set", for: .normal)
                self.normalSprayDurationPicker?.isHidden = true
                self.normalSprayDurationPickerContainerHeight?.constant = k_picker_closed_height
            }
        }
    }
    @IBAction func expandNormalSprayDurationPicker(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            self.normalSprayDurationPickerSelected = !self.normalSprayDurationPickerSelected
            self.normalSprayIntervalPickerSelected = false 
            self.disconnectedSprayIntervalPickerSelected = false 
            self.startupSprayDurationPickerSelected = false

            self.view.layoutIfNeeded()
        })
    }

    
    //MARK: - NORMAL SPRAY INTERVAL
    var normalSprayIntervalValue: TimeInterval = 0 {
        didSet {
            self.normalSprayIntervalField?.text = "Interval: \(self.normalSprayIntervalValue) Min"
            self.normalSprayIntervalPicker?.selectRow(self.normalSprayIntervalManager.rowForValue(value: self.normalSprayIntervalValue), inComponent: 0, animated: true)
        }
    }
    let normalSprayIntervalManager: PickerDataSource = PickerDataSource()
    @IBOutlet weak var normalSprayIntervalButton: UIButton?
    @IBOutlet weak var normalSprayIntervalField: UILabel?
    @IBOutlet weak var normalSprayIntervalPickerContainer: UIView?
    @IBOutlet weak var normalSprayIntervalPicker: UIPickerView?
    @IBOutlet weak var normalSprayIntervalPickerHeight: NSLayoutConstraint?
    var normalSprayIntervalPickerSelected: Bool = false {
        didSet {
            if self.normalSprayIntervalPickerSelected {
                // container closed so open it
                self.normalSprayIntervalButton?.setTitle("Done", for: .normal)
                self.normalSprayIntervalPicker?.isHidden = false
                self.normalSprayIntervalPickerHeight?.constant = k_picker_open_height
            } else {
                // container open so close it
                self.normalSprayIntervalButton?.setTitle("Set", for: .normal)
                self.normalSprayIntervalPicker?.isHidden = true
                self.normalSprayIntervalPickerHeight?.constant = k_picker_closed_height
            }
        }
    }
    @IBAction func expandNormalSprayIntervalPicker(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            self.normalSprayDurationPickerSelected = false
            self.normalSprayIntervalPickerSelected = !self.normalSprayIntervalPickerSelected 
            self.disconnectedSprayIntervalPickerSelected = false 
            self.startupSprayDurationPickerSelected = false
            
            self.view.layoutIfNeeded()
        })
    }

    
    //MARK: - DISCONNECTED SPRAY INTERVAL
    var disconnectedSprayIntervalValue: TimeInterval = 0 {
        didSet {
            self.disconnectedSprayIntervalField?.text = "Disconnected Interval: \(self.disconnectedSprayIntervalValue) Min"
            self.disconnectedSprayIntervalPicker?.selectRow(self.disconnectedSprayIntervalManager.rowForValue(value: self.disconnectedSprayIntervalValue), inComponent: 0, animated: true)
        }
    }
    let disconnectedSprayIntervalManager: PickerDataSource = PickerDataSource()
    @IBOutlet weak var disconnectedSprayIntervalButton: UIButton?
    @IBOutlet weak var disconnectedSprayIntervalField: UILabel?
    @IBOutlet weak var disconnectedSprayIntervalPickerContainer: UIView?
    @IBOutlet weak var disconnectedSprayIntervalPicker: UIPickerView?
    @IBOutlet weak var disconnectedSprayIntervalPickerHeight: NSLayoutConstraint?
    var disconnectedSprayIntervalPickerSelected: Bool = false {
        didSet {
            if self.disconnectedSprayIntervalPickerSelected {
                // container closed so open it
                self.disconnectedSprayIntervalButton?.setTitle("Done", for: .normal)
                self.disconnectedSprayIntervalPicker?.isHidden = false
                self.disconnectedSprayIntervalPickerHeight?.constant = k_picker_open_height
            } else {
                // container open so close it
                self.disconnectedSprayIntervalButton?.setTitle("Set", for: .normal)
                self.disconnectedSprayIntervalPicker?.isHidden = true
                self.disconnectedSprayIntervalPickerHeight?.constant = k_picker_closed_height
            }
        }
    }
    @IBAction func expandDisconnectedSprayIntervalPicker(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            self.normalSprayDurationPickerSelected = false
            self.normalSprayIntervalPickerSelected = false
            self.disconnectedSprayIntervalPickerSelected = !self.disconnectedSprayIntervalPickerSelected 
            self.startupSprayDurationPickerSelected = false

            self.view.layoutIfNeeded()
        })
    }
    
    
    //MARK: - STARTUP SPRAY DURATION
    var startupSprayDurationValue: TimeInterval = 0 {
        didSet {
            self.startupSprayDurationField?.text = "Startup Duration: \(self.startupSprayDurationValue) Sec"
            self.startupSprayDurationPicker?.selectRow(self.startupSprayDurationManager.rowForValue(value: self.startupSprayDurationValue), inComponent: 0, animated: true)
        }
    }
    let startupSprayDurationManager: PickerDataSource = PickerDataSource()
    @IBOutlet weak var startupSprayDurationButton: UIButton?
    @IBOutlet weak var startupSprayDurationField: UILabel?
    @IBOutlet weak var startupSprayDurationPickerContainer: UIView?
    @IBOutlet weak var startupSprayDurationPicker: UIPickerView?
    @IBOutlet weak var startupSprayDurationPickerHeight: NSLayoutConstraint?
    var startupSprayDurationPickerSelected: Bool = false {
        didSet {
            if self.startupSprayDurationPickerSelected {
                // container closed so open it
                self.startupSprayDurationButton?.setTitle("Done", for: .normal)
                self.startupSprayDurationPicker?.isHidden = false
                self.startupSprayDurationPickerHeight?.constant = k_picker_open_height
            } else {
                // container open so close it
                self.startupSprayDurationButton?.setTitle("Set", for: .normal)
                self.startupSprayDurationPicker?.isHidden = true
                self.startupSprayDurationPickerHeight?.constant = k_picker_closed_height
            }
        }
    }
    @IBAction func expandStartupSprayDurationPicker(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            self.normalSprayDurationPickerSelected = false
            self.normalSprayIntervalPickerSelected = false
            self.disconnectedSprayIntervalPickerSelected = false
            self.startupSprayDurationPickerSelected = !self.startupSprayDurationPickerSelected
            
            self.view.layoutIfNeeded()
        })
    }
    
    
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.isLoading = true;

        if !self.settingsLoaded { 
            self.normalSprayDurationValue = 1 
            self.normalSprayIntervalValue = 1
            self.disconnectedSprayIntervalValue = 1
            self.startupSprayDurationValue = 1
        }
        
        // NORMAL SPRAY DURATION SETUP
        self.normalSprayDurationManager.timeUnits = .SECONDS
        self.normalSprayDurationManager.minTime = 1
        self.normalSprayDurationManager.maxTime = 21
        self.normalSprayDurationManager.selectionCallback = {
            (_ time: TimeInterval) in 
            self.normalSprayDurationValue = time
            self.peripheral?.updateDeviceSprayDuration(duration: time)
        }
        self.normalSprayDurationPicker?.dataSource = self.normalSprayDurationManager
        self.normalSprayDurationPicker?.delegate = self.normalSprayDurationManager
        
        
        // NORMAL SPRAY INTERVAL SETUP
        self.normalSprayIntervalManager.timeUnits = .MINUTES
        self.normalSprayIntervalManager.minTime = 1
        self.normalSprayIntervalManager.maxTime = 16
        self.normalSprayIntervalManager.selectionCallback = {
            (_ time: TimeInterval) in 
            self.normalSprayIntervalValue = time
            self.peripheral?.updateDeviceSprayInterval(duration: time)
        }
        self.normalSprayIntervalPicker?.dataSource = self.normalSprayIntervalManager
        self.normalSprayIntervalPicker?.delegate = self.normalSprayIntervalManager
        
        
        // DISCONNECTED SPRAY INTERVAL SETUP
        self.disconnectedSprayIntervalManager.timeUnits = .MINUTES
        self.disconnectedSprayIntervalManager.minTime = 1
        self.disconnectedSprayIntervalManager.maxTime = 16
        self.disconnectedSprayIntervalManager.selectionCallback = {
            (_ time: TimeInterval) in 
            self.disconnectedSprayIntervalValue = time
            self.peripheral?.updateDeviceDisconnectedSprayInterval(duration: time)
        }
        self.disconnectedSprayIntervalPicker?.dataSource = self.disconnectedSprayIntervalManager
        self.disconnectedSprayIntervalPicker?.delegate = self.disconnectedSprayIntervalManager
        
        
        // STARTUP SPRAY DURATION SETUP
        self.startupSprayDurationManager.timeUnits = .SECONDS
        self.startupSprayDurationManager.minTime = 1
        self.startupSprayDurationManager.maxTime = 60
        self.startupSprayDurationManager.selectionCallback = {
            (_ time: TimeInterval) in 
            self.startupSprayDurationValue = time
            self.peripheral?.updateDeviceStartupSprayDuration(duration: time)
        }
        self.startupSprayDurationPicker?.dataSource = self.startupSprayDurationManager
        self.startupSprayDurationPicker?.delegate = self.startupSprayDurationManager
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}





let k_command_send_settings_data: UInt8 = 3
let k_set_connected_interval: UInt8 = 11
let k_set_disconnected_interval: UInt8 = 12
let k_set_spray_duration: UInt8 = 13
let k_set_startup_spray_duration: UInt8 = 14
let k_set_leaf_sensor_threshold: UInt8 = 16

//#define k_set_leaf_sensor_pin 30
//#define k_set_root_temp_pin 31
//#define k_set_air_temp_pin 32
//#define k_set_light_sensor_pin 33


extension BLEPeripheral {
    
    func getCurrentSettings( completion: @escaping ((_ data: Data) -> Void) ) {
        guard let service: BLEService = self[k_leaf_sensor_service] else { return }
        guard let command_characteristic: BLECharacteristic = service[k_leaf_sensor_command] else { return }
        guard let data_characteristic: BLECharacteristic = service[k_leaf_sensor_data] else { return }
        
        data_characteristic.setReadCompletion({ 
            (data: Data?) in
            
            if let data = data {
                completion(data)
            }
        })
        
        command_characteristic.sendCommand(command: k_command_send_settings_data, data: 0)
    }
    
    func updateDeviceSprayDuration( duration: TimeInterval) {
        guard let command_characteristic: BLECharacteristic = self.commandCharacteristic else { return }
        let t: UInt32 = UInt32(duration)
        command_characteristic.sendCommand(command: k_set_spray_duration, data: t)
    }
    
    func updateDeviceSprayInterval( duration: TimeInterval) {
        guard let command_characteristic: BLECharacteristic = self.commandCharacteristic else { return }
        let t: UInt32 = UInt32(duration)
        command_characteristic.sendCommand(command: k_set_connected_interval, data: t)
    }
    
    func updateDeviceStartupSprayDuration( duration: TimeInterval) {
        guard let command_characteristic: BLECharacteristic = self.commandCharacteristic else { return }
        let t: UInt32 = UInt32(duration)
        command_characteristic.sendCommand(command: k_set_startup_spray_duration, data: t)
    }
    
    func updateDeviceDisconnectedSprayInterval( duration: TimeInterval) {
        guard let command_characteristic: BLECharacteristic = self.commandCharacteristic else { return }
        let t: UInt32 = UInt32(duration)
        command_characteristic.sendCommand(command: k_set_disconnected_interval, data: t)
    }
    
}













