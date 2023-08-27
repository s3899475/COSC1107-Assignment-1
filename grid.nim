# chunked grid
import std/deques
from std/sequtils import repeat

type
  Grid*[T] = ref object
    arr*: Deque[Deque[T]]
    min_x*, min_y*: int
    default: T

proc newGrid*[T](default: T): Grid[T] =
  var
    y = initDeque[Deque[T]]()
  y.addFirst(initDeque[T]())
  y[0].addFirst default
  Grid[T](arr: y, min_x: 0, min_y: 0, default: default)

func `$`*[T](g: Grid[T]): string =
  for row in g.arr:
    for val in row:
      result &= $val
    result &= '\n'

proc expand_to*[T](g: var Grid[T], x, y: int) =
  let
    max_x = g.arr[0].len + g.min_x - 1
    max_y = g.arr.len + g.min_y - 1
  if y > max_y:
    for _ in 1..y-max_y:
      g.arr.addLast repeat(g.default, g.arr[0].len).toDeque
  if y < g.min_y:
    for _ in 1..g.min_y-y:
      g.arr.addFirst repeat(g.default, g.arr[0].len).toDeque
    g.min_y = y

  if x > max_x:
    for d in g.arr.mitems:
      for _ in 1..x-max_x:
        d.addLast g.default
  if x < g.min_x:
    for d in g.arr.mitems:
      for _ in 1..g.min_x-x:
        d.addFirst g.default
    g.min_x = x

# get
proc `[]`*[T](g: var Grid[T], x, y: int): T =
  g.expand_to(x, y)
  g.arr[y-g.min_y][x-g.min_x]

# set
proc `[]=`*[T](g: var Grid[T], x, y: int, sink: T) =
  g.expand_to(x, y)
  g.arr[y-g.min_y][x-g.min_x] = sink


when isMainModule:
  var g = newGrid[bool](false)
  g[0, 0] = true
  g[1, 0] = true
  g[1, 1] = true
  g[2, 2] = true

  echo g
  echo "y: ", g.arr.len
  echo "x: ", g.arr[0].len


  type
    LE = enum
      A
      B

  var g1 = newGrid[LE](A)
  echo g1


