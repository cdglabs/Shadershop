R.create "GridView",
  propTypes:
    plot: C.Plot
    isThumbnail: Boolean

  _getParams: (canvas) ->
    if @isThumbnail
      scaleFactor = window.innerHeight / canvas.height
    else
      scaleFactor = 1

    minWorld = @plot.toWorld({x: -canvas.width * scaleFactor / 2, y: -canvas.height * scaleFactor / 2})
    maxWorld = @plot.toWorld({x:  canvas.width * scaleFactor / 2, y:  canvas.height * scaleFactor / 2})

    dimensions = @plot.getDimensions()
    xMin = numeric.dot(minWorld, dimensions[0])
    yMin = numeric.dot(minWorld, dimensions[1])
    xMax = numeric.dot(maxWorld, dimensions[0])
    yMax = numeric.dot(maxWorld, dimensions[1])

    return {
      xMin: xMin
      xMax: xMax
      yMin: yMin
      yMax: yMax
      pixelSize: @plot.getPixelSize() * scaleFactor
    }

  drawFn: (canvas) ->
    @_lastParams = params = @_getParams(canvas)

    ctx = canvas.getContext("2d")

    util.canvas.clear(ctx)

    util.canvas.drawGrid ctx, params

  shouldComponentUpdate: (nextProps) ->
    return !_.isEqual(@_lastParams, @_getParams(@getDOMNode()))

  render: ->
    R.CanvasView {drawFn: @drawFn}
