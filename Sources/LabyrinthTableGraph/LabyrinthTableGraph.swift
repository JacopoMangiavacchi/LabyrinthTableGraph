import Foundation

public struct Block : Codable, Hashable, Equatable {
    let row: Int
    let col: Int
    let width: Int
    let heigth: Int
    
    func containRowCol(rowcol: (Int, Int)) -> Bool {
        return (rowcol.0 >= row && rowcol.1 >= col && rowcol.0 < row + heigth && rowcol.1 < col + width)
    }
}

public struct LabyrinthTableGraph : CustomStringConvertible, Codable {
    var rows: Int
    var columns: Int
    internal var boxes: [Box]
    internal var movableBlocks: Set<Block>
    internal var nonMovableBlocks: Set<Block>
    internal var edges: [[Int]]

    private enum CodingKeys: String, CodingKey {
        case rows
        case columns
        case boxes
        case movableBlocks
        case nonMovableBlocks
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        boxes = try container.decode([Box].self, forKey: .boxes)
        movableBlocks = try container.decode(Set<Block>.self, forKey: .movableBlocks)
        nonMovableBlocks = try container.decode(Set<Block>.self, forKey: .nonMovableBlocks)
        rows = try container.decode(Int.self, forKey: .rows)
        columns = try container.decode(Int.self, forKey: .columns)
        edges = [[Int]](repeating: [Int](), count: rows * columns)
        forceReloadAllEdges()
    }
    
    public init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
        boxes = [Box](repeating: Box.None, count: rows * columns)
        movableBlocks = Set<Block>()
        nonMovableBlocks = Set<Block>()
        edges = [[Int]](repeating: [Int](), count: rows * columns)
        forceReloadAllEdges()
    }

    public mutating func forceReloadAllEdges() {
        edges = [[Int]](repeating: [Int](), count: rows * columns)
        var pos = 0
        
        for box in boxes {
            for outputDirection in box.directions {
                var _next: (Int) -> Int?
                var expectedDirection: Direction
                
                switch outputDirection {
                case .North:
                    _next = _north
                    expectedDirection = .South
                case .East:
                    _next = _east
                    expectedDirection = .West
                case .South:
                    _next = _south
                    expectedDirection = .North
                case .West:
                    _next = _west
                    expectedDirection = .East
                }

                if let next = _next(pos) {
                    for inputDirection in boxes[next].directions {
                        if inputDirection == expectedDirection {
                            edges[pos].append(next)
                            break
                        }
                    }
                }
            }
            
            pos += 1
        }
    }
    
    //TODO: FEATURE: Replace nil with the opposite to let the Shortest Path Algorithm (AI) shortcuts outside the inner of the tablegraph
    internal func _north(pos: Int) -> Int? {
        return pos - columns >= 0 ? pos - columns : nil
    }
    internal func _east(pos: Int) -> Int? {
        return pos % columns < columns - 1 ? pos + 1 : nil
    }
    internal func _south(pos: Int) -> Int? {
        return pos + columns < (rows*columns) ? pos + columns : nil
    }
    internal func _west(pos: Int) -> Int? {
        return pos % columns > 0 ? pos - 1 : nil
    }
    
    
    public var description: String {
        var descriptionTable = String()
        var col = 0
        
        for box in boxes {
            descriptionTable.append(box.description)
            col += 1
            if col >= columns {
                descriptionTable.append("\n")
                col = 0
            }
        }
        
        return descriptionTable
    }
    
    public subscript(row: Int, column: Int) -> Box {
        get {
            return boxes[(row * columns) + column]
        }
        set (newBox) {
            boxes[(row * columns) + column] = newBox
        }
    }

    public subscript(pos: Int) -> Box {
        get {
            return boxes[pos]
        }
        set (newBox) {
            boxes[pos] = newBox
        }
    }

    public mutating func addMovableBlock(block: Block) {
        movableBlocks.insert(block)
    }
    
    public mutating func addNonMovableBlock(block: Block) {
        nonMovableBlocks.insert(block)
    }

    public mutating func rotate(row: Int, col: Int, rotation: Rotation) {
        return self.rotate(rowcol: (row, col), rotation: rotation)
    }

    public mutating func rotate(pos: Int, rotation: Rotation) {
        return self.rotate(rowcol: (pos / rows, pos % columns), rotation: rotation)
    }

    public mutating func rotate(rowcol: (Int, Int), rotation: Rotation) {
        boxes[(rowcol.0 * columns) + rowcol.1].rotate(rotation)
        forceReloadAllEdges() //TODO: OPTIMIZE _forceReloadEdge(row: rowcol.0, col: rowcol.1)
    }
    
    public mutating func move(row: Int, col: Int, direction: Direction) -> Bool {
        return self.move(rowcol: (row, col), direction: direction)
    }

    public mutating func move(pos: Int, direction: Direction) -> Bool {
        return self.move(rowcol: (pos / rows, pos % columns), direction: direction)
    }
    
    public mutating func move(rowcol: (Int, Int), direction: Direction) -> Bool {
        let allRowColToMoveArray = _getAllRowColToMoveArray(rowcol: rowcol, direction: direction)
        let blocksToMoveSet = _getAllBlocksToMove(rowcolArray: allRowColToMoveArray)

        var from = 0, to = 0

        switch direction {
        case .North, .South:
            from = rowcol.1
            to = rowcol.1
            for block in blocksToMoveSet {
                from = min(from, block.col)
                to = max(to, block.col + block.width - 1)
            }
        case .East, .West:
            from = rowcol.0
            to = rowcol.0
            for block in blocksToMoveSet {
                from = min(from, block.row)
                to = max(to, block.row + block.heigth - 1)
            }
        }
        
        var allMovable = true
        for i in from...to {
            if _isNonMovable(rowOrCol: i, direction: direction) {
                allMovable = false
                break
            }
        }

        if allMovable {
            for i in from...to {
                _moveEntireRowOrCol(rowOrCol: i, direction: direction)
            }
            
            forceReloadAllEdges()
            return true
        }
        
        return false
    }

    public mutating func shortestPath(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int) -> [Direction]? {
        return self.shortestPath(fromRowCol: (fromRow, fromCol), toRowCol: (toRow, toCol))
    }
    
    public mutating func shortestPath(fromPos: Int, toPos: Int) -> [Direction]? {
        struct Path {
            var directions: [Direction]
            var pos: Int
        }
        
        var visited = [Bool](repeating: false, count: rows * columns)
        var queue = [Path]()
        
        queue.append(Path(directions: [Direction](), pos: fromPos))
        
        while !queue.isEmpty {
            let currentPath = queue.removeFirst()
            visited[currentPath.pos] = true
            
            if currentPath.pos == toPos {
                return currentPath.directions
            }
            
            for direction in boxes[currentPath.pos].directions {
                var _next: (Int) -> Int?
                var expectedDirection: Direction
                
                switch direction {
                case .North:
                    _next = _north
                    expectedDirection = .South
                case .East:
                    _next = _east
                    expectedDirection = .West
                case .South:
                    _next = _south
                    expectedDirection = .North
                case .West:
                    _next = _west
                    expectedDirection = .East
                }
                
                if let next = _next(currentPath.pos), !visited[next] {
                    for inputDirection in boxes[next].directions {
                        if inputDirection == expectedDirection {
                            var directions = currentPath.directions
                            directions.append(inputDirection)
                            queue.append(Path(directions: directions, pos: next))
                            break
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    public mutating func shortestPath(fromRowCol: (Int, Int), toRowCol: (Int, Int)) -> [Direction]? {
        return self.shortestPath(fromPos: fromRowCol.1 + (fromRowCol.0 * columns), toPos: toRowCol.1 + (toRowCol.0 * columns))
    }
    
    internal mutating func _moveEntireRowOrCol(rowOrCol: Int, direction: Direction) {
        var temp: Box!
        var start = 0
        var end = 0
        var increment = 0

        switch direction {
        case .North:
            start = rowOrCol
            temp = boxes[start]
            end = rows - 1
            increment = columns
        case .South:
            start = rowOrCol + ((rows-1) * columns)
            temp = boxes[start]
            end = rows - 1
            increment = -columns
        case .East:
            start = (rowOrCol * columns) + (columns-1)
            temp = boxes[start]
            end = columns - 1
            increment = -1
        case .West:
            start = rowOrCol * columns
            temp = boxes[start]
            end = columns - 1
            increment = 1
        }
        
        for _ in 0..<end {
            let next = start + increment
            boxes[start] = boxes[next]
            start = next
        }
        
        boxes[start] = temp
    }

    internal func _getAllRowColToMoveArray(rowcol: (Int,Int), direction: Direction) -> [(Int,Int)] {
        var allRowColArray = [(Int,Int)]()

        switch direction {
        case .North, .South:
            for i in 0..<rows {
                allRowColArray.append((i, rowcol.1))
            }
        case .East, .West:
            for i in 0..<columns {
                allRowColArray.append((rowcol.0, i))
            }
        }
        
        return allRowColArray
    }
    
    internal func _getAllBlocksToMove(rowcolArray: [(Int,Int)]) -> Set<Block> {
        var blocksToMoveSet = Set<Block>()
        
        for block in movableBlocks {
            for rowcol in rowcolArray {
                if block.containRowCol(rowcol: rowcol) {
                    blocksToMoveSet.insert(block)
                    break
                }
            }
        }
        
        return blocksToMoveSet
    }
    
    internal func  _isNonMovable(rowOrCol: Int, direction: Direction) -> Bool {
        for block in nonMovableBlocks {
            switch direction {
            case .North, .South:
                for i in 0..<rows {
                    if block.containRowCol(rowcol: (i, rowOrCol)) {
                        return true
                    }
                }
            case .East, .West:
                for i in 0..<columns {
                    if block.containRowCol(rowcol: (rowOrCol, i)) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
}
