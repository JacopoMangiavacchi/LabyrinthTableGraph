import Foundation

public enum Rotation : Int {
    case Right, Left
}

fileprivate protocol Rotate {
    mutating func rotate(_ rotation: Rotation)
}

public enum Orientation : Int, Rotate, Codable  {
    case Vertical, Horizontal  // 2
    
    mutating func rotate(_ rotation: Rotation) {
        self = Orientation(rawValue: (self.rawValue + 1) % 2)!
    }
}

public enum Direction : Int, Rotate, Codable  {
    case North, East, South, West // 4

    mutating func rotate(_ rotation: Rotation) {
        switch rotation {
        case .Right:
            self = Direction(rawValue: (self.rawValue + 1) % 4)!
        case .Left:
            if self == .North {
                self = .West
            }
            else {
                self = Direction(rawValue: (self.rawValue - 1) % 4)!
            }
        }
    }
}

public enum BoxType : String, Codable {
    case None                               // X
    case Cross                              // +
    case Linear                             // - |
    case Curved                             // L ∧>∨<
    case Intersection                       // ⊤⊣⊥⊢
}

public enum Box : Rotate, CustomStringConvertible, Codable {
    case None                               // X
    case Cross                              // +
    case Linear(orientation: Orientation)   // - |
    case Curved(direction: Direction)       // L ∧>∨<
    case Intersection(direction: Direction) // ⊤⊣⊥⊢
    
    mutating func rotate(_ rotation: Rotation) {
        switch self {
        case .None:
            break
        case .Cross:
            break
        case var .Linear(orientation):
            orientation.rotate(rotation)
            self = .Linear(orientation: orientation)
        case var .Curved(direction):
            direction.rotate(rotation)
            self = .Curved(direction: direction)
        case var .Intersection(direction):
            direction.rotate(rotation)
            self = .Intersection(direction: direction)
        }
    }
    
    var directions: [Direction] {
        var directions = [Direction]()
        
        switch self {
        case .None:                                 // X
            break
        case .Cross:                                // +
            directions.append(contentsOf: [.North, .East, .South, .West])
        case let .Linear(orientation):
            switch orientation {
            case .Horizontal:                       // -
                directions.append(contentsOf: [.East, .West])
            case .Vertical:                         // |
                directions.append(contentsOf: [.North, .South])
            }
        case let .Curved(direction):
            switch direction {
            case .North:                            // L  ∧
                directions.append(contentsOf: [.North, .East])
            case .East:                             // L  >
                directions.append(contentsOf: [.East, .South])
            case .South:                            // L  ∨
                directions.append(contentsOf: [.South, .West])
            case .West:                             // L  <
                directions.append(contentsOf: [.North, .West])
            }
        case let .Intersection(direction):
            switch direction {
            case .North:                            // ⊤
                directions.append(contentsOf: [.East, .South, .West])
            case .East:                             // ⊣
                directions.append(contentsOf: [.North, .South, .West])
            case .South:                            // ⊥
                directions.append(contentsOf: [.North, .East, .West])
            case .West:                             // ⊢
                directions.append(contentsOf: [.North, .East, .South])
            }
        }
        
        return directions
    }
    
    public var description: String {
        switch self {
        case .None:
            return "x"
        case .Cross:
            return "+"
        case let .Linear(orientation):
            switch orientation {
            case .Horizontal:
                return "-"
            case .Vertical:
                return "|"
            }
        case let .Curved(direction):
            switch direction {
            case .North:
                return "∧"
            case .East:
                return ">"
            case .South:
                return "∨"
            case .West:
                return "<"
            }
        case let .Intersection(direction):
            switch direction {
            case .North:
                return "⊤"
            case .East:
                return "⊣"
            case .South:
                return "⊥"
            case .West:
                return "⊢"
            }
        }
    }

    // Custom Encode / Decode
    // Enum with Associated Values Cannot Have a Raw Value and cannot be auto Codable
    
    struct BoxStruct : Codable {
        let type: BoxType
        let orientation: Orientation?
        let direction: Direction?
    }
    
    enum DecodeError : Error {
        case MissingOrientation
        case MissingDirection
    }
    
    public init(from decoder: Decoder) throws {
        let boxStruct = try BoxStruct(from: decoder)
        
        switch boxStruct.type {
        case .None:
            self = Box.None
        case .Cross:
            self = Box.Cross
        case .Linear:
            if let o = boxStruct.orientation {
                self = Box.Linear(orientation: o)
            }
            else {
                throw DecodeError.MissingOrientation
            }
        case .Curved:
            if let d = boxStruct.direction {
                self = Box.Curved(direction: d)
            }
            else {
                throw DecodeError.MissingDirection
            }
        case .Intersection:
            if let d = boxStruct.direction {
                self = Box.Intersection(direction: d)
            }
            else {
                throw DecodeError.MissingDirection
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var type: BoxType
        var orientation: Orientation?
        var direction: Direction?
        
        switch self {
        case .None:
            type = .None
        case .Cross:
            type = .Cross
        case let .Linear(o):
            type = .Linear
            orientation = o
        case let .Curved(d):
            type = .Curved
            direction = d
        case let .Intersection(d):
            type = .Intersection
            direction = d
        }

        try BoxStruct(type: type, orientation: orientation, direction: direction).encode(to: encoder)
    }
}