R.create "MainPlotView",
  propTypes:
    fn: C.DefinedFn

  getLocalMouseCoords: ->
    bounds = @fn.bounds
    rect = @getDOMNode().getBoundingClientRect()
    x = util.lerp(UI.mousePosition.x, rect.left, rect.right, bounds.xMin, bounds.xMax)
    y = util.lerp(UI.mousePosition.y, rect.bottom, rect.top, bounds.yMin, bounds.yMax)
    return {x, y}

  findHitTarget: ->
    {x, y} = @getLocalMouseCoords()

    rect = @getDOMNode().getBoundingClientRect()
    bounds = @fn.bounds
    pixelWidth = (bounds.xMax - bounds.xMin) / rect.width

    found = null
    for childFn in @getExpandedChildFns()
      evaluated = childFn.evaluate([x, 0, 0, 0])

      distance = Math.abs(y - evaluated[0])
      if distance < config.hitTolerance * pixelWidth
        found = childFn

    return found

  changeSelection: ->
    UI.selectChildFn(@findHitTarget())

  handleMouseMove: ->
    UI.hoveredChildFn = @findHitTarget()

  handleMouseLeave: ->
    UI.hoveredChildFn = null

  startPan: (e) ->
    originalX = e.clientX
    originalY = e.clientY
    originalBounds = {
      xMin: @fn.bounds.xMin
      xMax: @fn.bounds.xMax
      yMin: @fn.bounds.yMin
      yMax: @fn.bounds.yMax
    }

    rect = @getDOMNode().getBoundingClientRect()
    xScale = (originalBounds.xMax - originalBounds.xMin) / rect.width
    yScale = (originalBounds.yMax - originalBounds.yMin) / rect.height

    UI.dragging = {
      cursor: config.cursor.grabbing
      onMove: (e) =>
        dx = e.clientX - originalX
        dy = e.clientY - originalY
        @fn.bounds = {
          xMin: originalBounds.xMin - dx * xScale
          xMax: originalBounds.xMax - dx * xScale
          yMin: originalBounds.yMin + dy * yScale
          yMax: originalBounds.yMax + dy * yScale
        }
    }

    util.onceDragConsummated e, null, =>
      @changeSelection()

  handleMouseDown: (e) ->
    return if e.target.closest(".PointControl")
    UI.preventDefault(e)
    @startPan(e)

  handleWheel: (e) ->
    e.preventDefault()

    {x, y} = @getLocalMouseCoords()

    bounds = @fn.bounds

    scaleFactor = 1.1
    scale = if e.deltaY > 0 then scaleFactor else 1/scaleFactor

    @fn.bounds = {
      xMin: (bounds.xMin - x) * scale + x
      xMax: (bounds.xMax - x) * scale + x
      yMin: (bounds.yMin - y) * scale + y
      yMax: (bounds.yMax - y) * scale + y
    }

  getExpandedChildFns: ->
    result = []
    recurse = (childFns) ->
      for childFn in childFns
        continue unless childFn.visible
        result.push(childFn)
        if UI.isChildFnExpanded(childFn) and childFn.fn instanceof C.CompoundFn
          recurse(childFn.fn.childFns)
    recurse(@fn.childFns)
    return result


  render: ->
    plots = []

    # Child Fns
    for childFn in @getExpandedChildFns()
      plots.push {
        exprString: childFn.getExprString("x")
        color: config.color.child
      }

    # Hovered
    if UI.hoveredChildFn
      plots.push {
        exprString: UI.hoveredChildFn.getExprString("x")
        color: config.color.hovered
      }

    # Main
    plots.push {
      exprString: @fn.getExprString("x")
      color: config.color.main
    }

    # Selected
    if UI.selectedChildFn
      plots.push {
        exprString: UI.selectedChildFn.getExprString("x")
        color: config.color.selected
      }

    # Remove redundant plots
    plots = _.reject plots, (plot, plotIndex) ->
      for i in [plotIndex+1 ... plots.length]
        if plots[i].exprString == plot.exprString
          return true
      return false

    R.div {
      className: "MainPlot",
      onMouseDown: @handleMouseDown,
      onWheel: @handleWheel,
      onMouseMove: @handleMouseMove,
      onMouseLeave: @handleMouseLeave
    },
      R.div {className: "PlotContainer"},
        # Grid
        R.GridView {bounds: @fn.bounds}

        R.ShaderCartesianView {
          bounds: @fn.bounds
          plots: plots
        }

        if UI.selectedChildFn
          R.ChildFnControlsView {
            childFn: UI.selectedChildFn
          }


R.create "ChildFnControlsView",
  propTypes:
    childFn: C.ChildFn

  snap: (value) ->
    container = @getDOMNode().closest(".PlotContainer")
    rect = container.getBoundingClientRect()

    bounds = @lookup("fn").bounds

    pixelWidth = (bounds.xMax - bounds.xMin) / rect.width

    {largeSpacing, smallSpacing} = util.canvas.getSpacing({
      xMin: bounds.xMin
      xMax: bounds.xMax
      yMin: bounds.yMin
      yMax: bounds.yMax
      width: rect.width
      height: rect.height
    })

    snapTolerance = pixelWidth * config.snapTolerance

    nearestSnap = Math.round(value / largeSpacing) * largeSpacing
    if Math.abs(value - nearestSnap) < snapTolerance
      value = nearestSnap
      digitPrecision = Math.floor(Math.log(largeSpacing) / Math.log(10))
      precision = Math.pow(10, digitPrecision)
      return util.floatToString(value, precision)

    digitPrecision = Math.floor(Math.log(pixelWidth) / Math.log(10))
    precision = Math.pow(10, digitPrecision)

    return util.floatToString(value, precision)

  handleTranslateChange: (x, y) ->
    @childFn.domainTranslate[0].valueString = @snap(x)
    @childFn.rangeTranslate[0].valueString  = @snap(y)

  handleScaleChange: (x, y) ->
    @childFn.domainTransform[0][0].valueString = @snap(x - @childFn.domainTranslate[0].getValue())
    @childFn.rangeTransform[0][0].valueString  = @snap(y - @childFn.rangeTranslate[0].getValue())

  render: ->
    R.span {},
      R.PointControlView {
        x: @childFn.domainTranslate[0].getValue()
        y: @childFn.rangeTranslate[0].getValue()
        onChange: @handleTranslateChange
      }
      R.PointControlView {
        x: @childFn.domainTranslate[0].getValue() + @childFn.domainTransform[0][0].getValue()
        y: @childFn.rangeTranslate[0].getValue()  + @childFn.rangeTransform[0][0].getValue()
        onChange: @handleScaleChange
      }




R.create "PointControlView",
  propTypes:
    x: Number
    y: Number
    onChange: Function

  getDefaultProps: -> {
    onChange: ->
  }

  handleMouseDown: (e) ->
    UI.preventDefault(e)

    container = @getDOMNode().closest(".PlotContainer")
    rect = container.getBoundingClientRect()

    UI.dragging = {
      onMove: (e) =>
        bounds = @lookup("fn").bounds

        x = (e.clientX - rect.left) / rect.width
        y = (e.clientY - rect.top)  / rect.height

        x = util.lerp(x, 0, 1, bounds.xMin, bounds.xMax)
        y = util.lerp(y, 1, 0, bounds.yMin, bounds.yMax)

        @onChange(x, y)
    }


  style: ->
    bounds = @lookup("fn").bounds
    top  = util.lerp(@y, bounds.yMin, bounds.yMax, 100, 0) + "%"
    left = util.lerp(@x, bounds.xMin, bounds.xMax, 0, 100) + "%"
    return {top, left}

  render: ->
    R.div {
      className: "PointControl"
      style: @style()
      onMouseDown: @handleMouseDown
    }
