R.create "GridView",
  propTypes:
    plot: C.Plot
    isThumbnail: Boolean

  _getParams: ->
    canvas = @getDOMNode()

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

  _draw: ->
    didResize = @_ensureProperSize()
    params = @_getParams()

    if !didResize and _.isEqual(params, @_lastParams)
      return

    @_lastParams = params

    canvas = @getDOMNode()

    ctx = canvas.getContext("2d")

    util.canvas.clear(ctx)

    util.canvas.drawGrid ctx, params

  _ensureProperSize: ->
    # Returns true if we had to resize the canvas.
    canvas = @getDOMNode()
    rect = canvas.getBoundingClientRect()
    if canvas.width != rect.width or canvas.height != rect.height
      canvas.width = rect.width
      canvas.height = rect.height
      return true
    return false

  componentDidMount: ->
    @_draw()

  componentDidUpdate: ->
    @_draw()

  render: ->
    R.canvas {}
