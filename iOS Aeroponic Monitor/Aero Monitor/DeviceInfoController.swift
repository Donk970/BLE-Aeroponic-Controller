//
//  DeviceInfoController.swift
//  Aero Monitor
//
//  Created by DoodleBytes Development on 7/6/17.
//  Copyright © 2017 DoodleBytes Development. All rights reserved.
//

import UIKit

private let k_spray_cell_id = "Spray"
private let k_data_cell_id = "Data"
private let k_settings_cell_id = "Settings"
private let k_pins_cell_id = "Pins"
private let k_sensors_cell_id = "Sensors"
private let k_empty_cell = "Empty"



class DeviceInfoController: AbstractPeripheralCollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    override func updateUI() {
        if let peripheral: BLEPeripheral = self.peripheral {
            self.updatingUI = true;
            
            peripheral.updateDeviceTimeStamp()
        }
    }
    
    
    
    @IBAction func doSpray( _ sender: UIButton ) {
        self.peripheral?.triggerSpray()
    }
    

    
    
    
    

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return 6
    }
    
    func cellIDForPath(indexPath: IndexPath) -> String {
        switch indexPath.row {
        case 0:
            return k_spray_cell_id
        case 1:
            return k_data_cell_id
        case 2:
            return k_settings_cell_id
        case 3:
            return k_pins_cell_id
        case 4:
            return k_sensors_cell_id
        default:
            return k_empty_cell
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellIDForPath(indexPath: indexPath), for: indexPath)
    
        // Configure the cell
    
        return cell
    }
}







