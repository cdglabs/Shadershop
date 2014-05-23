R.create "PlotLayoutView",
  propTypes:
    fn: C.DefinedFn

  render: ->
    plotLocations = @fn.plotLayout.getPlotLocations()

    R.div {className: "PlotLayout"},
      for {plot, x, y, w, h}, index in plotLocations
        R.div {
          className: "PlotLocation"
          style: {
            left:   x * 100 + "%"
            top:    y * 100 + "%"
            width:  w * 100 + "%"
            height: h * 100 + "%"
          }
          key: index
        },
          R.PlotView {
            fn: @fn
            plot: plot
          }



R.create "PlotView",
  propTypes:
    fn: C.DefinedFn
    plot: C.Plot

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
    x = UI.mousePosition.x - (rect.left + rect.width/2)
    y = UI.mousePosition.y - (rect.top + rect.height/2)
    y *= -1
    return @plot.toWorld({x, y})

  _findHitTarget: ->
    pixelSize = @plot.getPixelSize()
    maxDistance = config.hitTolerance * pixelSize
    maxQuadrance = maxDistance * maxDistance

    point = @_getWorldMouseCoords()

    inputVal  = point[ ... point.length/2]
    outputVal = point[point.length/2 ... ]

    found = null
    foundError = maxQuadrance

    for childFn in @_getExpandedChildFns()
      evaluated = childFn.evaluate(inputVal)

      offset = numeric.sub(outputVal, evaluated)
      error = numeric.norm2Squared(offset)

      if error < foundError
        found = childFn
        foundError = error

    return found


  render: ->
    exprs = []

    if @plot.type == "colorMap"

      # Main
      exprs.push {
        exprString: Compiler.getExprString(@fn, "x")
      }

    else

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
      for childFn in UI.selectedChildFns
        exprs.push {
          exprString: Compiler.getExprString(childFn, "x")
          color: config.color.selected
        }

      # Remove redundant exprs
      exprs = _.reject exprs, (expr, exprIndex) ->
        for i in [exprIndex+1 ... exprs.length]
          if exprs[i].exprString == expr.exprString
            return true
        return false

    R.div {
      className: "PlotContainer",
      onMouseDown: @_onMouseDown,
      onWheel: @_onWheel,
      onMouseMove: @_onMouseMove,
      onMouseLeave: @_onMouseLeave
    },
      # Grid
      R.GridView {plot: @plot, isThumbnail: false}

      R.ShaderCartesianView {
        plot: @plot
        exprs: exprs
        isThumbnail: false
      }

      # if UI.selectedChildFns.length == 1
      #   R.ChildFnControlsView {
      #     childFn: UI.selectedChildFns[0]
      #     plot: @plot
      #   }

      # Settings Button
      R.div {className: "SettingsButton Interactive", onClick: @_onSettingsButtonClick},
        R.div {className: "icon-cog"}

  _onMouseMove: ->
    Actions.hoverChildFn(@_findHitTarget())

  _onMouseLeave: ->
    Actions.hoverChildFn(null)

  _onMouseDown: (e) ->
    return if e.target.closest(".Interactive")
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

    plotLayout = @fn.plotLayout
    Actions.zoomPlotLayout(plotLayout, zoomCenter, scaleFactor)

  _changeSelection: ->
    childFn = @_findHitTarget()
    if key.command or key.shift
      if childFn?
        Actions.toggleSelectChildFn(childFn)
    else
      Actions.selectChildFn(childFn)

  _startPan: (e) ->
    from = @_getWorldMouseCoords()

    UI.dragging = {
      cursor: config.cursor.grabbing
      onMove: (e) =>
        to = @_getWorldMouseCoords()

        plotLayout = @fn.plotLayout
        Actions.panPlotLayout(plotLayout, from, to)
    }

  _onSettingsButtonClick: ->
    # TODO: will be more than just a toggle...
    if @plot.type == "cartesian"
      @plot.type = "colorMap"
    else
      @plot.type = "cartesian"






















R.create "ChildFnControlsView",
  propTypes:
    childFn: C.ChildFn
    plot: C.Plot

  render: ->
    R.div {className: "Interactive PointControlContainer"},
      R.PointControlView {
        position: @_getTranslatePosition()
        onMove: @_setTranslatePosition
      }
      for dimension, index in @plot.getDimensions()
        R.PointControlView {
          position: @_getTransformPosition(dimension)
          onMove: @_setTransformPosition(dimension)
          key: index
        }

  _snap: (value) ->
    pixelSize = @plot.getPixelSize()

    {largeSpacing, smallSpacing} = util.canvas.getSpacing(pixelSize)

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
    return @plot.toPixel(translate)

  _setTranslatePosition: ({x, y}) ->
    translate = @plot.toWorld({x, y})

    for value, coord in translate.domain
      if value?
        valueString = @_snap(value, .01)
        Actions.setVariableValueString(@childFn.domainTranslate[coord], valueString)
    for value, coord in translate.range
      if value?
        valueString = @_snap(value, .01)
        Actions.setVariableValueString(@childFn.rangeTranslate[coord], valueString)

  _getTransformPosition: (dimension) ->
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
    return @plot.toPixel(point)

  _setTransformPosition: (dimension) ->
    ({x, y}) =>
      translate = {
        domain: @childFn.domainTranslate.map (v) -> v.getValue()
        range:  @childFn.rangeTranslate.map (v) -> v.getValue()
      }
      point = @plot.toWorld({x, y})

      movedBasisVector = util.vector.sub(point[dimension.space], translate[dimension.space])

      oldBasisVector = @childFn.getBasisVector(dimension.space, dimension.coord)
      newBasisVector = util.vector.merge(oldBasisVector, movedBasisVector)

      valueStrings = newBasisVector.map (value) => @_snap(value)

      Actions.setBasisVector(@childFn, dimension.space, dimension.coord, valueStrings)






R.create "PointControlView",
  propTypes:
    position: Object # {x, y} in the Pixel frame
    onMove: Function

  render: ->
    R.div {
      className: "PointControl",
      onMouseDown: @_onMouseDown
      style: {
        left: @position.x
        top: -@position.y
      }
    }

  _onMouseDown: (e) ->
    util.preventDefault(e)

    container = @getDOMNode().closest(".PointControlContainer")
    rect = container.getBoundingClientRect()

    UI.dragging = {
      onMove: (e) =>
        x = e.clientX - rect.left
        y = e.clientY - rect.top
        y *= -1
        @onMove({x, y})
    }





