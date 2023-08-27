# js langton's ant display
import dom
import deques
from math import ceil, pow
from strutils import parseInt, parseFloat, allCharsInSet

import ../grid
import ../langton

const
  INITIAL_GRID_SIZE = 256
  # scale goes in reverse
  INITIAL_SCALE = 4
  MAX_SCALE = 256

type
  Canvas* = ref CanvasObj
  CanvasObj {.importc.} = object of dom.Element
    width*: int
    height*: int
  
  CanvasContext2d* = ref CanvasContext2dObj
  CanvasContext2dObj {.importc.} = object
    canvas*: Canvas
    font*: cstring
    fillStyle*: cstring # converting to hex in nim js core seems very slow

  Button* = ref ButtonObj
  ButtonObj {.importc.} = object of dom.Element

  WheelEvent* = ref WheelEventObj
  WheelEventObj {.importc.} = object of dom.MouseEvent
    deltaY*: float


proc getContext2d*(c: Canvas): CanvasContext2d =
  {.emit: "`result` = `c`.getContext('2d');".}

proc beginPath*(ctx: CanvasContext2d) {.importcpp.}
proc closePath*(ctx: CanvasContext2d) {.importcpp.}
proc stroke*(ctx: CanvasContext2d) {.importcpp.}
proc strokeText*(ctx: CanvasContext2d, txt: cstring, x, y: float) {.importcpp.}
proc fillRect*(ctx: CanvasContext2d, x, y, width, height: int) {.importcpp.}
proc clearRect*(ctx: CanvasContext2d, x, y, width, height: int) {.importcpp.}
# only works with literals >:(
#proc fillStyle*(ctx: CanvasContext2d, r, g, b: float) =
#  {.emit: "`ctx`.fillStyle = ``rgb(`r`,`g`,`b`)``;".}
#template fillStyle(ctx: CanvasContext2d, col: tuple[r, g, b: float]) =
#  ctx.fillStyle(col.r, col.g, col.b)

template id(str: string): Element = dom.document.getElementById(str)

# draw a single "pixel" on the grid
proc draw_on_grid(ctx: CanvasContext2d, x, y: int, scale: int) =
  let grid_size: int = INITIAL_GRID_SIZE div scale
  let pos: tuple[x, y: int] = (
    ctx.canvas.width div 2 + x*grid_size,
    ctx.canvas.height div 2 + y*grid_size
  )
  ctx.fillRect(
    pos.x - grid_size div 2 - 1,
    pos.y - grid_size div 2 - 1,
    grid_size,
    grid_size
  )

# greyscale colour palette
proc greyscale(top: int, val: int): cstring =
  let shade = $(255 - math.ceil(val.float / top.float * 255))
  #fmt"rgb({shade}, {shade}, {shade})".cstring
  cstring("rgb(" & shade & "," & shade & "," & shade & ")")

# rainbow colour palette
proc rainbow(top: int, val: int): cstring =
  if val == 0:
    cstring("#FFFFFF")
  else:
    let hue = $(360 - math.ceil(val.float / top.float * 360))
    cstring("hsl(" & hue & ",90%,50%)")

# generate full palette
proc gen_palette(a: Ant, palette: cstring): seq[cstring] =
  var fn: proc(top, val: int): cstring
  case palette:
    of "greyscale":
      fn = greyscale
    of "rainbow":
      fn = rainbow
    else:
      fn = greyscale

  for i in 0..<a.nstates:
    result.add fn(a.nstates-1, i)

proc draw(ctx: CanvasContext2d, a: Ant, scale: int,
  palette: seq[cstring]) =
  # clear canvas
  ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height)

  # draw grid spaces
  for y_idx, row in a.grid.arr:
    for x_idx, val in row:
      let (x, y) = (x_idx+a.grid.min_x, y_idx+a.grid.min_y)
      if val > 0:
        ctx.fillStyle = palette[val]
        ctx.draw_on_grid(x, y, scale)

proc draw_ant(ctx: CanvasContext2d, a: Ant, scale: int, colour: cstring = "red") =
  ctx.fillStyle = colour
  ctx.draw_on_grid(a.pos.x*2, a.pos.y*2, scale*2)

proc fitCanvas(c: Canvas) =
  c.width = dom.window.innerWidth
  c.height = dom.window.innerHeight

proc get_interval(idx: int): int =
  let values = [5, 10, 50, 100, 200, 500, 1000, 2000]
  if idx < 0 or idx > values.len-1:
    100
  else:
    values[idx]

proc definition_valid(def: string): bool =
  def != "" and def.allCharsInSet({'L', 'R', 'U', 'N'})

# initaliase
dom.window.onload = proc (e: dom.Event) =
  # element selectors
  let antDefinition = id"AntDefinition"
  let jumpSlider = id"JumpSlider"
  let jumpValueLabel = id"JumpValueLabel"
  let intervalSlider = id"IntervalSlider"
  let intervalValueLabel = id"IntervalValueLabel"
  let paletteSelector = id"PaletteSelector"
  let showAntCheck = id"ShowAntCheck"
  let errorText = id"ErrorText"
  # initialize settings
  var
    running = false
    scale = INITIAL_SCALE
    jump = math.pow(10, parseFloat($jumpSlider.value)).int
    interval = get_interval(parseInt($intervalSlider.value))
    show_ant = showAntCheck.checked
    ant: Ant
    palette: seq[cstring]

  if definition_valid($antDefinition.value):
    ant = initAnt($antDefinition.value) # will be "RL" by default, set in html
  else:
    errorText.textContent = "Ant definition must contain only: (L,R,U,N)"
    ant = initAnt("RL")

  palette = ant.gen_palette(paletteSelector.value)

  jumpValueLabel.textContent = cstring($jump)
  intervalValueLabel.textContent = cstring($interval)

  let c = id"Langton".Canvas
  let ctx = c.getContext2d()
  c.fitCanvas
  ctx.draw(ant, scale, palette)
  if show_ant:
    ctx.draw_ant(ant, scale)

  # update canvas size on window resize
  dom.window.addEventListener("resize", proc(event: dom.Event) =
    c.fitCanvas
    ctx.draw(ant, scale, palette)
    if show_ant:
      ctx.draw_ant(ant, scale)
  )

  # zoom in and out on canvas
  c.addEventListener("wheel", proc(event: dom.Event) =
    let up_scroll = event.UIEvent.MouseEvent.WheelEvent.deltaY < 0 # works!
    if up_scroll:
      # use ceil to make it always 1 or greater
      scale = math.ceil(scale.float / 2).int
    elif scale < MAX_SCALE: # stop overflow
      scale = scale * 2 # *= generates weird js?
    ctx.draw(ant, scale, palette)
    if show_ant:
      ctx.draw_ant(ant, scale)

    # dont scroll canvas on page
    event.stopImmediatePropagation()
  )

  # Start and stop the simulation
  let runButton = id"RunButton".Button
  runButton.onclick = proc(event: dom.Event) =
    if running:
      runButton.textContent = "Run"
      running = false
    else:
      runButton.textContent = "Stop"
      running = true

  # Jump through multiple iterations
  jumpSlider.addEventListener("input", proc(event: dom.Event) =
    jump = math.pow(10, parseFloat($event.target.value)).int
    jumpValueLabel.textContent = cstring($jump)
  )

  # Change to a different ant
  let restartButton = id"RestartButton"
  restartButton.onclick = proc(event: dom.Event) =
    if definition_valid($antDefinition.value):
      errorText.textContent = ""
      ant = initAnt($antDefinition.value)
      palette = ant.gen_palette(paletteSelector.value)

      ctx.draw(ant, scale, palette)
      if show_ant:
        ctx.draw_ant(ant, scale)
    else:
      running = false
      errorText.textContent = "Ant definition must contain only: (L,R,U,N)"

  # Change colour palette
  paletteSelector.onchange = proc(event: dom.Event) =
    palette = ant.gen_palette(paletteSelector.value)
    ctx.draw(ant, scale, palette)
    if show_ant:
      ctx.draw_ant(ant, scale)

  # Show/Don't show ant
  showAntCheck.onchange = proc(event: dom.Event) =
    show_ant = showAntCheck.checked
    ctx.draw(ant, scale, palette)
    if show_ant:
      ctx.draw_ant(ant, scale)

  # main loop
  proc main() =
    if running:
      if jump == 1:# incremental draw
        let prev_pos = ant.pos
        ant.step()

        ctx.fillStyle = palette[ant.grid[prev_pos.x, prev_pos.y]]
        ctx.draw_on_grid(prev_pos.x, prev_pos.y, scale)
        if show_ant:
          ctx.draw_ant(ant, scale)
      else:
        for _ in 1..jump:
          ant.step()
        ctx.draw(ant, scale, palette)
        if show_ant:
          ctx.draw_ant(ant, scale)

  var mainInterval = window.setInterval(main, interval)
  
  intervalSlider.addEventListener("input", proc(event: dom.Event) =
    interval = get_interval(parseInt($intervalSlider.value))
    intervalValueLabel.textContent = cstring($interval)
    mainInterval.clearInterval()
    mainInterval = window.setInterval(main, interval)
  )

