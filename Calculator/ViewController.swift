//
//  ViewController.swift
//  Calculator
//
//  Created by Tomas on 13/01/16.
//  Copyright © 2016 codeafterwork. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var history: UILabel!

    var userIsInTheMiddleOfTypingNumber = false
    
    var brain = CalculatorBrain()
    
    @IBAction func appendDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        if userIsInTheMiddleOfTypingNumber {
            if digit !=  "." || (digit == "." && display.text!.rangeOfString(".") == nil) {
                display.text = display.text! + digit
            }
        } else {
            if digit == "." {
                display.text = "0" + digit
            } else {
                display.text = digit
            }
            userIsInTheMiddleOfTypingNumber = true
        }
    }
    
    @IBAction func operate(sender: UIButton) {
        let operation = sender.currentTitle!
        if userIsInTheMiddleOfTypingNumber {
            enter()
        }
        perform(operation)
    }
    
    @IBAction func enter() {
        userIsInTheMiddleOfTypingNumber = false
        let (result, stack) = brain.pushOperand(displayValue!)
        displayValue = result
        history.text = stack
    }
 
    @IBAction func enterConstant(sender: UIButton) {
        let constant = sender.currentTitle!
        if userIsInTheMiddleOfTypingNumber {
            enter()
        }
        let (result, stack) = brain.pushConstant(constant)
        displayValue = result
        history.text = stack
    }
    
    @IBAction func clear(sender: UIButton) {
        brain.reset()
        displayValue = 0
        history.text = nil
        userIsInTheMiddleOfTypingNumber = false
    }
    
    @IBAction func back(sender: UIButton) {
        if let displayText = display.text {
            if displayText.characters.count > 1 {
                display.text = String(displayText.characters.dropLast())
            } else {
                displayValue = 0
                userIsInTheMiddleOfTypingNumber = false
            }
        }
    }
    
    @IBAction func sign() {
        if userIsInTheMiddleOfTypingNumber {
            if let displayText = display.text {
                if displayText.characters.first == "-" {
                    display.text = String(displayText.characters.dropFirst())
                } else {
                    display.text = "-" + displayText
                }
            }
        } else {
            perform("±")
        }
    }

    private func perform(operation: String) {
        let (result, stack) = brain.performOperation(operation)
        if result != nil {
            displayValue = result!
            if let displayText = display.text {
                if displayText.characters.last != "=" {
                    display.text = displayText + "="
                }
            }
        } else {
            displayValue = 0
        }
        history.text = stack
    }
    
    var displayValue: Double? {
        get {
            return NSNumberFormatter().numberFromString(display.text!)?.doubleValue ?? 0
        }
        set {
            if let value = newValue {
                display.text = "\(value)"
            } else {
                display.text = ""
            }
            userIsInTheMiddleOfTypingNumber = false
        }
    }
}

