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

  draw: ->
    canvas = @getDOMNode()

    @_lastParams = params = @_getParams()

    ctx = canvas.getContext("2d")

    util.canvas.clear(ctx)

    util.canvas.drawGrid ctx, params

  ensureProperSize: ->
    # Returns true if we had to resize the canvas.
    canvas = @getDOMNode()
    rect = canvas.getBoundingClientRect()
    if canvas.width != rect.width or canvas.height != rect.height
      canvas.width = rect.width
      canvas.height = rect.height
      return true
    return false

  shouldComponentUpdate: (nextProps) ->
    return true if @ensureProperSize()
    return !_.isEqual(@_lastParams, @_getParams(@getDOMNode()))

  componentDidMount: ->
    @ensureProperSize()
    @draw()

  componentDidUpdate: ->
    @draw()

  render: ->
    R.canvas {}
