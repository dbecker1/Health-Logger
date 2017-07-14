//
//  MainInterfaceController.swift
//  Weight Logger
//
//  Created by Daniel Becker on 7/12/17.
//  Copyright © 2017 Daniel Becker. All rights reserved.
//

import WatchKit
import HealthKit

class WeightInterfaceController: WKInterfaceController {
    @IBOutlet var integerPicker: WKInterfacePicker!
    @IBOutlet var decimalPicker: WKInterfacePicker!
    @IBOutlet var message: WKInterfaceLabel!
    
    var isAuthorized : Bool = false
    var bodyMassType : HKQuantityType?
    
    var integerValue = 0
    var decimalValue = 0
    var integerOptions = [WKPickerItem]()
    var decimalOptions = [WKPickerItem]()
    
    private final let maxWeight = 300

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        setMessage("")
        
        for i in 1...maxWeight {
            let item = WKPickerItem()
            item.title = String(i)
            integerOptions.append(item)
        }
        integerPicker.setItems(integerOptions)
        
        for i in 0...9 {
            let item = WKPickerItem()
            item.title = String(i)
            decimalOptions.append(item)
        }
        decimalPicker.setItems(decimalOptions)
        
        guard HKHealthStore.isHealthDataAvailable() else {
            setMessage("No health kit available")
            return
        }
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            setMessage("unable to create quanitity type")
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
            
            self.loadPreviousWeight()
        }
    }
    @IBAction func submit() {
        var weight = Double(integerValue)
        let decimal = Double(decimalValue) / 10
        weight += decimal
        
        if isAuthorized {
            
            let quantity = HKQuantity(unit: HKUnit.pound(), doubleValue: weight)
            
            let bodyMass = HKQuantitySample(
                type: bodyMassType!,
                quantity: quantity,
                start: Date(),
                end: Date()
            )
            
            HKHealthStore().save(bodyMass) {
                result, error in
                
                if error != nil {
                    self.setMessage(error.debugDescription)
                    return
                }
                
                self.setMessage("\(weight) saved.")
            }
        }

    }
    
    @IBAction func integerDidChange(_ value: Int) {
        integerValue = Int(integerOptions[value].title!)!
    }
    
    @IBAction func decimalDidChange(_ value: Int) {
        decimalValue = Int(decimalOptions[value].title!)!
    }
    
    func loadPreviousWeight() {
        let weightType = HKSampleType.quantityType(forIdentifier: .bodyMass)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let weightQuery = HKSampleQuery(sampleType: weightType!, predicate: nil, limit: 1, sortDescriptors: [sort]) {
            query, result, error in
            if (result?.count)! > 0 {
                let mostRecent = result?.first as? HKQuantitySample
                let weight = mostRecent?.quantity.doubleValue(for: HKUnit.pound())
                self.integerValue = Int(weight!)
                self.integerPicker.setSelectedItemIndex(self.integerValue - 1)
            }
        }
        HKHealthStore().execute(weightQuery)
    }
    
    private func setMessage(_ message: String) {
        self.message.setText(message)
    }
}

