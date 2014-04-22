R.create "PlotCartesianView",
  propTypes:
    bounds: Object
    fnString: String
    style: Object

  drawFn: (canvas) ->
    ctx = canvas.getContext("2d")

    fn = util.evaluate(@fnString)

    util.canvas.clear(ctx)

    {xMin, xMax, yMin, yMax} = @bounds
    util.canvas.drawCartesian ctx,
      xMin: xMin
      xMax: xMax
      yMin: yMin
      yMax: yMax
      fn: fn

    util.canvas.setStyle(ctx, @style)
    ctx.stroke()

  shouldComponentUpdate: (nextProps) ->
    return @bounds != nextProps.bounds or
      @fnString != nextProps.fnString or
      @style != nextProps.style

  render: ->
    R.CanvasView {drawFn: @drawFn, ref: "canvas"}