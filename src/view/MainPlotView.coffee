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

  _getWorldMouseCoords: ->
    rect = @getDOMNode().getBoundingClientRect()
    x = UI.mousePosition.x - rect.left
    y = UI.mousePosition.y - rect.top
    return @fn.plot.toWorld(rect.width, rect.height, {x, y})

  _findHitTarget: ->
    {domain, range} = @_getWorldMouseCoords()

    rect = @getDOMNode().getBoundingClientRect()
    pixelSize = @fn.plot.getPixelSize(rect.width, rect.height)

    # TODO 0 here should be replaced based on where the projection is.
    testPoint = util.constructVector(config.dimensions, 0)
    testPoint = util.vector.merge(testPoint, domain)

    found = null
    foundDistance = config.hitTolerance * pixelSize
    foundQuadrance = foundDistance * foundDistance

    for childFn in @_getExpandedChildFns()
      evaluated = childFn.evaluate(testPoint)

      offset = util.vector.sub(range, evaluated)
      quadrance = util.vector.quadrance(offset)

      if quadrance < foundQuadrance
        found = childFn
        foundQuadrance = quadrance

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

    return if Math.abs(e.deltaY) <= 1
    scaleFactor = 1.1
    scaleFactor = 1 / scaleFactor if e.deltaY < 0

    zoomCenter = @_getWorldMouseCoords()

    Actions.zoomPlot(@fn.plot, zoomCenter, scaleFactor)

  _changeSelection: ->
    Actions.selectChildFn(@_findHitTarget())

  _startPan: (e) ->
    from = @_getWorldMouseCoords()

    UI.dragging = {
      cursor: config.cursor.grabbing
      onMove: (e) =>
        to = @_getWorldMouseCoords()
        Actions.panPlot(@fn.plot, from, to)
    }























R.create "ChildFnControlsView",
  propTypes:
    childFn: C.ChildFn
    plot: C.Plot

  render: ->
    R.span {},
      R.PointControlView {
        position: @_getTranslatePosition
        onMove: @_setTranslatePosition
      }
      for dimension in @plot.getDimensions()
        R.PointControlView {
          position: @_getTransformPosition(dimension)
          onMove: @_setTransformPosition(dimension)
        }

  _toPixel: (world) ->
    container = @getDOMNode().closest(".PlotContainer")
    rect = container.getBoundingClientRect()
    return @plot.toPixel(rect.width, rect.height, world)

  _toWorld: (pixel) ->
    container = @getDOMNode().closest(".PlotContainer")
    rect = container.getBoundingClientRect()
    return @plot.toWorld(rect.width, rect.height, pixel)

  _snap: (value) ->
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


  _getTranslatePosition: ->
    translate = {
      domain: @childFn.domainTranslate.map (v) -> v.getValue()
      range:  @childFn.rangeTranslate.map (v) -> v.getValue()
    }
    return @_toPixel(translate)

  _setTranslatePosition: ({x, y}) ->
    translate = @_toWorld({x, y})

    for value, coord in translate.domain
      if value?
        valueString = @_snap(value, .01)
        Actions.setVariableValueString(@childFn.domainTranslate[coord], valueString)
    for value, coord in translate.range
      if value?
        valueString = @_snap(value, .01)
        Actions.setVariableValueString(@childFn.rangeTranslate[coord], valueString)

  _getTransformPosition: (dimension) ->
    =>
      translate = {
        domain: @childFn.domainTranslate.map (v) -> v.getValue()
        range:  @childFn.rangeTranslate.map (v) -> v.getValue()
      }

      basisVector = @childFn.getBasisVector(dimension.space, dimension.coord)

      if dimension.space == "domain"
        point = {
          domain: util.vector.add(translate.domain, basisVector)
          range: translate.range
        }
      else if dimension.space == "range"
        point = {
          domain: translate.domain
          range: util.vector.add(translate.range, basisVector)
        }
      return @_toPixel(point)

  _setTransformPosition: (dimension) ->
    ({x, y}) =>
      translate = {
        domain: @childFn.domainTranslate.map (v) -> v.getValue()
        range:  @childFn.rangeTranslate.map (v) -> v.getValue()
      }
      point = @_toWorld({x, y})

      movedBasisVector = util.vector.sub(point[dimension.space], translate[dimension.space])

      oldBasisVector = @childFn.getBasisVector(dimension.space, dimension.coord)
      newBasisVector = util.vector.merge(oldBasisVector, movedBasisVector)

      valueStrings = newBasisVector.map (value) => @_snap(value)

      Actions.setBasisVector(@childFn, dimension.space, dimension.coord, valueStrings)






R.create "PointControlView",
  propTypes:
    position: Function
    onMove: Function

  _refreshPosition: ->
    el = @getDOMNode()

    {x, y} = @position()
    el.style.left = x + "px"
    el.style.top  = y + "px"

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

    UI.dragging = {
      onMove: (e) =>
        x = e.clientX - rect.left
        y = e.clientY - rect.top
        @onMove({x, y})
    }





