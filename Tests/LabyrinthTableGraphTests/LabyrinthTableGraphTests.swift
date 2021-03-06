import XCTest
@testable import LabyrinthTableGraph

class LabyrinthTableGraphTests: XCTestCase {

    var t: LabyrinthTableGraph!

    override func setUp() {
        super.setUp()

        t = LabyrinthTableGraph(rows: 5, columns: 5)
    }
   
    override func tearDown() {
        super.tearDown()
    }
   
    func testMove() {
        t[2,0] = Box.Intersection(direction: .North)
        t[2,1] = Box.Intersection(direction: .South)
        t[2,2] = Box.Linear(orientation: .Horizontal)
        t[2,3] = Box.Intersection(direction: .East)
        t[2,4] = Box.Intersection(direction: .West)

        //t.move(rowcol: (2, 2), direction: .East)
        t.addMovableBlock(block: Block(row: 1, col: 2, width: 3, heigth: 3))
        t.addNonMovableBlock(block: Block(row: 4, col: 2, width: 1, heigth: 1))

        let ret = t.move(rowcol: (1, 2), direction: .East)
        
        XCTAssertEqual(ret, true)

        XCTAssertEqual(t.description, """
xxxxx
xxxxx
⊢⊤⊥-⊣
xxxxx
xxxxx

""")
    }

    func testJson() {
        t[2,0] = Box.Intersection(direction: .North)
        t[2,1] = Box.Intersection(direction: .South)
        t[2,2] = Box.Linear(orientation: .Horizontal)
        t[2,3] = Box.Intersection(direction: .East)
        t[2,4] = Box.Intersection(direction: .West)

        let original = t.description

        let data = try! JSONEncoder().encode(t)
        //let string = String(data: data, encoding: .utf8)!

        let t2 = try! JSONDecoder().decode(LabyrinthTableGraph.self, from: data)
        
        let reEncoded = t2.description

        XCTAssertEqual(original, reEncoded)
    }

    func testDijkstra() {
        t[2,0] = Box.Intersection(direction: .North)
        t[2,1] = Box.Intersection(direction: .South)
        t[2,2] = Box.Linear(orientation: .Horizontal)
        t[2,3] = Box.Intersection(direction: .East)
        t[2,4] = Box.Intersection(direction: .West)

        let path = t.shortestPath(fromRowCol: (2, 0), toRowCol: (2, 3))
        let pathString = path!.compactMap{ String($0.rawValue) }.reduce("") { $0 + $1 + "-" }

        XCTAssertEqual(pathString, "3-3-3-")
    }

    static var allTests = [
        ("testMove", testMove),
        ("testJson", testJson),
        ("testDijkstra", testDijkstra)
    ]
}
