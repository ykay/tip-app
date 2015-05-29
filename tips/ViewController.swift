//
//  ViewController.swift
//  tips
//
//  Created by Yuichi Kuroda on 5/25/15.
//  Copyright (c) 2015 Yuichi Kuroda. All rights reserved.
//

import UIKit

struct Global {
    struct Settings {
        static let DefaultTipIndexKey = "defaultTipIndex"
        static let DefaultTipIndex = 0
        
        static let LastSetCountryIndexKey = "lastSetCountryIndexKey"
    }
    
    static let ActiveCountryIndex = 0
}

class ViewController: UIViewController {

    @IBOutlet weak var billField: UITextField!
    @IBOutlet weak var tipLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var tipControl: UISegmentedControl!
    @IBOutlet weak var countryPicker: UIPickerView!
    @IBOutlet weak var countryLabel: UILabel!
    
    // Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tipLabel.text = "$0.00"
        totalLabel.text = "$0.00"
        
        billField.becomeFirstResponder()
        
        let ud = NSUserDefaults.standardUserDefaults()
        
        tipControl.selectedSegmentIndex = ud.integerForKey(Global.Settings.DefaultTipIndexKey)
    }
    
    // Every time it is shown; pre-animation
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let ud = NSUserDefaults.standardUserDefaults()
        
        tipControl.selectedSegmentIndex = ud.integerForKey(Global.Settings.DefaultTipIndexKey)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onEditingChanged(sender: AnyObject) {
        var tipPercentages = [0.15, 0.18, 0.20]
        var tipPercentage = tipPercentages[tipControl.selectedSegmentIndex]

        var billAmount = (billField.text as NSString).doubleValue
        var tip = billAmount * tipPercentage
        var total = billAmount + tip
        
        tipLabel.text = "$\(tip)"
        totalLabel.text = "$\(total)"
        
        tipLabel.text = String(format: "$%.2f", tip)
        totalLabel.text = String(format: "$%.2f", total)
    }
    
    @IBAction func onTap(sender: AnyObject) {
        view.endEditing(true)
    }
    
    
    var countries = [ "United States", "France", "Russia", "Greece", "Japan" ]
    var exchangeRates = [ 1, 0.918948723, 50.8724627, 0.918948723, 123.061777 ]
    var prevCountryIndex = 0
    
    // Implement UIViewDataSource protocol
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int{
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return countries.count
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return countries[row]
    }
    func pickerView(pickerView: UIPickerView!, didSelectRow row: Int, inComponent component: Int){
        countryLabel.text = countries[row]
        
        var billAmount = (billField.text as NSString).doubleValue
        if (prevCountryIndex == 0) {
            billAmount = billAmount * exchangeRates[row]
        }
        else {
            billAmount = billAmount / exchangeRates[prevCountryIndex]
            billAmount = billAmount * exchangeRates[row]
        }
        
        billField.text = "\(billAmount)"
        
        prevCountryIndex = row
        
        // TODO: Trigger logic in onEditingChanged so Tip + Total are adjusted.
        
        self.view.endEditing(true)
    }
    
    // TODO: onCountryChanged
    // ud.setInteger(countryMenu.index, Global.Settings.LastSetCountryIndexKey)
}

