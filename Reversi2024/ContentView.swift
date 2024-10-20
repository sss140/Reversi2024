import SwiftUI

enum Stone:String{
    case black,white,none
    static var colored:Set<Self> = [.black,.white]
    func opposite()->Stone{
        switch self{
        case .black:
            return .white
        case .white:
            return .black
        case .none:
            fatalError()
        }
    }
    func color()->Color{
        switch self{
        case .black:
            return .black
        case .white:
            return .white
        case .none:
            return .clear
        }
    }
}

struct Cell:View {
    var stone:Stone = .none
    var targetStones:[Stone:[(y:Int,x:Int)]] = [.black:[],.white:[]]
    mutating func clearTargetStones(){
        for stone in Stone.colored{
            targetStones[stone]!.removeAll()
        }
    }
    var body: some View{
        ZStack(){
            Rectangle()
                .foregroundStyle(.green)
                .border(.black, width: 1.0)
            Circle()
                .foregroundStyle(stone.color())
        }.scaledToFit()
    }
}

class ReversiManager:ObservableObject{
    var turn:Stone = .black
    @Published var grid:[[Cell]] = []
    @Published var message:String = ""
    init(){
        setUp()
    }
    public func setUp(){
        turn = .black
        message = turn.rawValue.uppercased()
        grid = [[Cell]](repeating: [Cell](repeating: Cell(), count: 8), count: 8)
        putStone(3,3,.black)
        putStone(4,4,.black)
        putStone(3,4,.white)
        putStone(4,3,.white)
        calcAllCells()
    }
    private func putStone(_ y:Int,_ x:Int,_ stone:Stone){
        grid[y][x].stone = stone
    }
    private func calcAllCells(){
        for y in 0..<8{
            for x in 0..<8{
                grid[y][x].clearTargetStones()
                if(grid[y][x].stone == .none){
                    checkTargetStones(y,x)
                }
            }
        }
    }
    private func checkTargetStones(_ y:Int,_ x:Int){
        let directions:[(y:Int,x:Int)] = [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]
        for stone in Stone.colored{
            for direction in directions{
                let foundTargetStones:[(y:Int,x:Int)] = findTargetStones(y,x,direction.y,direction.x,stone)
                grid[y][x].targetStones[stone]!.append(contentsOf: foundTargetStones)
            }
        }
    }
    private func findTargetStones(_ y:Int,_ x:Int,_ dy:Int,_ dx:Int,_ stone:Stone)->[(y:Int,x:Int)]{
        let outOfBounds = {(y:Int,x:Int)->Bool in (!(0..<8).contains(y) || !(0..<8).contains(x))}
        var result:[(y:Int,x:Int)] = []
        var position:(y:Int,x:Int) = (y:y+dy,x:x+dx)
        
        if(outOfBounds(position.y, position.x)){return []}
        while(grid[position.y][position.x].stone != stone){
            if(grid[position.y][position.x].stone == .none){return []}
            result.append(position)
            position = (y:position.y+dy,x:position.x+dx)
            if(outOfBounds(position.y, position.x)){return []}
        }
        return result
    }
    public func progressGame(_ y:Int,_ x:Int){
        if(grid[y][x].targetStones[turn]!.isEmpty){return}
        putStone(y, x, turn)
        for targetStone in grid[y][x].targetStones[turn]!{
            putStone(targetStone.y, targetStone.x, turn)
        }
        calcAllCells()
        changeTurn()
    }
    private func changeTurn(){
        var canChange:[Stone:Bool] = [.black:false,.white:false]
        for y in 0..<8{
            for x in 0..<8{
                for stone in Stone.colored{
                    canChange[stone]! = !(grid[y][x].targetStones[stone]!.isEmpty) ? true:canChange[stone]!
                }
            }
        }
        turn = (canChange[turn.opposite()]!) ? turn.opposite():turn
        message = (!canChange[.black]! && !canChange[.white]!) ? "Game Over":turn.rawValue.uppercased()
    }
}

struct ContentView: View {
    @ObservedObject var reversiManager = ReversiManager()
    var body: some View {
        VStack(spacing: 0.0){
            ForEach(0..<8, id:\.self){y in
                HStack(spacing: 0.0){
                    ForEach(0..<8, id:\.self){x in
                        reversiManager.grid[y][x]
                            .onTapGesture {
                                reversiManager.progressGame(y, x)
                            }
                    }
                }
            }
        }
        VStack(){
            Text("\(reversiManager.message)")
            Button("Restart") {
                reversiManager.setUp()
            }
        }.font(.largeTitle)
    }
}

#Preview {
    ContentView()
}
