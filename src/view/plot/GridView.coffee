R.create "GridView",
  propTypes:
    bounds: Object

  drawFn: (canvas) ->
    ctx = canvas.getContext("2d")

    {xMin, xMax, yMin, yMax} = @bounds

    util.canvas.clear(ctx)

    util.canvas.drawGrid ctx,
      xMin: xMin
      xMax: xMax
      yMin: yMin
      yMax: yMax

  shouldComponentUpdate: (nextProps) ->
    return @bounds != nextProps.bounds

  render: ->
    R.CanvasView {drawFn: @drawFn}
