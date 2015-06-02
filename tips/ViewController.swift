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
    @IBOutlet weak var currentCurrencyCodeLabel: UILabel!
    @IBOutlet weak var currentExchangeRateLabel: UILabel!
    
    var userDefaults = NSUserDefaults()
    var currencyFormatter = NSNumberFormatter()
    
    var inputCountryIndex = 0
    var inputBillAmount = Float()
    
    // Suggested tips (ref): http://www.businessinsider.com/world-tipping-guide-2015-5
    // Example getting info about NSLocale object (ref): http://stackoverflow.com/questions/6177309/nslocale-and-country-name
    func initializeValues() {
        var allLocales:Array<String> = NSLocale.availableLocaleIdentifiers() as Array<String>
    
        for localeId in allLocales {
            var countryName = getCountryNameFromLocaleIdentifier(localeId)
            if (countryName != "") {
                cultures.append(Country(name: countryName, exchangeRate: 1.0, tipRates: [ 0.15, 0.18, 0.20 ], localeIdentifier: localeId))
            }

        }
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
        // Lenient helps make converting the formatted string into a number possible. If not set, parsing will fail.
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
    
    func showExchangeRateInfo() {
        resultView.hidden = false
        UIView.animateWithDuration(0.5, delay: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.currentExchangeRateLabel.alpha = 1.0
            }, completion: nil)
    }
    
    func hideExchangeRateInfo() {
        UIView.animateWithDuration(0.5, delay: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.currentExchangeRateLabel.alpha = 0.0
            }, completion: nil)
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
        
        hideExchangeRateInfo()
        
        var billAmount = inputBillAmount
        var exchangeRate = getExchangeRateFromLocaleIdentifier(cultures[row].localeIdentifier)
        
        currentCurrencyCodeLabel.text = getCurrencyCode(cultures[row].localeIdentifier)
        currentExchangeRateLabel.text = NSString(format: "(%.5f)", exchangeRate)
        
        showExchangeRateInfo()
        
        if (row == inputCountryIndex) {
            billAmount = inputBillAmount
        }
        else if (selectedCountryIndex == 0) {
            billAmount = billAmount * exchangeRate
        }
        else {
            billAmount = billAmount / cultures[selectedCountryIndex].exchangeRate
            billAmount = billAmount * exchangeRate
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
    func getCurrencyCode(localeIdentifier: String) -> String {        var locale = NSLocale(localeIdentifier: localeIdentifier)
        var currencyCode : String? = locale.objectForKey(NSLocaleCurrencyCode) as? String
        if currencyCode == nil { return "" }
        
        return currencyCode!
    }
    // (Ref) Making Synchronous Http Request: http://stackoverflow.com/questions/24016142/how-to-make-an-http-request-in-swift
    // Yahoo API Example: "http://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.xchange where pair in ("USDEUR")&env=store://datatables.org/alltableswithkeys"
    func getExchangeRateFromLocaleIdentifier(localeIdentifier: String) -> Float {
        var locale = NSLocale(localeIdentifier: localeIdentifier)
        var exchangeRate:Float = 1.0 // Default if we cannot get it (i.e. no internet)
        
        // e.g. USD, ZMW, YEN
        var currencyCode = getCurrencyCode(localeIdentifier)
        
        // Construct url for getting exchange rate json (from Yahoo Apis)
        var requestUrl = "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(%22USD\(currencyCode)%22)&env=store://datatables.org/alltableswithkeys&format=json"
        
        let url = NSURL(string: requestUrl)
        if (url != nil) {
            var request1: NSURLRequest = NSURLRequest(URL: url!)
            var response: AutoreleasingUnsafeMutablePointer<NSURLResponse?>=nil
            var error: NSErrorPointer = nil
            var data: NSData =  NSURLConnection.sendSynchronousRequest(request1, returningResponse: response, error:nil)!
            
            var parseError: NSError?
            let parsedObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data,
                options: NSJSONReadingOptions.AllowFragments,
                error:&parseError)
            
            if let rootObj = parsedObject as? NSDictionary {
                if let queryObj = rootObj["query"] as? NSDictionary {
                    if let resultsObj = queryObj["results"] as? NSDictionary {
                        if let rateObj = resultsObj["rate"] as? NSDictionary {
                            if let rate = rateObj["Rate"] as? NSString {
                                exchangeRate = rate.floatValue
                            }
                        }
                    }
                }
            }
        }
        
        return exchangeRate
    }
    func getCountryNameFromLocaleIdentifier(localeIdentifier: String) -> String {
        // Because we want the name in English
        var usLocale = NSLocale(localeIdentifier: "en_US")
        var countryName = String()
        
        var locale = NSLocale(localeIdentifier: localeIdentifier)
        var countryCode : String? = locale.objectForKey(NSLocaleCountryCode) as? String
        if countryCode == nil { return "" }
        
        var tmpName : String? = usLocale.displayNameForKey(NSLocaleCountryCode, value: countryCode!)
        if tmpName == nil {return ""}
        else {
            // Force unwrap it because we know it contains a value
            countryName = tmpName!
        }

        return countryName
    }
}

