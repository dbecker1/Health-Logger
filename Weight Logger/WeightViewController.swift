//
//  MainViewController.swift
//  Weight Logger
//
//  Created by Daniel Becker on 7/11/17.
//  Copyright © 2017 Daniel Becker. All rights reserved.
//

import UIKit
import HealthKit

class WeightViewController: UIViewController {
    
    @IBOutlet weak var weightTextField: UITextField!
    var isAuthorized : Bool = false
    var bodyMassType : HKQuantityType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("No health kit available")
            return
        }
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            print("unable to create quanitity type")
            return
        }
        bodyMassType = quantityType
        
        
        HKHealthStore().requestAuthorization(toShare: [quantityType], read: [quantityType]) {
            result, error in
            
            if error != nil {
                print(error ?? "")
                return
            }
            
            if !result {
                print("User did not authorize healthkit data")
                return
            }
            
            self.isAuthorized = result
        }
    }
    
    @IBAction func submit(_ sender: UIButton) {
        
        if isAuthorized {
            let weightText = weightTextField.text!
            let weight = Double(weightText)
            
            let quantity = HKQuantity(unit: HKUnit.pound(), doubleValue: weight!)
            
            let bodyMass = HKQuantitySample(
                type: bodyMassType!,
                quantity: quantity,
                start: Date(),
                end: Date()
            )
            
            HKHealthStore().save(bodyMass) {
                result, error in
                
                if error != nil {
                    print(error ?? "")
                    return
                }
                
                print("Result saved")
            }
        }
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
