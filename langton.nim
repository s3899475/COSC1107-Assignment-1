# simple langton's ant simulation
import grid

type
  Direction = enum
    UP,
    RI,
    DN,
    LE

  Turn = enum
    None,
    Left,
    Right,
    UTurn

  Position = tuple[x, y: int]

  Ant* = ref object
    def: string
    nstates*: int
    grid*: Grid[int]
    dir*: Direction
    pos*: Position

proc initAnt*(def: string, initial_dir: Direction = UP): Ant =
  Ant(def: def, nstates:def.len, grid: newGrid[int](default=0), dir: initial_dir, pos: (0, 0))


proc to_rotation(ch: char): Turn =
  case ch
  of 'N':
    None
  of 'L':
    Left
  of 'R':
    Right
  of 'U':
    UTurn
  else:
    raise newException(ValueError, "invalid ant definition")

proc change_state(a: var Ant) =
  let state = a.grid[a.pos.x, a.pos.y]
  if state + 1 < a.nstates:
    a.grid[a.pos.x, a.pos.y] = state + 1
  else: 
    a.grid[a.pos.x, a.pos.y] = 0

proc turn(a: var Ant, turn: Turn) =
  case turn
  of None:
    discard
  of Right:
    case a.dir
    of UP:
      a.dir = RI
    of RI:
      a.dir = DN
    of DN:
      a.dir = LE
    of LE:
      a.dir = UP
  of Left:
    case a.dir
    of UP:
      a.dir = LE
    of RI:
      a.dir = UP
    of DN:
      a.dir = RI
    of LE:
      a.dir = DN
  of UTurn:
    case a.dir
    of UP:
      a.dir = DN
    of RI:
      a.dir = LE
    of DN:
      a.dir = UP
    of LE:
      a.dir = RI

proc move(a: var Ant) =
  case a.dir
  of UP:
    a.pos.y -= 1
  of RI:
    a.pos.x += 1
  of DN:
    a.pos.y += 1
  of LE:
    a.pos.x -= 1

proc get_state*(a: var Ant): int =
  a.grid[a.pos.x, a.pos.y]

proc step*(a: var Ant) =
  let state = a.get_state()
  a.turn(a.def[state].to_rotation)
  a.change_state()
  a.move()
  a.grid.expand_to(a.pos.x, a.pos.y)


when defined(debug):
  import deques
  func display_repr(state: int): string =
    case state
    of 1:
      "█"
    of 0:
      "·"
    else:
      " "

  # debug print
  proc `$`*(a: var Ant): string =
    for y, row in a.grid.arr:
      for x, val in row:
        if (x == a.pos.x - a.grid.min_x) and (y == a.pos.y - a.grid.min_y):
          result &= 'A'
        else:
          result &= display_repr(val)
      result &= '\n'


