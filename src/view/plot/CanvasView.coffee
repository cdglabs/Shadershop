R.create "CanvasView",
  propTypes: {
    drawFn: Function
  }

  draw: ->
    canvas = @getDOMNode()
    @drawFn(canvas)

  sizeCanvas: ->
    canvas = @getDOMNode()
    rect = canvas.getBoundingClientRect()
    if canvas.width != rect.width or canvas.height != rect.height
      canvas.width = rect.width
      canvas.height = rect.height
      return true
    return false

  handleResize: ->
    if @sizeCanvas()
      @draw()

  componentDidUpdate: ->
    @draw()

  componentDidMount: ->
    @sizeCanvas()
    @draw()
    window.addEventListener("resize", @handleResize)

  componentWillUnmount: ->
    window.removeEventListener("resize", @handleResize)

  render: ->
    R.canvas {}