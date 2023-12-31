#!/usr/bin/env crystal

N = {-1, 0}
E = {0, +1}
S = {+1, 0}
W = {0, -1}

alias Coord = NamedTuple(row: Int32, col: Int32)

class Dimensions
  property height : Int32
  property width : Int32
  property start : Coord

  def initialize(@height = 0, @width = 0, @start = {row: -1, col: -1})
  end
end
Dimension = Dimensions.new

class Node
  property neighbours
  property steps
  property loc

  def initialize(@loc : Coord, @neighbours : Array(Coord))
    @steps = -1
  end
end

graph = Hash(Coord, Node).new

File.new("input.txt").each_line.with_index do |line, row|
  Dimension.width = line.size
  Dimension.height = row + 1
  line.chars.each_with_index do |c, col|

    next if c == 'O' || c == 'I'

    loc = { row: row, col: col }
    Dimension.start = loc if c == 'S'
    dest = {
      '|' => [N, S],
      '-' => [E, W],
      'L' => [N, E],
      'J' => [N, W],
      '7' => [S, W],
      'F' => [S, E],
      '.' => [] of Tuple(Int32, Int32),
      'S' => [] of Tuple(Int32, Int32),
    }[c].map{|dir|
      { row: row + dir[0], col: col + dir[1] }
    }.select{|n| n[:col] >= 0 && n[:col] < Dimension.width}
    graph[loc] = Node.new(loc, dest) if c == 'S' || dest.size > 0
  end
end

graph[Dimension.start] = Node.new(Dimension.start, [ N, E, S, W ].map{|dir|
  { row: graph[Dimension.start].loc[:row] + dir[0], col: graph[Dimension.start].loc[:col] + dir[1] }
}.select{|n| n[:col] >= 0 && n[:col] < Dimension.width})

graph.each{|id, node|
  node.neighbours = node.neighbours.select{|n| graph.has_key?(n) && graph[n].neighbours.includes?(id)}
}

unvisited = [ Dimension.start ]
steps = 0
while unvisited.size > 0
  unvisited = unvisited.map{|node|
    graph[node].steps = steps
    graph[node].neighbours.select{|n| graph[n].steps < 0 }
  }.flatten
  steps += 1
end

graph.reject!{|id, node| node.steps < 0}

graph.each{|id, node|
  puts id if node.neighbours.select{|n| !graph[n].neighbours.includes?(id)}.size > 0
}

#puts "graph ["
#puts "  directed 1"
#graph.each{|id, node|
#  puts "  node ["
#  puts "    id #{id}"
#  print "    label \"#{id // Dimension.width}x#{id % Dimension.width} @ #{node.steps}"
#  print " = start" if id == Dimension.start
#  puts "\""
#  puts "  ]"
#}
#def edge(f, t, b)
#  puts "  edge ["
#  puts "    source #{f}"
#  puts "    target #{t}"
#  puts "    graphics ["
#  puts "      sourceArrow \"standard\"" if b
#  puts "      targetArrow \"standard\""
#  puts "    ]"
#  puts "  ]"
#end
#graph.each{|id, node|
#  node.neighbours.each{|n|
#    if graph[n].neighbours.includes?(id)
#      edge(id, n, true) if n < id
#    else
#      edge(id, n, false)
#    end
#  }
#}
#puts "]"

puts "part 1: #{graph.values.map{|n| n.steps}.max}"

stretch = graph.values.reduce(Hash(Coord, Coord).new){|map, node|
  map[node.loc] = { row: node.loc[:row] * 2, col: node.loc[:col] * 2 }
  map
}
graph.values.each{|node|
  node.loc = stretch[node.loc]
  node.neighbours = node.neighbours.map{|n| stretch[n]}
}
graph = graph.values.reduce(Hash(Coord, Node).new){|g, node|
  g[node.loc] = node 
  g
}
Dimension.height = Dimension.height * 2
Dimension.width = Dimension.width * 2

Grid = (0...Dimension.height).map{ (0...Dimension.width).map{ ' ' } }
graph.each{|id, node|
  Grid[node.loc[:row]][node.loc[:col]] = '\u2588'

  node.neighbours.each{|n|
    neighbour = graph[n]
    row = (node.loc[:row] + neighbour.loc[:row]) // 2
    col = (node.loc[:col] + neighbour.loc[:col]) // 2
    Grid[row][col] = '\u2592'
  }
}

def flood(row : Int32, col : Int32)
  return if row < 0 || row >= Dimension.height
  return if col < 0 || col >= Dimension.width

  return if Grid[row][col] != ' '

  Grid[row][col] = '\u2591'

  [ N, E, S, W ].each{|dir| flood(row + dir[0], col + dir[1]) }
end

(0...Dimension.height).each do |row|
  flood(row, 0)
  flood(row, Dimension.width - 1)
end
(0...Dimension.width).each do |col|
  flood(0, col)
  flood(0, Dimension.height - 1)
end

#Grid.each{|row|
#  row.each{|cell| print cell }
#  puts
#}

puts "part 2: #{(0...Dimension.height).step(2).map{|row| (0...Dimension.width).step(2).map{|col| Grid[row][col] == ' ' ? 1 : 0 }.sum }.sum}"
