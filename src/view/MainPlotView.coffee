R.create "MainPlotView",
  propTypes:
    definition: C.Definition

  getLocalMouseCoords: ->
    bounds = @definition.bounds
    rect = @getDOMNode().getBoundingClientRect()
    x = util.lerp(UI.mousePosition.x, rect.left, rect.right, bounds.xMin, bounds.xMax)
    y = util.lerp(UI.mousePosition.y, rect.bottom, rect.top, bounds.yMin, bounds.yMax)
    return {x, y}

  changeSelection: ->
    {x, y} = @getLocalMouseCoords()

    rect = @getDOMNode().getBoundingClientRect()
    bounds = @definition.bounds
    pixelWidth = (bounds.xMax - bounds.xMin) / rect.width

    found = null
    for childReference in @definition.childReferences
      exprString = childReference.getExprString("x")
      fnString = "(function (x) { return #{exprString}; })"

      fn = util.evaluate(fnString)

      distance = Math.abs(y - fn(x))
      if distance < config.hitTolerance * pixelWidth
        found = childReference

    UI.selectChildReference(found)

  startPan: (e) ->
    originalX = e.clientX
    originalY = e.clientY
    originalBounds = {
      xMin: @definition.bounds.xMin
      xMax: @definition.bounds.xMax
      yMin: @definition.bounds.yMin
      yMax: @definition.bounds.yMax
    }

    rect = @getDOMNode().getBoundingClientRect()
    xScale = (originalBounds.xMax - originalBounds.xMin) / rect.width
    yScale = (originalBounds.yMax - originalBounds.yMin) / rect.height

    UI.dragging = {
      cursor: config.cursor.grabbing
      onMove: (e) =>
        dx = e.clientX - originalX
        dy = e.clientY - originalY
        @definition.bounds = {
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

    bounds = @definition.bounds

    scaleFactor = 1.1
    scale = if e.deltaY > 0 then scaleFactor else 1/scaleFactor

    @definition.bounds = {
      xMin: (bounds.xMin - x) * scale + x
      xMax: (bounds.xMax - x) * scale + x
      yMin: (bounds.yMin - y) * scale + y
      yMax: (bounds.yMax - y) * scale + y
    }


  renderPlot: (curve, style) ->
    exprString = curve.getExprString("x")
    fnString = "(function (x) { return #{exprString}; })"
    return R.PlotCartesianView {
      bounds: @definition.bounds
      fnString
      style
    }


  render: ->
    R.div {className: "MainPlot", onMouseDown: @handleMouseDown, onWheel: @handleWheel},
      R.div {className: "PlotContainer"},
        # Grid
        R.GridView {bounds: @definition.bounds}

        # Child References
        @definition.childReferences.map (childReference) =>
          @renderPlot(childReference, config.style.default)

        # Main
        @renderPlot(@definition, config.style.main)

        if UI.selectedChildReference
          @renderPlot(UI.selectedChildReference, config.style.selected)

        if UI.selectedChildReference
          R.ReferenceControlsView {
            definition: @definition
            reference: UI.selectedChildReference
          }


R.create "ReferenceControlsView",
  propTypes:
    reference: C.Reference
    definition: C.Definition

  snap: (value) ->
    container = @getDOMNode().closest(".PlotContainer")
    rect = container.getBoundingClientRect()

    bounds = @definition.bounds

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
    @reference.domainTranslate.valueString = @snap(x)
    @reference.rangeTranslate.valueString  = @snap(y)

  handleScaleChange: (x, y) ->
    @reference.domainScale.valueString = @snap(x - @reference.domainTranslate.getValue())
    @reference.rangeScale.valueString  = @snap(y - @reference.rangeTranslate.getValue())

  render: ->
    R.span {},
      R.PointControlView {
        x: @reference.domainTranslate.getValue()
        y: @reference.rangeTranslate.getValue()
        onChange: @handleTranslateChange
      }
      R.PointControlView {
        x: @reference.domainTranslate.getValue() + @reference.domainScale.getValue()
        y: @reference.rangeTranslate.getValue()  + @reference.rangeScale.getValue()
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
        bounds = @lookup("definition").bounds

        x = (e.clientX - rect.left) / rect.width
        y = (e.clientY - rect.top)  / rect.height

        x = util.lerp(x, 0, 1, bounds.xMin, bounds.xMax)
        y = util.lerp(y, 1, 0, bounds.yMin, bounds.yMax)

        @onChange(x, y)
    }


  style: ->
    bounds = @lookup("definition").bounds
    top  = util.lerp(@y, bounds.yMin, bounds.yMax, 100, 0) + "%"
    left = util.lerp(@x, bounds.xMin, bounds.xMax, 0, 100) + "%"
    return {top, left}

  render: ->
    R.div {
      className: "PointControl"
      style: @style()
      onMouseDown: @handleMouseDown
    }
