//
//  SettingsViewController.swift
//  tips
//
//  Created by Yuichi Kuroda on 5/25/15.
//  Copyright (c) 2015 Yuichi Kuroda. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    @IBOutlet weak var defaultTipControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        var ud = NSUserDefaults.standardUserDefaults()

        var defaultTipIndex = ud.integerForKey(Global.Settings.DefaultTipIndexKey)
        
        defaultTipControl.selectedSegmentIndex = defaultTipIndex
    }
    @IBAction func onDefaultTipChanged(sender: AnyObject) {
        let ud = NSUserDefaults.standardUserDefaults()
        
        ud.setInteger(defaultTipControl.selectedSegmentIndex, forKey:Global.Settings.DefaultTipIndexKey)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
