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

      # Settings Button
      R.div {className: "SettingsButton Interactive", onClick: @_onSettingsButtonClick},
        R.div {className: "icon-cog"}

  _onSettingsButtonClick: ->
    # TODO This method of controlling plot layouts is getting even more hardcoded...
    plotLayout = @fn.plotLayout
    if plotLayout.display2d
      plotLayout.display2d = false
      plotLayout.plots[0].type = "cartesian"
    else
      plotLayout.display2d = true
      plotLayout.plots[0].type = "colorMap"
      plotLayout.plots[1].type = "cartesian"
      plotLayout.plots[2].type = "cartesian2"



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

    mask = @plot.getMask()
    outputMask = mask[config.dimensions ... ]

    inputVal  = point[ ... config.dimensions]
    outputVal = point[config.dimensions ... ]

    found = null
    foundError = maxQuadrance

    for childFn in @_getExpandedChildFns()
      evaluated = childFn.evaluate(inputVal)

      offset = numeric.sub(outputVal, evaluated)
      offset = numeric.mul(offset, outputMask) # We only care about the projected output.
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

      R.SliceControlsView {
        plot: @plot
      }

      if UI.selectedChildFns.length == 1
        R.ChildFnControlsView {
          childFn: UI.selectedChildFns[0]
          plot: @plot
        }

      # # Settings Button
      # R.div {className: "SettingsButton Interactive", onClick: @_onSettingsButtonClick},
      #   R.div {className: "icon-cog"}

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
      for transformInfo in @_getVisibleTransforms()
        R.PointControlView {
          position: @_getTransformPosition(transformInfo)
          onMove: @_setTransformPosition(transformInfo)
          key: transformInfo.space + transformInfo.basisVectorIndex
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
    translate = [].concat(
      @childFn.domainTranslate.map (v) -> v.getValue()
      @childFn.rangeTranslate.map (v) -> v.getValue()
    )
    return @plot.toPixel(translate)

  _setTranslatePosition: ({x, y}) ->
    translate = @plot.toWorld({x, y})

    for isRepresented, coord in @plot.getMask()
      if isRepresented
        value = translate[coord]
        valueString = @_snap(value)

        # This is hacky because childFn's data is stored the "old" way
        variable = if coord < translate.length/2
          @childFn.domainTranslate[coord]
        else
          @childFn.rangeTranslate[coord - translate.length/2]

        Actions.setVariableValueString(variable, valueString)


  _getVisibleTransforms: ->
    mask = @plot.getMask()
    visibleTransforms = []
    for space in ["domain", "range"]
      for basisVectorIndex in [0 ... config.dimensions]
        basisVector = @childFn.getBasisVector(space, basisVectorIndex)
        indexOffset = if space == "domain" then 0 else config.dimensions

        isVisible = _.all [0 ... config.dimensions], (coord) =>
          return true if mask[coord + indexOffset] == 1 # represented on the plot
          return true if basisVector[coord] == @plot.focus[coord + indexOffset] # "in" the projection
          return false

        if isVisible
          visibleTransforms.push {
            space
            basisVectorIndex
            basisVector
          }
    return visibleTransforms


  _getTransformPosition: (transformInfo) ->
    translate = [].concat(
      @childFn.domainTranslate.map (v) -> v.getValue()
      @childFn.rangeTranslate.map (v) -> v.getValue()
    )
    if transformInfo.space == "domain"
      transform = [].concat(
        transformInfo.basisVector
        util.constructVector(config.dimensions, 0)
      )
    else
      transform = [].concat(
        util.constructVector(config.dimensions, 0)
        transformInfo.basisVector
      )

    worldPosition = numeric.add(translate, transform)
    return @plot.toPixel(worldPosition)


  _setTransformPosition: (transformInfo) ->
    ({x, y}) =>
      translate = [].concat(
        @childFn.domainTranslate.map (v) -> v.getValue()
        @childFn.rangeTranslate.map (v) -> v.getValue()
      )

      point = @plot.toWorld({x, y})

      offset = numeric.sub(point, translate)

      if transformInfo.space == "domain"
        newBasisVector = offset[ ... config.dimensions]
        mask = @plot.getMask()[ ... config.dimensions]
      else
        newBasisVector = offset[config.dimensions ... ]
        mask = @plot.getMask()[config.dimensions ... ]

      newBasisVector = util.vectorMask(newBasisVector, transformInfo.basisVector, mask)

      valueStrings = newBasisVector.map (value) => @_snap(value)

      Actions.setBasisVector(@childFn, transformInfo.space, transformInfo.basisVectorIndex, valueStrings)





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



R.create "SliceControlsView",
  propTypes:
    plot: C.Plot

  render: ->
    R.div {className: "Interactive PointControlContainer"},
      for slice, index in @_getSlices()
        R.LineControlView {position: slice, onMove: @_onMove, key: index}

  _getSlices: ->
    slices = []

    pixelFocus = @plot.toPixel(@plot.focus)

    for dimension, dimensionIndex in @plot.getDimensions()
      for coord in [0 ... config.dimensions]
        if dimension[coord] == 1
          if dimensionIndex == 0 # x
            slices.push({x: pixelFocus.x})
          else if dimensionIndex == 1 # y
            slices.push({y: pixelFocus.y})
    return slices

  _onMove: (position) ->
    pixelFocus = @plot.toPixel(@plot.focus)
    pixelFocus = _.extend(pixelFocus, position)
    focus = @plot.toWorld(pixelFocus)

    plotLayout = @lookup("fn").plotLayout
    Actions.setPlotLayoutFocus(plotLayout, focus)




R.create "LineControlView",
  propTypes:
    position: Object # {x, y} in the Pixel frame
    onMove: Function

  render: ->
    R.div {
      className: "LineControl"
      onMouseDown: @_onMouseDown
      style: {
        left:   if @position.x? then  @position.x else "-50%"
        top:    if @position.y? then -@position.y else "-50%"
        width:  if @position.x? then "" else "100%"
        height: if @position.y? then "" else "100%"
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
        if @position.x?
          @onMove({x})
        else
          @onMove({y})
    }






