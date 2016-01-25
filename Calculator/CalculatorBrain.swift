//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Tomas on 16/01/16.
//  Copyright © 2016 codeafterwork. All rights reserved.
//

import Foundation

class CalculatorBrain {
    
    private enum Op: CustomStringConvertible {
        case Operand(Double)
        case UnaryOperation(String, Double -> Double)
        case BinaryOperation(String, (Double, Double) -> Double)
        case Constant(String, Double)
        case Variable(String)
        
        var description: String {
            get {
                switch self {
                case .Operand(let operand):
                    return "\(operand)"
                case .UnaryOperation(let symbol, _):
                    return symbol
                case .BinaryOperation(let symbol, _):
                    return symbol
                case .Constant(let symbol, _):
                    return "\(symbol)"
                case .Variable(let symbol):
                    return symbol
                }
            }
        }
        
        var precedence: Int {
            switch self {
            case .Operand(_), .Variable(_), .Constant(_, _), .UnaryOperation(_, _):
                return Int.max
            case .BinaryOperation(_, _):
                return Int.min
            }
        }
    }

    private var opStack = [Op]()
    
    private var knownOps = Dictionary<String, Op>() // [String:Op]()
    
    var variableValues = Dictionary<String, Double>()
    
    init() {
        func learnOp(op: Op) {
            knownOps[op.description] = op
        }
        learnOp(Op.BinaryOperation("×", *))
        learnOp(Op.BinaryOperation("÷") { $1 / $0 })
        learnOp(Op.BinaryOperation("+", +))
        learnOp(Op.BinaryOperation("-") { $1 - $0 })
        learnOp(Op.UnaryOperation("√", sqrt))
        learnOp(Op.UnaryOperation("sin", sin))
        learnOp(Op.UnaryOperation("cos", cos))
        learnOp(Op.UnaryOperation("±", { -1 * $0 }))
        learnOp(Op.Constant("π", M_PI))
    }
    
    typealias PropertyList = AnyObject
    
    var program: PropertyList {
        get {
            return opStack.map { $0.description }
        }
        set {
            if let opSymbols = newValue as? Array<String> {
                var newOpStack = [Op]()
                for opSymbol in opSymbols {
                    if let op = knownOps[opSymbol] {
                        newOpStack.append(op)
                    } else if let operand = NSNumberFormatter().numberFromString(opSymbol)?.doubleValue {
                        newOpStack.append(.Operand(operand))
                    }
                }
                opStack = newOpStack
            }
        }
    }
    
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand):
                return (operand, remainingOps)
            case .UnaryOperation(_, let operation):
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result {
                    return (operation(operand), operandEvaluation.remainingOps)
                }
            case .BinaryOperation(_, let operation):
                let op1Evaluation = evaluate(remainingOps)
                if let operand1 = op1Evaluation.result {
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.result {
                        return (operation(operand1, operand2), op2Evaluation.remainingOps)
                    }
                }
            case .Constant(_, let constantValue):
                return (constantValue, remainingOps)
            case .Variable(let symbol):
                if let operand = variableValues[symbol] {
                    return (operand, remainingOps)
                }
            }
        }
        return (nil, ops)
    }
    
    func evaluate() -> Double? {
        let (result, remainingOps) = evaluate(opStack)
        print("\(opStack) = \(result) with \(remainingOps) left over")
        return result
    }
    
    func pushOperand(operand: Double) -> Double?  {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.Variable(symbol))
        return evaluate()
    }
    
    func performOperation(symbol: String) -> Double?  {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        return evaluate()
    }
    
    func pushConstant(symbol: String) -> Double? {
        if let constant = knownOps[symbol] {
            opStack.append(constant)
        }
        return evaluate()
    }
    
    func reset() {
        opStack = [Op]()
        variableValues = Dictionary<String, Double>()
    }
    
    var description: String {
        get {
            let (descriptionArray, _) = description([String](), ops: opStack)
            return descriptionArray.joinWithSeparator(", ")
        }
    }
    
    private func description(currentDescription: [String], ops: [Op]) -> (accumulatedDescription: [String], remainingOps: [Op]) {
        var accumulatedDescription = currentDescription
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeFirst()
            switch op {
            case .Operand(_), .Variable(_), .Constant(_, _):
                accumulatedDescription.append(op.description)
                return description(accumulatedDescription, ops: remainingOps)
            case .UnaryOperation(let symbol, _):
                if !accumulatedDescription.isEmpty {
                    let unaryOperand = accumulatedDescription.removeLast()
                    accumulatedDescription.append(symbol + "(\(unaryOperand))")
                    let (newDescription, remainingOps) = description(accumulatedDescription, ops: remainingOps)
                    return (newDescription, remainingOps)
                }
            case .BinaryOperation(let symbol, _):
                if !accumulatedDescription.isEmpty {
                    let binaryOperandLast = accumulatedDescription.removeLast()
                    if !accumulatedDescription.isEmpty {
                        let binaryOperandFirst = accumulatedDescription.removeLast()
                        if op.description == remainingOps.first?.description || op.precedence == remainingOps.first?.precedence {
                            accumulatedDescription.append("(\(binaryOperandFirst)" + symbol + "\(binaryOperandLast))")
                        } else {
                            accumulatedDescription.append("\(binaryOperandFirst)" + symbol + "\(binaryOperandLast)")
                        }
                        return description(accumulatedDescription, ops: remainingOps)
                    } else {
                        accumulatedDescription.append("?" + symbol + "\(binaryOperandLast)")
                        return description(accumulatedDescription, ops: remainingOps)
                    }
                } else {
                    accumulatedDescription.append("?" + symbol + "?")
                    return description(accumulatedDescription, ops: remainingOps)
                }
            }
        }
        return (accumulatedDescription, ops)
    }
}