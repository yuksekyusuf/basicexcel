import Foundation

// Struct to uniquely identify each cell by row and column
struct CellIdentifier: Hashable {
    let row: Int
    let column: Int
    
    init(_ row: Int, _ column: Int) {
        self.row = row
        self.column = column
    }
    
    var id: String {
        "\(row),\(column)" // String representation of the cell location
    }
}

// Enum to define possible formulas in cells
enum Formula {
    case sum([CellIdentifier]) // Sum formula with referenced cells
    case non // No formula
}

// This is when a cell can be evaluated
enum CellValue {
    case value(Double)
    case refError
}

// Main Excel class to manage cells and their values
class Excel {
    var cells: [CellIdentifier: (value: CellValue, formula: Formula)] = [:] // Dictionary of cells
    
    /*
     Retrieves the value of a cell identified by 'id'. Returns '.refError' if the cell cannot be evaluated (e.g., it doesn't exist or has a circular reference).
     */
    private func getValueCell(id: CellIdentifier) -> CellValue {
        // Initialize a set to track visited cells for circular reference detection
        var visited = Set<CellIdentifier>()
        
        // Evaluate the cell's value recursively
        return evaluate(id: id, visited: &visited)
    }
    
    // Set a cell to a constant value
    func setConstant(_ id: CellIdentifier, value: Double) {
        cells[id] = (value: .value(value), formula: Formula.non)
    }
    
    // Set a cell to sum values of referenced cells
    func setSumCell(_ id: CellIdentifier, arguments: [CellIdentifier]) {
        var sum: Double = 0.0
        for cell in arguments {
            // Check if any referenced cell returns .refError
            if case .refError = getValueCell(id: cell) {
                cells[id] = (value: .refError, formula: .sum(arguments))
                return
            }
            // Add value if cell exists
            if case .value(let value) = getValueCell(id: cell) {
                sum += value
            }
        }
        // Set cell to the computed sum value
        cells[id] = (value: .value(sum), formula: .sum(arguments))
    }
    
    
    // Evaluates all cells and returns their computed values
    private func evaluateCells() -> [CellIdentifier: CellValue] {
        var evaluatedCells: [CellIdentifier: CellValue] = [:]
        
        // Iterate over each cell in the spreadsheet
        for (cellId, _) in cells {
            var visited = Set<CellIdentifier>() // Track visited cells for circular reference detection
            evaluatedCells[cellId] = evaluate(id: cellId, visited: &visited) // Evaluate the cell's value
        }
        
        return evaluatedCells
    }
    
    private func evaluate(id: CellIdentifier, visited: inout Set<CellIdentifier>) -> CellValue {
        // Check for circular reference
        if visited.contains(id) {
            return .refError
        }
        
        // Mark the current cell as visited
        visited.insert(id)
        
        // Attempt to retrieve the formula associated with the current cell
        if let formula = cells[id]?.formula {
            switch formula {
            case .sum(let arguments):
                var sum = 0.0
                for argument in arguments {
                    // Recursively evaluate each referenced cell
                    let value = evaluate(id: argument, visited: &visited)
                    // If a referenced cell results in an error, propagate the error
                    if case .refError = value {
                        // Remove the current cell from visited before returning
                        visited.remove(id)
                        return .refError
                    }
                    // If the referenced cell has a valid value, add it to the sum
                    if case .value(let v) = value {
                        sum += v
                    }
                }
                // Remove the current cell from visited after evaluation
                visited.remove(id)
                return .value(sum)
            case .non:
                // If the cell has no formula, it's a constant value
                // Remove the current cell from visited after evaluation
                visited.remove(id)
                return cells[id]?.value ?? .refError
            }
        }
        
        // If the cell has neither a formula nor a value, return an error
        // Remove the current cell from visited before returning
        visited.remove(id)
        return .refError
    }

    
    func printCells() -> String {
        let cells = evaluateCells()
        var result = ""
        for (cell, value) in cells {
            result += "\(cell.id): "
            switch value {
            case .value(let val):
                result += "\(val)"
            case .refError:
                result += "REFERROR"
            }
            result += "\n"
        }
        return result
    }
}

// Test 1 - Test Simple Negation
func test1() {
    let excel = Excel()
    excel.setConstant(CellIdentifier(0, 0), value: 5)
    excel.setSumCell(CellIdentifier(0, 1), arguments: [CellIdentifier(0, 0)])
    print(excel.printCells()) // Outputs 0,0: 5 | 0,1: 5
    
    // Update cell (0,0)
    excel.setConstant(CellIdentifier(0, 0), value: 10)
    print(excel.printCells()) // Incorrectly outputs 0,0: 10 | 0,1: 5
}

// Test 2 - Test Simple Summation
func test2() {
    let excel = Excel()
    excel.setConstant(CellIdentifier(0, 0), value: 5)
    excel.setConstant(CellIdentifier(0, 1), value: 10)
    excel.setSumCell(CellIdentifier(0, 2), arguments: [CellIdentifier(0, 0), CellIdentifier(0, 1)])
    print(excel.printCells())
    // Expected output
    // 0,0: 5
    // 0,1: 10
    // 0,2: 15
}

// Test 3 - Test chain of summations
func test3() {
    let excel = Excel()
    excel.setConstant(CellIdentifier(0, 0), value: 5)
    excel.setSumCell(CellIdentifier(0, 1), arguments: [CellIdentifier(0, 0)])
    excel.setSumCell(CellIdentifier(0, 2), arguments: [CellIdentifier(0, 1)])
    print(excel.printCells())
    // Expected output
    // 0,0: 5
    // 0,1: 5
    // 0,2: 5
}

// Test 4 - Test circular reference
func test4() {
    let excel = Excel()
    excel.setSumCell(CellIdentifier(0, 0), arguments: [CellIdentifier(0, 1)])
    excel.setSumCell(CellIdentifier(0, 1), arguments: [CellIdentifier(0, 0)])
    print(excel.printCells())
    // Expected output
    // 0,0: REFERROR
    // 0,1: REFERROR
}

// Test 5 - Test reference that is empty at the start
func test5() {
    let excel = Excel()
    excel.setSumCell(CellIdentifier(0, 1), arguments: [CellIdentifier(0,0)])
    print(excel.printCells()) // Outputs 0,1: REFERROR
    
    // Set cell (0,0) to a value
    excel.setConstant(CellIdentifier(0, 0), value: 5)
    print(excel.printCells()) // Incorrectly still outputs 0,1: REFERROR
}
//
print("TEST 1")
test1()
print("TEST 2")
test2()
print("TEST 3")
test3()
print("TEST 4")
test4()
print("TEST 5")
test5()








