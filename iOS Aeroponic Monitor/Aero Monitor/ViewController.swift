//
//  ViewController.swift
//  Aero Monitor
//
//  Created by DoodleBytes Development on 6/5/17.
//  Copyright © 2017 DoodleBytes Development. All rights reserved.
//

import UIKit


let k_peripheral_display_cell_identifier: String = "peripheral_display_cell"

class ViewController: UITableViewController {
    
    var manager: BLEManager!
    
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
            //self.activityIndicator?.isHidden = true 
            self.activityIndicator?.stopAnimating()
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        self.showActivityIndicator()
        serviceUUIDs = [k_leaf_sensor_service]
        self.manager = BLEManager.sharedManager
        
        
        self.manager.uiCallback = {
            (_ manager: BLEManager, _ peripherals: [BLEPeripheral], _ selected: BLEPeripheral?) in 
            
            self.hideActivityIndicator()
            self.tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.manager.peripheralsArray.count 
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: k_peripheral_display_cell_identifier, for: indexPath)
        let peripheral: BLEPeripheral = self.manager.peripheralsArray[indexPath.row] 
        cell.textLabel?.text = peripheral.name 
        cell.detailTextLabel?.text = peripheral.identifier.uuidString
        
        
        return cell
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let dst: DeviceInfoController = segue.destination as? DeviceInfoController else { return }
        guard let cell: UITableViewCell = sender as? UITableViewCell else { return }
        guard let p: IndexPath = self.tableView.indexPath(for: cell) else { return }
        dst.peripheral = self.manager.peripheralsArray[p.row] 
        dst.manager = self.manager
    }

}

