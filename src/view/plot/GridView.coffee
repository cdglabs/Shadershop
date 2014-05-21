R.create "GridView",
  propTypes:
    plot: C.Plot
    isThumbnail: Boolean

  drawFn: (canvas) ->
    ctx = canvas.getContext("2d")

    if @isThumbnail
      scaleFactor = window.innerHeight / canvas.height
    else
      scaleFactor = 1

    bounds = @plot.getScaledBounds(canvas.width, canvas.height, scaleFactor)
    {xMin, xMax, yMin, yMax} = bounds

    util.canvas.clear(ctx)

    util.canvas.drawGrid ctx,
      xMin: xMin
      xMax: xMax
      yMin: yMin
      yMax: yMax
      pixelSize: @plot.getPixelSize(canvas.width, canvas.height) * scaleFactor

  shouldComponentUpdate: (nextProps) ->
    return true

  render: ->
    R.CanvasView {drawFn: @drawFn}
