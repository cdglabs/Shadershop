R.create "GridView",
  propTypes:
    plot: C.Plot
    isThumbnail: Boolean

  _getParams: ->
    params = {}

    canvas = @getDOMNode()

    if @isThumbnail
      scaleFactor = window.innerHeight / canvas.height
    else
      scaleFactor = 1

    minWorld = @plot.toWorld({x: -canvas.width * scaleFactor / 2, y: -canvas.height * scaleFactor / 2})
    maxWorld = @plot.toWorld({x:  canvas.width * scaleFactor / 2, y:  canvas.height * scaleFactor / 2})

    dimensions = @plot.getDimensions()
    params.xMin = numeric.dot(minWorld, dimensions[0])
    params.yMin = numeric.dot(minWorld, dimensions[1])
    params.xMax = numeric.dot(maxWorld, dimensions[0])
    params.yMax = numeric.dot(maxWorld, dimensions[1])

    params.pixelSize = @plot.getPixelSize() * scaleFactor

    # Hacky way to see if we should draw axis labels
    if scaleFactor == 1
      xCoord = dimensions[0].indexOf(1)
      if xCoord < config.dimensions
        params.xLabelColor = config.domainLabelColor
        params.xLabel = "x" + (xCoord+1)
      else
        params.xLabelColor = config.rangeLabelColor
        params.xLabel = "y" + (xCoord+1 - config.dimensions)

      yCoord = dimensions[1].indexOf(1)
      if yCoord < config.dimensions
        params.yLabelColor = config.domainLabelColor
        params.yLabel = "x" + (yCoord+1)
      else
        params.yLabelColor = config.rangeLabelColor
        params.yLabel = "y" + (yCoord+1 - config.dimensions)

    return params

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
