//
//  BloodPressureInterfaceController.swift
//  Weight Logger
//
//  Created by Daniel Becker on 7/13/17.
//  Copyright © 2017 Daniel Becker. All rights reserved.
//

import WatchKit
import HealthKit

class BloodPressureInterfaceController: WKInterfaceController {
    var isAuthorized : Bool = false
    var systolicType : HKQuantityType?
    var diastolicType : HKQuantityType?
    
    @IBOutlet var systolicPicker: WKInterfacePicker!
    @IBOutlet var diastolicPicker: WKInterfacePicker!
    @IBOutlet var message: WKInterfaceLabel!
    
    var systolicValue = 0
    var diastolicValue = 0
    var bpOptions = [WKPickerItem]()
    
    private final let maxBP = 200
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        setMessage("")
        
        for i in 1...maxBP {
            let item = WKPickerItem()
            item.title = String(i)
            bpOptions.append(item)
        }
        systolicPicker.setItems(bpOptions)
        diastolicPicker.setItems(bpOptions)
        
        
        guard HKHealthStore.isHealthDataAvailable() else {
            setMessage("No health kit available")
            return
        }
        
        guard let systolicTypeLoad = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic) else {
            setMessage("unable to create systolic quanitity type")
            return
        }
        self.systolicType = systolicTypeLoad
        
        guard let diastolicTypeLoad = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            setMessage("unable to create diastolic quanitity type")
            return
        }
        self.diastolicType = diastolicTypeLoad
        
        
        HKHealthStore().requestAuthorization(toShare: [systolicType!, diastolicType!], read: [systolicType!, diastolicType!]) {
            result, error in
            
            if error != nil {
                print(error ?? "")
                return
            }
            
            if !result {
                print("User did not authorize healthkit data")
                return
            }
            
            self.isAuthorized = true
            self.loadPreviousBP()
        }
    }
    
    @IBAction func submit() {
        if isAuthorized {
            let systolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: Double(systolicValue))
            let diastolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: Double(diastolicValue))
            
            let systolicPressure = HKQuantitySample(type: systolicType!, quantity: systolicQuantity, start: Date(), end: Date())
            let diastolicPressure = HKQuantitySample(type: diastolicType!, quantity: diastolicQuantity, start: Date(), end: Date())
            
            let bpCorrelationType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure)
            let bpCorrelation = Set(arrayLiteral: systolicPressure, diastolicPressure)
            let bloodPressure = HKCorrelation(type: bpCorrelationType!, start: Date(), end: Date(), objects: bpCorrelation)
            
            HKHealthStore().save(bloodPressure) {
                result, error in
                
                if error != nil {
                    self.setMessage(error.debugDescription)
                    return
                }
                
                self.setMessage("\(self.systolicValue)/\(self.diastolicValue) saved.")
                    
            }
        }
    }
    private func setMessage(_ message : String) {
        self.message.setText(message)
    }
    
    @IBAction func systolicDidChange(_ value: Int) {
        systolicValue = Int(bpOptions[value].title!)!
    }
    
    @IBAction func diastolicDidChange(_ value: Int) {
        diastolicValue = Int(bpOptions[value].title!)!
    }
    
    func loadPreviousBP() {
        let bpType = HKQuantityType.correlationType(forIdentifier: .bloodPressure)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let bpQuery = HKSampleQuery(sampleType: bpType!, predicate: nil, limit: 1, sortDescriptors: [sort]) {
            query, result, error in
            if (result?.count)! > 0 {
                let mostRecent = result?.first as? HKCorrelation
                let sys = mostRecent?.objects(for: self.systolicType!).first as? HKQuantitySample
                let dias = mostRecent?.objects(for: self.diastolicType!).first as?HKQuantitySample
                self.systolicValue = Int(sys!.quantity.doubleValue(for: HKUnit.millimeterOfMercury()))
                self.diastolicValue = Int(dias!.quantity.doubleValue(for: HKUnit.millimeterOfMercury()))
                
                self.systolicPicker.setSelectedItemIndex(self.systolicValue - 1)
                self.diastolicPicker.setSelectedItemIndex(self.diastolicValue - 1)
            }
            
        }
        HKHealthStore().execute(bpQuery)
    }
}
