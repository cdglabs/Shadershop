
lerp = util.lerp

devicePixelRatio = window.devicePixelRatio || 1 # Scale canvas for HiDPI displays

canvasBounds = (ctx) ->
  canvas = ctx.canvas
  canvas.width *= devicePixelRatio
  canvas.height *= devicePixelRatio
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

getSpacing = (pixelSize) ->
  # minSpacing is the minimum distance, in world coordinates, between major
  # grid lines.
  minSpacing = pixelSize * config.minGridSpacing

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
  pixelSize = opts.pixelSize
  xLabel = opts.xLabel
  yLabel = opts.yLabel
  xLabelColor = opts.xLabelColor
  yLabelColor = opts.yLabelColor

  {cxMin, cxMax, cyMin, cyMax, width, height} = canvasBounds(ctx)

  {largeSpacing, smallSpacing} = getSpacing(pixelSize)

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
  labelEdgeDistance = labelDistance * 6 # To keep it from overlapping the axis labels
  ctx.font = "#{textHeight * devicePixelRatio}px verdana" # Scale font size for HiDPI displays
  ctx.fillStyle = labelColor
  ctx.textAlign = "center"
  ctx.textBaseline = "top"
  for x in ticks(largeSpacing, xMin, xMax)
    if x != 0
      text = parseFloat(x.toPrecision(12)).toString()
      [cx, cy] = fromLocal([x, 0])
      if cx < cxMax - labelEdgeDistance
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
      if cy > labelEdgeDistance
        cx += labelDistance
        if cx < labelDistance
          cx = labelDistance
        if cx + ctx.measureText(text).width + labelDistance > width
          cx = width - labelDistance - ctx.measureText(text).width
        ctx.fillText(text, cx, cy)

  # draw axis labels
  # TODO: The axis labels overlap if you're in the lower left quadrant.
  if xLabel
    [originX, originY] = fromLocal([0, 0])

    text = xLabel
    ctx.fillStyle = xLabelColor
    cx = cxMax - labelDistance
    cy = originY + labelDistance
    if cy < labelDistance
      cy = labelDistance
    if cy + textHeight + labelDistance > height
      cy = height - labelDistance - textHeight
    ctx.textAlign = "right"
    ctx.textBaseline = "top"
    ctx.fillText(text, cx, cy)

    text = yLabel
    ctx.fillStyle = yLabelColor
    cx = originX + labelDistance
    cy = labelDistance
    if cx < labelDistance
      cx = labelDistance
    if cx + ctx.measureText(text).width + labelDistance > width
      cx = width - labelDistance - ctx.measureText(text).width
    ctx.textAlign = "left"
    ctx.textBaseline = "top"
    ctx.fillText(text, cx, cy)

  ctx.restore()






util.canvas = {
  lerp
  clear
  getSpacing
  drawGrid
}
