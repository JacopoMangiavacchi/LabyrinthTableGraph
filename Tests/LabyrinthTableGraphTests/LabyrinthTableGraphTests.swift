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
   
    func moveTest() {
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

        //XCTAssertEqual(t.description, "...")
    }

    func jsonTest() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        //XCTAssertEqual(LabyrinthTableGraph().text, "Hello, World!")
    }

    func dijkstraTest() {
        t[2,0] = Box.Intersection(direction: .North)
        t[2,1] = Box.Intersection(direction: .South)
        t[2,2] = Box.Linear(orientation: .Horizontal)
        t[2,3] = Box.Intersection(direction: .East)
        t[2,4] = Box.Intersection(direction: .West)

        let path = t.shortestPath(fromRowCol: (2, 0), toRowCol: (2, 4))

        //XCTAssertEqual(path, "...")
    }

    static var allTests = [
        ("moveTest", moveTest),
        ("jsonTest", jsonTest),
        ("dijkstraTest", dijkstraTest)
    ]
}
