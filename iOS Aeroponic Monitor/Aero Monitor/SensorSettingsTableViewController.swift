//
//  SensorSettingsTableViewController.swift
//  Aero Monitor
//
//  Created by DoodleBytes Development on 7/14/17.
//  Copyright © 2017 DoodleBytes Development. All rights reserved.
//

import UIKit






struct sensor_settings_t {
    var leaf_sensor_threshold: UInt16
    var root_temperature_intercept: UInt16
    var root_temperature_slope: UInt16
    var air_temperature_intercept: UInt16
    var air_temperature_slope: UInt16
    
    var leafSensorSensitivity: Float {
        get {
            let value: Float = Float(self.leaf_sensor_threshold)/65534.0
            print("get threshold: \(self.leaf_sensor_threshold) -> \(value)")
            return value 
        }
        set(v) {
            let value: UInt16 = UInt16(v*65534.0)
            print("set threshold: \(v) -> \(value)")
            self.leaf_sensor_threshold = value 
        }
    }
}







class SensorSettingsTableViewController: AbstractPeripheralTableViewController {
    
    var settingsLoaded: Bool = false
    var settings: sensor_settings_t = sensor_settings_t(
        
        leaf_sensor_threshold:  100,
        root_temperature_intercept: 0, 
        root_temperature_slope: 1, 
        air_temperature_intercept: 0, 
        air_temperature_slope: 1
        
        ) {
        didSet {
            print("SensorSettingsTableViewController.settings.didSet \(self.settings)")
            
//            self.isLoading = false;
//            self.settingsLoaded = true
//            self.normalSprayDurationValue = TimeInterval(self.settings.spray_duration)
//            self.normalSprayIntervalValue = TimeInterval(self.settings.default_connected_spray_interval)
//            self.disconnectedSprayIntervalValue = TimeInterval(self.settings.default_disconnected_spray_interval)
//            self.startupSprayDurationValue = TimeInterval(self.settings.startup_spray_duration)
        }
    }
    
    
    override func updateUI() {
        print("SensorSettingsTableViewController.updateUI()")
        if let peripheral: BLEPeripheral = self.peripheral {
            print("    has peripheral")
            self.updatingUI = true;
            
            self.isLoading = true;
            peripheral.getCurrentSensorSettings(completion: { 
                (data: Data) in
                print("        data returned")

                if !self.updatingUI { return }
                
                let item: sensor_settings_t = data.withUnsafeBytes() { 
                    (ptr: UnsafePointer<sensor_settings_t>) -> sensor_settings_t in
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
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
        return 4
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dst: AbstractSensorSettingsViewController = segue.destination as? AbstractSensorSettingsViewController { 
            dst.peripheral = self.peripheral 
            dst.manager = self.manager
            dst.settings = self.settings 
            return 
        }
        super.prepare(for: segue, sender: sender)
    }

}






let k_command_send_sensor_settings_data: UInt8 = 4

extension BLEPeripheral {
    
    func getCurrentSensorSettings( completion: @escaping ((_ data: Data) -> Void) ) {
        guard let service: BLEService = self[k_leaf_sensor_service] else { return }
        guard let command_characteristic: BLECharacteristic = service[k_leaf_sensor_command] else { return }
        guard let data_characteristic: BLECharacteristic = service[k_leaf_sensor_data] else { return }
        
        data_characteristic.setReadCompletion({ 
            (data: Data?) in
            print("\n\n\n    k_command_send_sensor_settings_data READ COMPLETION CALLED\n\n\n")
            
            if let data = data {
                print("\n\n\n        k_command_send_sensor_settings_data COMPLETING WITH DATA\n\n\n")
                completion(data)
            }
        })
        
        command_characteristic.sendCommand(command: k_command_send_sensor_settings_data, data: 0)
    }
    
    
    func updateDeviceLeafSensorThreshold( value: Float) {
        guard let command_characteristic: BLECharacteristic = self.commandCharacteristic else { return }
        let t: UInt32 = UInt32(value*65534.0)
        command_characteristic.sendCommand(command: k_set_leaf_sensor_threshold, data: t)
    }
    

}











class AbstractSensorSettingsViewController: AbstractPeripheralViewController {
    var settings: sensor_settings_t? {
        didSet {
            self.updateUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func updateUI() {
        
    }
    
}













class LeafSensorSettingsViewController: AbstractSensorSettingsViewController {
//    override var settings: sensor_settings_t {
//        didSet {
//            self.updateUI()
//        }
//    }
    
    @IBOutlet weak var sensitivitySlider: UISlider?
    
    @IBOutlet weak var sensitivityLabel: UILabel?
    
    @IBAction func sensitivityChanged(_ sender: UISlider) {
        print("change: \(sender.value)")
        self.sensitivityLabel?.text = "\(sender.value)"
    }
    
    @IBAction func sensitivityFinished(_ sender: UISlider) {
        print("final: \(sender.value)")
        self.settings?.leafSensorSensitivity = sender.value 
        self.peripheral?.updateDeviceLeafSensorThreshold(value: sender.value)
    }
    
    
    override func updateUI() {
        print("LeafSensorSettingsViewController.updateUI()")
        print("    LeafSensorSettingsViewController.settings: \(self.settings)")
        if let settings: sensor_settings_t = self.settings {
            self.sensitivitySlider?.value = settings.leafSensorSensitivity
            self.sensitivityLabel?.text = "\(settings.leafSensorSensitivity)"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateUI()
    }
}















