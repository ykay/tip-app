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
        
        static let LastTimeAppRanKey = "lastTimeAppRan"
        static let LastInputCountryIndexKey = "lastInputCountryIndex"
        static let LastInputBillAmountKey = "lastInputBillAmount"
        static let LastSetCountryIndexKey = "lastSetCountryIndex"
        static let LastSetBillAmountKey = "lastSetBillAmount"
        static let LastSetTipIndexKey = "lastSetTipIndex"
        static let LastSetExchangeRateKey = "lastSetExchangeRate"
    }
    
    static let ActiveCountryIndex = 0
}

struct Country {
    var name = String()
    var exchangeRate:Float;
    var localeIdentifier = String()
}

var cultures: [Country] = [Country]()

let tipRates: Array<Float> = [ 0.15, 0.18, 0.20 ]

class ViewController: UIViewController {

    @IBOutlet weak var billField: UITextField!
    @IBOutlet weak var tipLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var tipControl: UISegmentedControl!
    @IBOutlet weak var countryPicker: UIPickerView!
    @IBOutlet weak var billFieldSymbol: UILabel!
    @IBOutlet weak var currentCurrencyCodeLabel: UILabel!
    @IBOutlet weak var currentExchangeRateLabel: UILabel!
    @IBOutlet weak var inputCurrencyCodeLabel: UILabel!
    
    @IBOutlet weak var tipTitleLabel: UILabel!
    @IBOutlet weak var totalTitleLabel: UILabel!
    @IBOutlet weak var inputReferenceLabel: UILabel!
    
    @IBOutlet weak var resultView: UIView!
    @IBOutlet weak var countryPickerView: UIView!
    
    var defaultBackColor = UIColor(red: 249/255.0, green: 249/255.0, blue: 249/255.0, alpha: 1)
    var defaultLightTextColor = UIColor(red: 164/255.0, green: 217/255.0, blue: 211/255.0, alpha: 1)
    var defaultNormalTextColor = UIColor(red: 16/255.0, green: 133/255.0, blue: 117/255.0, alpha: 1)
    var defaultDarkTextColor = UIColor(red: 4/255.0, green: 61/255.0, blue: 49/255.0, alpha: 1)

    var defaultTitleNormalTextColor = UIColor(red: 98/255.0, green: 98/255.0, blue: 98/255.0, alpha: 1)
    
    var invertedBackColor = UIColor()
    var invertedLightTextColor = UIColor()
    var invertedNormalTextColor = UIColor()
    var invertedDarkTextColor = UIColor()
    var invertedTitleNormalTextColor = UIColor()
    
    var darkMode = false
    
    var userDefaults = NSUserDefaults()
    var currencyFormatter = NSNumberFormatter()
    
    var inputCountryIndex = 0
    var inputBillAmount = Float()
    var inputLocaleIdentifier = String()
    
    func initializeUIValues() {
        invertedBackColor = defaultDarkTextColor
        invertedLightTextColor = defaultLightTextColor
        invertedNormalTextColor = defaultBackColor
        invertedDarkTextColor = defaultBackColor
        
        invertedTitleNormalTextColor = defaultBackColor
    }
    
    func switchToDarkMode() {
        UIView.animateWithDuration(0.5, delay: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.resultView.backgroundColor = self.invertedBackColor
            self.countryPickerView.backgroundColor = self.invertedBackColor
            self.view.backgroundColor = self.invertedBackColor
            }, completion: { (value: Bool) in
            self.switchTextToDarkMode()
            })

        inputReferenceLabel.hidden = true
        
        darkMode = true
    }
    
    func switchTextToDarkMode() {
        UIView.animateWithDuration(0.5, delay: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.tipTitleLabel.textColor = self.invertedTitleNormalTextColor
            self.totalTitleLabel.textColor = self.invertedTitleNormalTextColor
            self.billField.textColor = self.invertedLightTextColor
            self.totalLabel.textColor = self.invertedLightTextColor
            }, completion: nil)
    }
    
    func switchToLightMode() {
        UIView.animateWithDuration(0.5, delay: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.view.backgroundColor = self.defaultBackColor
            self.resultView.backgroundColor = self.defaultBackColor
            self.countryPickerView.backgroundColor = self.defaultBackColor
            }, completion: { (value: Bool) in
                self.switchTextToLightMode()
            })
        
        darkMode = false
    }
    
    func switchTextToLightMode() {
        UIView.animateWithDuration(0.5, delay: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.tipTitleLabel.textColor = self.defaultTitleNormalTextColor
            self.totalTitleLabel.textColor = self.defaultTitleNormalTextColor
            self.billField.textColor = self.defaultDarkTextColor
            self.totalLabel.textColor = self.defaultDarkTextColor
            }, completion: nil)
    }

    // Example getting info about NSLocale object (ref): http://stackoverflow.com/questions/6177309/nslocale-and-country-name
    func initializeValues() {
        var allLocales:Array<String> = NSLocale.availableLocaleIdentifiers() as Array<String>
        // Tracks country names so we don't add duplicates
        var duplicateFilter = Dictionary<String,Int>()
        
        for localeId in allLocales {
            var countryName = getCountryNameFromLocaleIdentifier(localeId)
            if (countryName != "") {
                if duplicateFilter[countryName] == nil {
                    cultures.append(Country(name: countryName, exchangeRate: 1.0, localeIdentifier: localeId))
                    duplicateFilter[countryName] = 1
                }
            }
        }
        
        cultures = cultures.sorted { $0.name < $1.name }
    }
    
    // Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        var resetValues = true
        
        initializeUIValues()
        
        // Initialize tip rates based on culture
        initializeValues()
        
        billField.becomeFirstResponder()
        
        // See if we should use last set values or just reset everything (after 10 minutes of non-use)
        if let lastTimeAppRan = userDefaults.objectForKey(Global.Settings.LastTimeAppRanKey) as? NSDate {
            let elapsedTime = NSDate().timeIntervalSinceDate(lastTimeAppRan as NSDate)
            if ((elapsedTime / 60) < 10) {
                resetValues = false
            }
        }
        
        if (!resetValues)
        {
            // Set country, bill amount, and tip to what it was last set to
            selectedCountryIndex = userDefaults.integerForKey(Global.Settings.LastSetCountryIndexKey)
            inputCountryIndex = userDefaults.integerForKey(Global.Settings.LastInputCountryIndexKey)
            countryPicker.selectRow(selectedCountryIndex, inComponent: 0, animated: false)
            
            inputBillAmount = userDefaults.floatForKey(Global.Settings.LastInputBillAmountKey)
            billField.text = NSString(format: "%.2f", userDefaults.floatForKey(Global.Settings.LastSetBillAmountKey))
        }
        else {
            selectedCountryIndex = 237
            inputCountryIndex = selectedCountryIndex
            countryPicker.selectRow(selectedCountryIndex, inComponent: 0, animated: false)
            
            inputBillAmount = 0
        }
        
        inputLocaleIdentifier = cultures[inputCountryIndex].localeIdentifier
        inputCurrencyCodeLabel.text = getCurrencyCode(inputLocaleIdentifier)
        
        currencyFormatter.numberStyle = .CurrencyStyle
        currencyFormatter.locale = NSLocale(localeIdentifier: cultures[selectedCountryIndex].localeIdentifier)
        // Lenient helps make converting the formatted string into a number possible. If not set, parsing will fail.
        currencyFormatter.lenient = true
        
        currentCurrencyCodeLabel.text = getCurrencyCode(cultures[selectedCountryIndex].localeIdentifier)
        
        if let currentExchangeRate = userDefaults.stringForKey(Global.Settings.LastSetExchangeRateKey) {
            currentExchangeRateLabel.text = currentExchangeRate
        }
        
        tipControl.removeAllSegments()
        for (index, element) in enumerate(tipRates) {
            tipControl.insertSegmentWithTitle(NSString(format: "%.2f", element), atIndex: index, animated: false)
        }
        
        tipControl.selectedSegmentIndex = userDefaults.integerForKey(Global.Settings.LastSetTipIndexKey)
        if (tipControl.selectedSegmentIndex == -1) {
            tipControl.selectedSegmentIndex = 0
            userDefaults.setInteger(0, forKey: Global.Settings.LastSetTipIndexKey)
        }
        
        updateExchangeRateAndBillAmount(selectedCountryIndex)
        
        populateFields()
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

    @IBAction func onEditingBegan(sender: AnyObject) {
        if (!darkMode) {
            switchToDarkMode()
        }
    }
    
    @IBAction func onEditingChanged(sender: AnyObject) {
        inputCountryIndex = selectedCountryIndex
        inputBillAmount = (billField.text as NSString).floatValue
        inputLocaleIdentifier = cultures[inputCountryIndex].localeIdentifier
        
        userDefaults.setInteger(inputCountryIndex, forKey: Global.Settings.LastInputCountryIndexKey)
        userDefaults.setFloat(inputBillAmount, forKey: Global.Settings.LastInputBillAmountKey)
        
        // Update label for input currency name
        inputCurrencyCodeLabel.text = getCurrencyCode(inputLocaleIdentifier)
        
        populateFields()
    }
    
    @IBAction func onEditingEnded(sender: AnyObject) {
        if (darkMode) {
            switchToLightMode()
        }
        updateExchangeRateAndBillAmount(selectedCountryIndex)
    }
    
    @IBAction func onTipChanged(sender: AnyObject) {
        userDefaults.setInteger(tipControl.selectedSegmentIndex, forKey: Global.Settings.LastSetTipIndexKey)
        populateFields()
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
    func updateExchangeRateAndBillAmount(countryIndex: Int) {
        currencyFormatter.locale = NSLocale(localeIdentifier: cultures[countryIndex].localeIdentifier)
        
        hideExchangeRateInfo()
        
        var billAmount = inputBillAmount
        if let exchangeRate = getExchangeRateFromLocaleIdentifier(cultures[countryIndex].localeIdentifier) {
            
            currentCurrencyCodeLabel.text = getCurrencyCode(cultures[countryIndex].localeIdentifier)
            currentExchangeRateLabel.text = NSString(format: "(%.5f)", exchangeRate)
            
            showExchangeRateInfo()
            
            if (countryIndex == inputCountryIndex) {
                // billAmount is the inputBillAmount (already set).
            }
            else if (selectedCountryIndex == 0) {
                billAmount = billAmount * exchangeRate
            }
            else {
                billAmount = billAmount / cultures[selectedCountryIndex].exchangeRate
                billAmount = billAmount * exchangeRate
            }
            
        }
        else {
            currentExchangeRateLabel.text = "(could not retrieve exchange rate)"
            
            // We couldn't get the exchange rate (i.e. no internet); Set the billAmount to unconverted input value
            billAmount = inputBillAmount
        }
        
        if (billAmount==0) {
            billField.text = ""
        }
        else {
            billField.text = NSString(format: "%.2f", billAmount)
        }
        
        if (countryIndex != inputCountryIndex) {
            inputReferenceLabel.text = String("(\(inputCurrencyCodeLabel.text!): \(inputBillAmount))")
            inputReferenceLabel.hidden = false
        } else {
            inputReferenceLabel.hidden = true
        }
        
        // Save new country to last set values
        userDefaults.setInteger(countryIndex, forKey: Global.Settings.LastSetCountryIndexKey)
        userDefaults.setFloat(billAmount, forKey: Global.Settings.LastSetBillAmountKey)
        userDefaults.setObject(currentExchangeRateLabel.text, forKey: Global.Settings.LastSetExchangeRateKey)

    }
    func pickerView(pickerView: UIPickerView!, didSelectRow row: Int, inComponent component: Int){
        updateExchangeRateAndBillAmount(row)
        
        // Save current index so we know how to calculate the next conversion
        selectedCountryIndex = row
        
        populateFields()
        
        self.view.endEditing(true)
    }
    
    // Helper functions
    func populateFields(){
        var tipPercentage = tipRates[tipControl.selectedSegmentIndex]
        
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
    func getCurrencyCode(localeIdentifier: String) -> String {
        var locale = NSLocale(localeIdentifier: localeIdentifier)
        var currencyCode : String? = locale.objectForKey(NSLocaleCurrencyCode) as? String
        if currencyCode == nil { return "" }
        
        return currencyCode!
    }
    // (Ref) Making Synchronous Http Request: http://stackoverflow.com/questions/24016142/how-to-make-an-http-request-in-swift
    // Yahoo API Example: "http://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.xchange where pair in ("USDEUR")&env=store://datatables.org/alltableswithkeys"
    func getExchangeRateFromLocaleIdentifier(localeIdentifier: String) -> Float? {
        var locale = NSLocale(localeIdentifier: localeIdentifier)
        var exchangeRate:Float? // Default to nil
        
        // e.g. USD, ZMW, YEN
        var currencyCode = getCurrencyCode(localeIdentifier)
        var inputCurrencyCode = getCurrencyCode(inputLocaleIdentifier)
        
        // Construct url for getting exchange rate json (from Yahoo Apis)
        var requestUrl = "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(%22\(inputCurrencyCode)\(currencyCode)%22)&env=store://datatables.org/alltableswithkeys&format=json"
        
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

