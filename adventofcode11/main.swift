//
//  main.swift
//  adventofcode11
//
//  Created by Cruse, Si on 12/11/18.
//  Copyright © 2018 Cruse, Si. All rights reserved.
//

import Foundation

//    --- Day 11: Chronal Charge ---
//    You watch the Elves and their sleigh fade into the distance as they head toward the North Pole.
//
//    Actually, you're the one fading. The falling sensation returns.
//
//    The low fuel warning light is illuminated on your wrist-mounted device. Tapping it once causes it to project a hologram of the situation: a 300x300 grid of fuel cells and their current power levels, some negative. You're not sure what negative power means in the context of time travel, but it can't be good.
//
//    Each fuel cell has a coordinate ranging from 1 to 300 in both the X (horizontal) and Y (vertical) direction. In X,Y notation, the top-left cell is 1,1, and the top-right cell is 300,1.
//
//    The interface lets you select any 3x3 square of fuel cells. To increase your chances of getting to your destination, you decide to choose the 3x3 square with the largest total power.
//
//    The power level in a given fuel cell can be found through the following process:
//
//    Find the fuel cell's rack ID, which is its X coordinate plus 10.
//    Begin with a power level of the rack ID times the Y coordinate.
//    Increase the power level by the value of the grid serial number (your puzzle input).
//    Set the power level to itself multiplied by the rack ID.
//    Keep only the hundreds digit of the power level (so 12345 becomes 3; numbers with no hundreds digit become 0).
//    Subtract 5 from the power level.
//    For example, to find the power level of the fuel cell at 3,5 in a grid with serial number 8:
//
//    The rack ID is 3 + 10 = 13.
//    The power level starts at 13 * 5 = 65.
//    Adding the serial number produces 65 + 8 = 73.
//    Multiplying by the rack ID produces 73 * 13 = 949.
//    The hundreds digit of 949 is 9.
//    Subtracting 5 produces 9 - 5 = 4.
//    So, the power level of this fuel cell is 4.
//
//    Here are some more example power levels:
//
//    Fuel cell at  122,79, grid serial number 57: power level -5.
//    Fuel cell at 217,196, grid serial number 39: power level  0.
//    Fuel cell at 101,153, grid serial number 71: power level  4.
//    Your goal is to find the 3x3 square which has the largest total power. The square must be entirely within the 300x300 grid. Identify this square using the X,Y coordinate of its top-left fuel cell. For example:
//
//    For grid serial number 18, the largest total 3x3 square has a top-left corner of 33,45 (with a total power of 29); these fuel cells appear in the middle of this 5x5 region:
//
//    -2  -4   4   4   4
//    -4   4   4   4  -5
//    4   3   3   4  -4
//    1   1   2   4  -3
//    -1   0   2  -5  -2
//    For grid serial number 42, the largest 3x3 square's top-left is 21,61 (with a total power of 30); they are in the middle of this region:
//
//    -3   4   2   2   2
//    -4   4   3   3   4
//    -5   3   3   4  -4
//    4   3   3   4  -3
//    3   3   3  -5  -1
//    What is the X,Y coordinate of the top-left fuel cell of the 3x3 square with the largest total power?

struct Matrix<T> {
    let rows: Int, columns: Int, depth: Int
    var grid: [T]
    init(rows: Int, columns: Int, depth: Int, defaultValue: T) {
        self.rows = rows
        self.columns = columns
        self.depth = depth
        grid = Array(repeating: defaultValue, count: rows * columns * depth)
    }
    func indexIsValid(row: Int, column: Int, depth: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns && depth >= 0 && depth < self.depth
    }
    subscript(row: Int, column: Int, depth: Int) -> T {
        get {
            assert(indexIsValid(row: row, column: column, depth: depth), "Index out of range")
            // x + WIDTH * (y + DEPTH * z)
            return grid[column + self.columns * (row + self.depth * depth)]
        }
        set {
            assert(indexIsValid(row: row, column: column, depth: depth), "Index out of range")
            grid[column + self.columns * (row + self.depth * depth)] = newValue
        }
    }
    var row_range: ClosedRange<Int> { return 0...self.rows - 1 }
    var column_range: ClosedRange<Int> { return 0...self.columns - 1 }
    var depth_range: ClosedRange<Int> { return 0...self.depth - 1 }
}

class PowerGrid {
    let serial: Int
    var _grid: Matrix<Int?> = Matrix<Int?>(rows: 300, columns: 300, depth: 300, defaultValue: nil)
    
    init(serial: Int) {
        self.serial = serial
    }

// FIRST CHALLENGE - UNCACHED SOLUTION
//    func cellpowerlevel(x: Int, y: Int) -> Int {
//        let rack = x + 10
//        return (((rack * y + serial) * rack) / 100 % 10) - 5
//    }

//    func blockpowerlevel(x: Int, y: Int, size: Int) -> Int {
//        let blockrange = 0...size-1
//        let power = blockrange.reduce(0, { rowtotal, j in
//            blockrange.reduce(0, { columntotal, i in
//                cellpowerlevel(x: x + i, y: y + j) + columntotal
//            }) + rowtotal })
//        return power
//    }
    
    func cellpowerlevel(x: Int, y: Int) -> Int {
        if let power = _grid[x,y,0] {
            return power
        } else {
            let rack = x + 10
            let power = (((rack * y + serial) * rack) / 100 % 10) - 5
            _grid[x,y,0] = power
            return power
        }
    }
    
    private func rng(size: Int) -> (Int, Int) {
        assert(size > 1)
        return (size - size / 2, size / 2)
    }

    func slicepowerlevel(x: Int, y: Int, offset: (Int, Int)) -> Int {
        if offset.0 == offset.1 { return 0 }
        let xrange = x+offset.0...x+offset.0+offset.1-1
        let yrange = y+offset.0...y+offset.0+offset.1-1
        return xrange.reduce(0, { rowtotal, i in cellpowerlevel(x: i, y: y+offset.1) + rowtotal }) +
               yrange.reduce(0, { coltotal, i in cellpowerlevel(x: x+offset.1, y: i) + coltotal })
    }

    func blockpowerlevel(x: Int, y: Int, size: Int) -> Int {
        if size == 1 { return cellpowerlevel(x: x, y: y) }
        else if let power = _grid[x,y,size-1] {
            return power
        } else {
            let blockranges = rng(size: size)
            let power = blockpowerlevel(x: x , y: y, size: blockranges.0)
            + blockpowerlevel(x: x + blockranges.0, y: y, size: blockranges.1)
            + blockpowerlevel(x: x + blockranges.0, y: y + blockranges.0, size: blockranges.1)
            + blockpowerlevel(x: x , y: y + blockranges.0, size: blockranges.1)
            + slicepowerlevel(x: x, y: y, offset: blockranges)
            _grid[x,y,size-1] = power
            return power
        }
    }
    
    func maxpowerlevel(size: Int = 3) -> (x: Int, y: Int, power: Int, size: Int) {
        let blockrange = 0...300-size
        return blockrange.flatMap { y in blockrange.map { x in (x: x, y: y, power: blockpowerlevel(x: x, y: y, size: size), size: size)}}
            .max{ $0.power < $1.power }!
    }
    
    func maxblockpowerlevel() -> (x: Int, y: Int, power: Int, size: Int) {
        let blocksize = 2...300
        return blocksize.reversed().map { maxpowerlevel(size: $0) }.max{ $0.power < $1.power }!
    }

}

//let serial8 = PowerGrid(serial: 8)
//print(serial8.cellpowerlevel(x: 3, y: 5))
//
////    Fuel cell at  122,79, grid serial number 57: power level -5.
//let serial57 = PowerGrid(serial: 57)
//print(serial57.cellpowerlevel(x: 122, y: 79))
//
////    Fuel cell at 217,196, grid serial number 39: power level  0.
//let serial39 = PowerGrid(serial: 39)
//print(serial39.cellpowerlevel(x: 217, y: 196))
//
////    Fuel cell at 101,153, grid serial number 71: power level  4.
//let serial71 = PowerGrid(serial: 71)
//print(serial71.cellpowerlevel(x: 101, y: 153))


//let serial18 = PowerGrid(serial: 18)
//print(serial18.maxpowerlevel()
//
//let serial42 = PowerGrid(serial: 42)
//print(serial42.maxpowerlevel())

let serial8444 = PowerGrid(serial: 8444)
let mpl = serial8444.maxpowerlevel()
print("The FIRST CHALLENGE answer is \(mpl.x),\(mpl.y)\n")

//        --- Part Two ---
//    You discover a dial on the side of the device; it seems to let you select a square of any size, not just 3x3. Sizes from 1x1 to 300x300 are supported.
//
//    Realizing this, you now must find the square of any size with the largest total power. Identify this square by including its size as a third parameter after the top-left coordinate: a 9x9 square with a top-left corner of 3,5 is identified as 3,5,9.
//
//    For example:
//
//    For grid serial number 18, the largest total square (with a total power of 113) is 16x16 and has a top-left corner of 90,269, so its identifier is 90,269,16.
//    For grid serial number 42, the largest total square (with a total power of 119) is 12x12 and has a top-left corner of 232,251, so its identifier is 232,251,12.
//    What is the X,Y,size identifier of the square with the largest total power?

//print(serial18.maxblockpowerlevel())

//print(maxblockpowerlevel(serial: 42))

let mbpl = serial8444.maxblockpowerlevel()
print("The SECOND CHALLENGE answer is \(mbpl.x),\(mbpl.y),\(mbpl.size)\n")

