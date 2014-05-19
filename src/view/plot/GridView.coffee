R.create "GridView",
  propTypes:
    plot: C.Plot

  drawFn: (canvas) ->
    ctx = canvas.getContext("2d")

    {xMin, xMax, yMin, yMax} = @plot.getBounds(canvas.width, canvas.height)

    util.canvas.clear(ctx)

    util.canvas.drawGrid ctx,
      xMin: xMin
      xMax: xMax
      yMin: yMin
      yMax: yMax
      pixelSize: @plot.getPixelSize(canvas.width, canvas.height)

  shouldComponentUpdate: (nextProps) ->
    return true

  render: ->
    R.CanvasView {drawFn: @drawFn}
