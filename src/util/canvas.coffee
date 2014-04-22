
lerp = util.lerp


canvasBounds = (ctx) ->
  canvas = ctx.canvas
  {
    cxMin: 0
    cxMax: canvas.width
    cyMin: canvas.height
    cyMax: 0
    width: canvas.width
    height: canvas.height
  }


clear = (ctx) ->
  canvas = ctx.canvas
  ctx.clearRect(0, 0, canvas.width, canvas.height)


setStyle = (ctx, styleOpts) ->
  for own key, value of styleOpts
    ctx[key] = value


drawCartesian = (ctx, opts) ->
  xMin = opts.xMin
  xMax = opts.xMax
  yMin = opts.yMin
  yMax = opts.yMax
  fn = opts.fn
  testDiscontinuity = opts.testDiscontinuity ? () -> false

  {cxMin, cxMax, cyMin, cyMax} = canvasBounds(ctx)

  ctx.beginPath()


  numSamples = cxMax / config.resolution

  samples = []
  for i in [0..numSamples]
    cx = i * config.resolution
    x = lerp(cx, cxMin, cxMax, xMin, xMax)
    y = fn(x)
    cy = lerp(y, yMin, yMax, cyMin, cyMax)
    samples.push {x, y, cx, cy}



  pieces = []
  pieceStart = 0
  pushPiece = (pieceEnd) ->
    pieces.push {start: pieceStart, end: pieceEnd}
    pieceStart = pieceEnd

  for sample, i in samples
    if i == 0
      continue

    x = samples[i].x
    previousX = samples[i-1].x

    if testDiscontinuity([previousX, x])
      pushPiece(i-1)
      pieceStart = i

  pushPiece(samples.length-1)



  lines = []
  lineStart = 0
  pushLine = (lineEnd) ->
    lines.push {start: lineStart, end: lineEnd}
    lineStart = lineEnd

  for piece in pieces
    lineStart = piece.start
    for i in [piece.start+1 .. piece.end]

      if i - 1 == lineStart
        continue

      dCy1 = samples[i  ].cy - samples[i-1].cy
      dCy2 = samples[i-1].cy - samples[i-2].cy

      if Math.abs(dCy1 - dCy2) > .000001
        pushLine(i - 1)

      if i == piece.end
        pushLine(i)



  for line in lines
    start = samples[line.start]
    end = samples[line.end]
    if start.cx == end.cx
      ctx.moveTo(start.cx, start.cy)
      ctx.lineTo(end.cx+0.1, end.cy)
    else
      ctx.moveTo(start.cx, start.cy)
      ctx.lineTo(end.cx, end.cy)


drawVertical = (ctx, opts) ->
  xMin = opts.xMin
  xMax = opts.xMax
  x = opts.x

  {cxMin, cxMax, cyMin, cyMax} = canvasBounds(ctx)

  ctx.beginPath()
  cx = lerp(x, xMin, xMax, cxMin, cxMax)
  ctx.moveTo(cx, cyMin)
  ctx.lineTo(cx, cyMax)


drawHorizontal = (ctx, opts) ->
  yMin = opts.yMin
  yMax = opts.yMax
  y = opts.y

  {cxMin, cxMax, cyMin, cyMax} = canvasBounds(ctx)

  ctx.beginPath()
  cy = lerp(y, yMin, yMax, cyMin, cyMax)
  ctx.moveTo(cxMin, cy)
  ctx.lineTo(cxMax, cy)


# =============================================================================
# Grid
# =============================================================================

ticks = (spacing, min, max) ->
  first = Math.ceil(min / spacing)
  last = Math.floor(max / spacing)
  (x * spacing for x in [first..last])

drawLine = (ctx, [x1, y1], [x2, y2]) ->
  ctx.beginPath()
  ctx.moveTo(x1, y1)
  ctx.lineTo(x2, y2)
  ctx.stroke()

getSpacing = (opts) ->
  {xMin, xMax, yMin, yMax} = opts
  width = opts.width ? config.mainPlotWidth
  height = opts.height ? config.mainPlotHeight

  xSize = xMax - xMin
  ySize = yMax - yMin

  xMinSpacing = (xSize / width ) * config.minGridSpacing
  yMinSpacing = (ySize / height) * config.minGridSpacing
  minSpacing = Math.max(xMinSpacing, yMinSpacing)

  ###
  need to determine:
    largeSpacing = {1, 2, or 5} * 10^n
    smallSpacing = divide largeSpacing by 4 (if 1 or 2) or 5 (if 5)
  largeSpacing must be greater than minSpacing
  ###
  div = 4
  largeSpacing = z = Math.pow(10, Math.ceil(Math.log(minSpacing) / Math.log(10)))
  if z / 5 > minSpacing
    largeSpacing = z / 5
  else if z / 2 > minSpacing
    largeSpacing = z / 2
    div = 5
  smallSpacing = largeSpacing / div

  return {largeSpacing, smallSpacing}


drawGrid = (ctx, opts) ->
  xMin = opts.xMin
  xMax = opts.xMax
  yMin = opts.yMin
  yMax = opts.yMax

  {cxMin, cxMax, cyMin, cyMax, width, height} = canvasBounds(ctx)

  {largeSpacing, smallSpacing} = getSpacing({xMin, xMax, yMin, yMax, width, height})

  toLocal = ([cx, cy]) ->
    [
      lerp(cx, cxMin, cxMax, xMin, xMax)
      lerp(cy, cyMin, cyMax, yMin, yMax)
    ]
  fromLocal = ([x, y]) ->
    [
      lerp(x, xMin, xMax, cxMin, cxMax)
      lerp(y, yMin, yMax, cyMin, cyMax)
    ]

  labelDistance = 5
  color = config.gridColor
  minorOpacity = 0.075
  majorOpacity = 0.1
  axesOpacity = 0.25
  labelOpacity = 1.0
  textHeight = 12

  minorColor = "rgba(#{color}, #{minorOpacity})"
  majorColor = "rgba(#{color}, #{majorOpacity})"
  axesColor = "rgba(#{color}, #{axesOpacity})"
  labelColor = "rgba(#{color}, #{labelOpacity})"

  ctx.save()
  ctx.lineWidth = 1


  # draw minor grid lines
  ctx.strokeStyle = minorColor
  for x in ticks(smallSpacing, xMin, xMax)
    drawLine(ctx, fromLocal([x, yMin]), fromLocal([x, yMax]))
  for y in ticks(smallSpacing, yMin, yMax)
    drawLine(ctx, fromLocal([xMin, y]), fromLocal([xMax, y]))

  # draw major grid lines
  ctx.strokeStyle = majorColor
  for x in ticks(largeSpacing, xMin, xMax)
    drawLine(ctx, fromLocal([x, yMin]), fromLocal([x, yMax]))
  for y in ticks(largeSpacing, yMin, yMax)
    drawLine(ctx, fromLocal([xMin, y]), fromLocal([xMax, y]))

  # draw axes
  ctx.strokeStyle = axesColor
  drawLine(ctx, fromLocal([0, yMin]), fromLocal([0, yMax]))
  drawLine(ctx, fromLocal([xMin, 0]), fromLocal([xMax, 0]))

  # draw labels
  ctx.font = "#{textHeight}px verdana"
  ctx.fillStyle = labelColor
  ctx.textAlign = "center"
  ctx.textBaseline = "top"
  for x in ticks(largeSpacing, xMin, xMax)
    if x != 0
      text = parseFloat(x.toPrecision(12)).toString()
      [cx, cy] = fromLocal([x, 0])
      cy += labelDistance
      if cy < labelDistance
        cy = labelDistance
      if cy + textHeight + labelDistance > height
        cy = height - labelDistance - textHeight
      ctx.fillText(text, cx, cy)
  ctx.textAlign = "left"
  ctx.textBaseline = "middle"
  for y in ticks(largeSpacing, yMin, yMax)
    if y != 0
      text = parseFloat(y.toPrecision(12)).toString()
      [cx, cy] = fromLocal([0, y])
      cx += labelDistance
      if cx < labelDistance
        cx = labelDistance
      if cx + ctx.measureText(text).width + labelDistance > width
        cx = width - labelDistance - ctx.measureText(text).width
      ctx.fillText(text, cx, cy)

  ctx.restore()






util.canvas = {
  lerp
  clear
  setStyle
  drawCartesian
  drawVertical
  drawHorizontal
  getSpacing
  drawGrid
}
