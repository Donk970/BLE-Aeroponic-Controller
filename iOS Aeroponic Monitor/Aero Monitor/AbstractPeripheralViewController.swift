//
//  AbstractPeripheralViewController.swift
//  Aero Monitor
//
//  Created by DoodleBytes Development on 7/14/17.
//  Copyright © 2017 DoodleBytes Development. All rights reserved.
//

import UIKit

class AbstractPeripheralTableViewController: UITableViewController {
    var manager: BLEManager!
    
    var peripheral: BLEPeripheral? = nil {
        didSet {
            self.updateUI()
        }
    }
    
    var updatingUI: Bool = false;
    func updateUI() {
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


    /*
    // MARK: - Navigation
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dst: AbstractPeripheralViewController = segue.destination as? AbstractPeripheralViewController { 
            print("SEGUE TO: AbstractPeripheralViewController")
            
            dst.peripheral = self.peripheral 
            dst.manager = self.manager
            return 
        } 
        if let dst: AbstractPeripheralTableViewController = segue.destination as? AbstractPeripheralTableViewController { 
            print("SEGUE TO: AbstractPeripheralTableViewController")
            
            dst.peripheral = self.peripheral 
            dst.manager = self.manager
            return 
        }
        if let dst: AbstractPeripheralCollectionViewController = segue.destination as? AbstractPeripheralCollectionViewController { 
            print("SEGUE TO: AbstractPeripheralCollectionViewController")
            
            dst.peripheral = self.peripheral 
            dst.manager = self.manager
            return 
        }
    }

}





class AbstractPeripheralCollectionViewController: UICollectionViewController {
    var manager: BLEManager!
    
    var peripheral: BLEPeripheral? = nil {
        didSet {
            self.updateUI()
        }
    }
    
    var updatingUI: Bool = false;
    func updateUI() {
    }
    
    
    /*
     // MARK: - Navigation
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dst: AbstractPeripheralViewController = segue.destination as? AbstractPeripheralViewController { 
            print("SEGUE TO: AbstractPeripheralViewController")

            dst.peripheral = self.peripheral 
            dst.manager = self.manager
            return 
        } 
        if let dst: AbstractPeripheralTableViewController = segue.destination as? AbstractPeripheralTableViewController { 
            print("SEGUE TO: AbstractPeripheralTableViewController")
            
            dst.peripheral = self.peripheral 
            dst.manager = self.manager
            return 
        }
        if let dst: AbstractPeripheralCollectionViewController = segue.destination as? AbstractPeripheralCollectionViewController { 
            print("SEGUE TO: AbstractPeripheralCollectionViewController")
            
            dst.peripheral = self.peripheral 
            dst.manager = self.manager
            return 
        }
    }
    
}







class AbstractPeripheralViewController: UIViewController {
    var manager: BLEManager!
    
    var peripheral: BLEPeripheral? = nil {
        didSet {
            self.updateUI()
        }
    }
    
    var updatingUI: Bool = false;
    func updateUI() {
    }
    
    
    /*
     // MARK: - Navigation
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dst: AbstractPeripheralViewController = segue.destination as? AbstractPeripheralViewController { 
            print("SEGUE TO: AbstractPeripheralViewController")
            
            dst.peripheral = self.peripheral 
            dst.manager = self.manager
            return 
        } 
        if let dst: AbstractPeripheralTableViewController = segue.destination as? AbstractPeripheralTableViewController { 
            print("SEGUE TO: AbstractPeripheralTableViewController")
            
            dst.peripheral = self.peripheral 
            dst.manager = self.manager
            return 
        }
        if let dst: AbstractPeripheralCollectionViewController = segue.destination as? AbstractPeripheralCollectionViewController { 
            print("SEGUE TO: AbstractPeripheralCollectionViewController")
            
            dst.peripheral = self.peripheral 
            dst.manager = self.manager
            return 
        }
    }
    
}
















