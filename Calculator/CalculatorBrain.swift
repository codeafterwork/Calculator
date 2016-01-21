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
        case Constant(Double)
        
        var description: String {
            get {
                switch self {
                case .Operand(let operand):
                    return "\(operand)"
                case .UnaryOperation(let symbol, _):
                    return symbol
                case .BinaryOperation(let symbol, _):
                    return symbol
                case .Constant(let constant):
                    return "\(constant)"
                }
            }
        }
    }

    private var opStack = [Op]()
    
    private var knownOps = Dictionary<String, Op>() // [String:Op]()
    private var knownConstants = Dictionary<String, Double>()
    
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
        
        knownConstants["π"] = M_PI
    }
    
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remaingOps = ops
            let op = remaingOps.removeLast()
            switch op {
            case .Operand(let operand):
                return (operand, remaingOps)
            case .UnaryOperation(_, let operation):
                let operandEvaluation = evaluate(remaingOps)
                if let operand = operandEvaluation.result {
                    return (operation(operand), operandEvaluation.remainingOps)
                }
            case .BinaryOperation(_, let operation):
                let op1Evaluation = evaluate(remaingOps)
                if let operand1 = op1Evaluation.result {
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.result {
                        return (operation(operand1, operand2), op2Evaluation.remainingOps)
                    }
                }
            case .Constant(let constant):
                return (constant, remaingOps)
            }
        }
        return (nil, ops)
    }
    
    func evaluate() -> (Double?, String?) {
        let (result, remainingOps) = evaluate(opStack)
        print("\(opStack) = \(result) with \(remainingOps) left over")
        return (result, "\(opStack)")
    }
    
    func pushOperand(operand: Double) -> (Double?, String?)  {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    func performOperation(symbol: String) -> (Double?, String?)  {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        return evaluate()
    }
    
    func pushConstant(symbol: String) -> (Double?, String?) {
        if let constant = knownConstants[symbol] {
            opStack.append(Op.Constant(constant))
        }
        return evaluate()
    }
    
    func reset() {
        opStack = [Op]()
    }
}