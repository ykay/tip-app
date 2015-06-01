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
        static let LastSetBillAmountKey = "lastSetBillAmountKey"
        static let LastSetTipIndexKey = "lastSetTipIndexKey"
    }
    
    static let ActiveCountryIndex = 0
}

struct Country {
    var name = String()
    var exchangeRate:Float;
    var tipRates = [Float]()
    var localeIdentifier = String()
}

var cultures: [Country] = [Country]()

class ViewController: UIViewController {

    @IBOutlet weak var billField: UITextField!
    @IBOutlet weak var tipLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var tipControl: UISegmentedControl!
    @IBOutlet weak var countryPicker: UIPickerView!
    @IBOutlet weak var billFieldSymbol: UILabel!
    @IBOutlet weak var resultView: UIView!
    
    var userDefaults = NSUserDefaults()
    var currencyFormatter = NSNumberFormatter()
    
    var inputCountryIndex = 0
    var inputBillAmount = Float()
    
    // Suggested tips (ref): http://www.businessinsider.com/world-tipping-guide-2015-5
    func initializeValues() {
        cultures.append(Country(name: "United States", exchangeRate: 1, tipRates: [ 0.15, 0.18, 0.20 ], localeIdentifier: "en_US"))
        cultures.append(Country(name: "France", exchangeRate: 0.918948723, tipRates: [ 0.10 ], localeIdentifier: "fr_FR"))
        cultures.append(Country(name: "Czech Republic", exchangeRate: 24.9507223, tipRates: [ 0.10, 0.13, 0.15 ], localeIdentifier: "cs_CZ"))
        cultures.append(Country(name: "Japan", exchangeRate: 123.061777, tipRates: [ 0 ], localeIdentifier: "ja_JP"))
    }
    // Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Initialize tip rates based on culture
        initializeValues()
        
        billField.becomeFirstResponder()
        
        // Set country, bill amount, and tip to what it was last set to
        selectedCountryIndex = userDefaults.integerForKey(Global.Settings.LastSetCountryIndexKey)
        inputCountryIndex = selectedCountryIndex
        countryPicker.selectRow(selectedCountryIndex, inComponent: 0, animated: false)
        
        inputBillAmount = userDefaults.floatForKey(Global.Settings.LastSetBillAmountKey)
        
        currencyFormatter.numberStyle = .CurrencyStyle
        currencyFormatter.locale = NSLocale(localeIdentifier: cultures[selectedCountryIndex].localeIdentifier)
        currencyFormatter.lenient = true
        
        if (inputBillAmount != 0) {
            billField.text = NSString(format: "%.2f", inputBillAmount)
        }
        
        tipControl.removeAllSegments()
        for (index, element) in enumerate(cultures[selectedCountryIndex].tipRates) {
            tipControl.insertSegmentWithTitle(NSString(format: "%.2f", element), atIndex: index, animated: false)
        }
        
        tipControl.selectedSegmentIndex = userDefaults.integerForKey(Global.Settings.LastSetTipIndexKey)
        if (tipControl.selectedSegmentIndex == -1) {
            tipControl.selectedSegmentIndex = 0
            userDefaults.setInteger(0, forKey: Global.Settings.LastSetTipIndexKey)
        }
        
        populateFields(false)
    }
    
    func showEverythingElse() {
        resultView.hidden = false
        UIView.animateWithDuration(0.5, delay: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
            self.resultView.alpha = 1.0
            
            }, completion: nil)
    }
    
    func hideEverythingElse() {
        UIView.animateWithDuration(0.5, delay: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
            self.resultView.alpha = 0.0
            
            }, completion: nil)
    }
    
    // Every time it is shown; pre-animation
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tipControl.selectedSegmentIndex = userDefaults.integerForKey(Global.Settings.DefaultTipIndexKey)
        userDefaults.setInteger(tipControl.selectedSegmentIndex, forKey: Global.Settings.LastSetTipIndexKey)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onEditingChanged(sender: AnyObject) {
        inputCountryIndex = selectedCountryIndex
        inputBillAmount = (billField.text as NSString).floatValue

        userDefaults.setInteger(inputCountryIndex, forKey: Global.Settings.LastSetCountryIndexKey)
        userDefaults.setFloat(inputBillAmount, forKey: Global.Settings.LastSetBillAmountKey)
        
        populateFields(false)
    }
    
    @IBAction func onTipChanged(sender: AnyObject) {
        userDefaults.setInteger(tipControl.selectedSegmentIndex, forKey: Global.Settings.LastSetTipIndexKey)
        populateFields(false)
    }
    
    @IBAction func onTap(sender: AnyObject) {
        view.endEditing(true)
    }
    
    var selectedCountryIndex = 0
    
    // Implement UIViewDataSource protocol
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int{
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return cultures.count
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return cultures[row].name
    }
    func pickerView(pickerView: UIPickerView!, didSelectRow row: Int, inComponent component: Int){
        currencyFormatter.locale = NSLocale(localeIdentifier: cultures[row].localeIdentifier)
        
        var billAmount = inputBillAmount
        
        if (row == inputCountryIndex) {
            billAmount = inputBillAmount
        }
        else if (selectedCountryIndex == 0) {
            billAmount = billAmount * cultures[row].exchangeRate
        }
        else {
            billAmount = billAmount / cultures[selectedCountryIndex].exchangeRate
            billAmount = billAmount * cultures[row].exchangeRate
        }
        
        if (billAmount==0) {
            billField.text = ""
        }
        else {
            billField.text = NSString(format: "%.2f", billAmount)
        }

        // Save new country to last set values
        userDefaults.setInteger(row, forKey: Global.Settings.LastSetCountryIndexKey)
        userDefaults.setFloat(billAmount, forKey: Global.Settings.LastSetBillAmountKey)
        
        // Save current index so we know how to calculate the next conversion
        selectedCountryIndex = row
        
        populateFields(true)
        
        self.view.endEditing(true)
    }
    
    // Helper functions
    func populateFields(countryChanged: Bool){
        // Populate tip rates
        if (countryChanged) {
            tipControl.removeAllSegments()
            for (index, element) in enumerate(cultures[selectedCountryIndex].tipRates) {
                tipControl.insertSegmentWithTitle(NSString(format: "%.2f", element), atIndex: index, animated: false)
            }
            
            // Reset the selected tip rate because it's different per country
            tipControl.selectedSegmentIndex = 0
        }
    
        var tipPercentage = cultures[selectedCountryIndex].tipRates[tipControl.selectedSegmentIndex]
        
        var billAmount = (billField.text as NSString).floatValue
        var tip = billAmount * tipPercentage
        var total = billAmount + tip
        
        if (inputBillAmount == 0) {
            hideEverythingElse()
        }
        else {
            showEverythingElse()
        }
        
        tipLabel.text = currencyFormatter.stringFromNumber(tip)
        totalLabel.text = currencyFormatter.stringFromNumber(total)
    }
}

