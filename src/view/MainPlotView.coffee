R.create "MainPlotView",
  propTypes:
    fn: C.DefinedFn

  _getExpandedChildFns: ->
    result = []
    recurse = (childFns) ->
      for childFn in childFns
        continue unless childFn.visible
        result.push(childFn)
        if UI.isChildFnExpanded(childFn) and childFn.fn instanceof C.CompoundFn
          recurse(childFn.fn.childFns)
    recurse(@fn.childFns)
    return result

  _getLocalMouseCoords: ->
    rect = @getDOMNode().getBoundingClientRect()
    bounds = @fn.plot.getBounds(rect.width, rect.height)
    x = util.lerp(UI.mousePosition.x, rect.left, rect.right, bounds.xMin, bounds.xMax)
    y = util.lerp(UI.mousePosition.y, rect.bottom, rect.top, bounds.yMin, bounds.yMax)
    return {x, y}

  _findHitTarget: ->
    {x, y} = @_getLocalMouseCoords()

    rect = @getDOMNode().getBoundingClientRect()
    pixelSize = @fn.plot.getPixelSize(rect.width, rect.height)

    found = null
    foundDistance = config.hitTolerance * pixelSize

    for childFn in @_getExpandedChildFns()
      evaluated = childFn.evaluate([x, 0, 0, 0])

      distance = Math.abs(y - evaluated[0])
      if distance < foundDistance
        found = childFn
        foundDistance = distance

    return found

  render: ->
    exprs = []

    expandedChildFns = @_getExpandedChildFns()

    # Child Fns
    for childFn in expandedChildFns
      exprs.push {
        exprString: Compiler.getExprString(childFn, "x")
        color: config.color.child
      }

    # Hovered
    if UI.hoveredChildFn and _.contains(expandedChildFns, UI.hoveredChildFn)
      exprs.push {
        exprString: Compiler.getExprString(UI.hoveredChildFn, "x")
        color: config.color.hovered
      }

    # Main
    exprs.push {
      exprString: Compiler.getExprString(@fn, "x")
      color: config.color.main
    }

    # Selected
    if UI.selectedChildFn and _.contains(expandedChildFns, UI.selectedChildFn)
      exprs.push {
        exprString: Compiler.getExprString(UI.selectedChildFn, "x")
        color: config.color.selected
      }

    # Remove redundant exprs
    exprs = _.reject exprs, (expr, exprIndex) ->
      for i in [exprIndex+1 ... exprs.length]
        if exprs[i].exprString == expr.exprString
          return true
      return false

    R.div {
      className: "MainPlot",
      onMouseDown: @_onMouseDown,
      onWheel: @_onWheel,
      onMouseMove: @_onMouseMove,
      onMouseLeave: @_onMouseLeave
    },
      R.div {className: "PlotContainer"},
        # Grid
        R.GridView {plot: @fn.plot}

        R.ShaderCartesianView {
          plot: @fn.plot
          exprs: exprs
        }

        if UI.selectedChildFn
          R.ChildFnControlsView {
            childFn: UI.selectedChildFn
            plot: @fn.plot
          }

  _onMouseMove: ->
    Actions.hoverChildFn(@_findHitTarget())

  _onMouseLeave: ->
    Actions.hoverChildFn(null)

  _onMouseDown: (e) ->
    return if e.target.closest(".PointControl")
    util.preventDefault(e)

    @_startPan(e)

    util.onceDragConsummated e, null, =>
      @_changeSelection()

  _onWheel: (e) ->
    e.preventDefault()

    {x, y} = @_getLocalMouseCoords()

    zoomCenter = {
      domain: [x, null,null,null]
      range:  [y, null,null,null]
    }

    scaleFactor = 1.1
    scaleFactor = 1 / scaleFactor if e.deltaY < 0

    Actions.zoomPlot(@fn.plot, zoomCenter, scaleFactor)

  _changeSelection: ->
    Actions.selectChildFn(@_findHitTarget())

  _startPan: (e) ->
    {x, y} = @_getLocalMouseCoords()
    from = {
      domain: [x, null,null,null]
      range:  [y, null,null,null]
    }

    UI.dragging = {
      cursor: config.cursor.grabbing
      onMove: (e) =>
        {x, y} = @_getLocalMouseCoords()
        to = {
          domain: [x, null,null,null]
          range:  [y, null,null,null]
        }
        Actions.panPlot(@fn.plot, from, to)
    }




R.create "ChildFnControlsView",
  propTypes:
    childFn: C.ChildFn
    plot: C.Plot

  snap: (value) ->
    container = @getDOMNode().closest(".PlotContainer")
    rect = container.getBoundingClientRect()

    bounds = @plot.getBounds(rect.width, rect.height)
    pixelSize = @plot.getPixelSize(rect.width, rect.height)

    {largeSpacing, smallSpacing} = util.canvas.getSpacing({
      xMin: bounds.xMin
      xMax: bounds.xMax
      yMin: bounds.yMin
      yMax: bounds.yMax
      width: rect.width
      height: rect.height
    })

    snapTolerance = pixelSize * config.snapTolerance

    nearestSnap = Math.round(value / largeSpacing) * largeSpacing
    if Math.abs(value - nearestSnap) < snapTolerance
      value = nearestSnap
      digitPrecision = Math.floor(Math.log(largeSpacing) / Math.log(10))
      precision = Math.pow(10, digitPrecision)
      return util.floatToString(value, precision)

    digitPrecision = Math.floor(Math.log(pixelSize) / Math.log(10))
    precision = Math.pow(10, digitPrecision)

    return util.floatToString(value, precision)

  render: ->
    R.span {},
      R.PointControlView {
        x: @childFn.domainTranslate[0].getValue()
        y: @childFn.rangeTranslate[0].getValue()
        plot: @plot
        onMove: @_onTranslateChange
      }
      R.PointControlView {
        x: @childFn.domainTranslate[0].getValue() + @childFn.domainTransform[0][0].getValue()
        y: @childFn.rangeTranslate[0].getValue()  + @childFn.rangeTransform[0][0].getValue()
        plot: @plot
        onMove: @_onScaleChange
      }

  _onTranslateChange: (x, y) ->
    Actions.setVariableValueString(@childFn.domainTranslate[0], @snap(x))
    Actions.setVariableValueString(@childFn.rangeTranslate[0] , @snap(y))

  _onScaleChange: (x, y) ->
    Actions.setVariableValueString(@childFn.domainTransform[0][0], @snap(x - @childFn.domainTranslate[0].getValue()) )
    Actions.setVariableValueString(@childFn.rangeTransform[0][0] , @snap(y - @childFn.rangeTranslate[0].getValue())  )






R.create "PointControlView",
  propTypes:
    x: Number
    y: Number
    plot: C.Plot
    onMove: Function

  _refreshPosition: ->
    el = @getDOMNode()

    container = @getDOMNode().closest(".PlotContainer")
    rect = container.getBoundingClientRect()

    bounds = @plot.getBounds(rect.width, rect.height)

    el.style.left = util.lerp(@x, bounds.xMin, bounds.xMax, 0, rect.width)  + "px"
    el.style.top  = util.lerp(@y, bounds.yMin, bounds.yMax, rect.height, 0) + "px"

  render: ->
    R.div {className: "PointControl", onMouseDown: @_onMouseDown}

  componentDidMount: ->
    @_refreshPosition()

  componentDidUpdate: ->
    @_refreshPosition()

  _onMouseDown: (e) ->
    util.preventDefault(e)

    container = @getDOMNode().closest(".PlotContainer")
    rect = container.getBoundingClientRect()

    bounds = @plot.getBounds(rect.width, rect.height)

    UI.dragging = {
      onMove: (e) =>
        x = util.lerp(e.clientX, rect.left, rect.right, bounds.xMin, bounds.xMax)
        y = util.lerp(e.clientY, rect.bottom, rect.top, bounds.yMin, bounds.yMax)
        @onMove(x, y)
    }
