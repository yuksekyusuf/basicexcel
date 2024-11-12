
# Basic Excel Implementation

This repository contains a simplified Excel-like application implemented in Swift, designed to manage cells with constants or formulas and handle inter-cell dependencies. The project was initially inspired by a coding interview for an iOS developer position, where the challenge was to create an Excel structure with basic functionality.

## Features

- **Constant Values**: Set cells to hold constant numeric values.
- **Summation Formula**: Define cells that sum values from other cells.
- **Dependency Tracking**: Cells automatically recalculate when dependencies change.
- **Circular Reference Detection**: Circular dependencies between cells are detected and return an error (`refError`).

## Code Structure

- `CellIdentifier`: Uniquely identifies each cell by its row and column.
- `Formula` Enum: Defines formulas for cells, supporting sums and constants.
- `CellValue` Enum: Stores either a numeric value or a reference error.
- `Excel` Class: Manages all cells, handles setting values/formulas, and performs recursive evaluation with circular reference handling.

## Lessons and Improvements

The recursive approach allows basic dependency management and circular reference handling, serving as a foundational model for more complex Excel-like applications.
