R.create "AppRootView",
  propTypes:
    appRoot: C.AppRoot

  add: ->
    sine = new C.Sine()
    @appRoot.sines.push(sine)
    UI.selectedData = {sine}

  render: ->
    R.div {},
      R.MainPlotView {appRoot: @appRoot}
      R.div {className: "Sidebar"},
        @appRoot.sines.map (sine, index) =>
          R.SineView {
            sine
            array: @appRoot.sines
            index: index
          }
        R.div {className: "TextButton", onClick: @add}, "add"






R.create "SineView",
  propTypes:
    sine: C.Sine
    array: Array
    index: Number

  handleMouseDown: ->
    UI.selectedData = {
      sine: @sine
    }

  remove: ->
    @array.splice(@index, 1)

  render: ->
    className = R.cx {
      Curve: true
      Selected: @sine == UI.selectedData?.sine
    }
    R.div {className, onMouseDown: @handleMouseDown},
      R.div {className: "FnName"}, "Sine"
      R.div {},
        R.span {className: "TransformLabel"}, "+"
        R.VariableView {variable: @sine.domainTranslate}
        R.VariableView {variable: @sine.rangeTranslate}
      R.div {},
        R.span {className: "TransformLabel"}, "*"
        R.VariableView {variable: @sine.domainScale}
        R.VariableView {variable: @sine.rangeScale}
      R.div {className: "Extras"},
        R.div {className: "TextButton", onClick: @remove}, "remove"




R.create "VariableView",
  propTypes:
    variable: C.Variable

  handleInput: (newValue) ->
    @variable.valueString = newValue

  render: ->
    R.TextFieldView {
      className: "Variable"
      value: @variable.valueString
      onInput: @handleInput
    }




R.create "MainPlotView",
  propTypes:
    appRoot: C.AppRoot

  getLocalMouseCoords: ->
    bounds = @appRoot.bounds
    rect = @getDOMNode().getBoundingClientRect()
    x = util.lerp(UI.mousePosition.x, rect.left, rect.right, bounds.xMin, bounds.xMax)
    y = util.lerp(UI.mousePosition.y, rect.bottom, rect.top, bounds.yMin, bounds.yMax)
    return {x, y}

  changeSelection: ->
    {x, y} = @getLocalMouseCoords()

    rect = @getDOMNode().getBoundingClientRect()
    bounds = @appRoot.bounds
    pixelWidth = (bounds.xMax - bounds.xMin) / rect.width

    found = null
    for sine in @appRoot.sines
      fnString = sine.fnString()
      fn = util.evaluate(fnString)
      distance = Math.abs(y - fn(x))
      if distance < config.hitTolerance * pixelWidth
        found = {sine}

    UI.selectedData = found

  startPan: (e) ->
    originalX = e.clientX
    originalY = e.clientY
    originalBounds = {
      xMin: @appRoot.bounds.xMin
      xMax: @appRoot.bounds.xMax
      yMin: @appRoot.bounds.yMin
      yMax: @appRoot.bounds.yMax
    }

    rect = @getDOMNode().getBoundingClientRect()
    xScale = (originalBounds.xMax - originalBounds.xMin) / rect.width
    yScale = (originalBounds.yMax - originalBounds.yMin) / rect.height

    UI.dragging = {
      cursor: config.cursor.grabbing
      onMove: (e) =>
        dx = e.clientX - originalX
        dy = e.clientY - originalY
        @appRoot.bounds = {
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

    bounds = @appRoot.bounds

    scaleFactor = 1.2
    scale = if e.deltaY > 0 then scaleFactor else 1/scaleFactor

    @appRoot.bounds = {
      xMin: (bounds.xMin - x) * scale + x
      xMax: (bounds.xMax - x) * scale + x
      yMin: (bounds.yMin - y) * scale + y
      yMax: (bounds.yMax - y) * scale + y
    }


  render: ->
    R.div {className: "MainPlot", onMouseDown: @handleMouseDown, onWheel: @handleWheel},
      R.div {className: "PlotContainer"},
        # Grid
        R.GridView {bounds: @appRoot.bounds}

        # Sines
        @appRoot.sines.map (sine) =>
          R.PlotSineView {sine}

        # Sum
        R.PlotCartesianView {
          bounds: @appRoot.bounds
          fnString: do =>
            exprStrings = @appRoot.sines.map (sine) =>
              sine.exprString()
            sumString = exprStrings.join(" + ")
            "(function (x) { return #{sumString}; })"
          style: {lineWidth: 1.5, strokeStyle: "#666"}
        }

        if UI.selectedData?.sine
          R.PlotSineControlsView {sine: UI.selectedData.sine}



R.create "PlotSineView",
  propTypes:
    sine: C.Sine

  render: ->
    bounds = @lookup("appRoot").bounds

    if @sine == UI.selectedData?.sine
      style = config.style.selected
    else
      style = config.style.default

    R.PlotCartesianView {
      bounds: bounds
      fnString: @sine.fnString()
      style: style
    }



R.create "PlotSineControlsView",
  propTypes:
    sine: C.Sine

  snap: (value) ->
    container = @getDOMNode().closest(".PlotContainer")
    rect = container.getBoundingClientRect()

    bounds = @lookup("appRoot").bounds

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
    @sine.domainTranslate.valueString = @snap(x)
    @sine.rangeTranslate.valueString  = @snap(y)

  handleScaleChange: (x, y) ->
    @sine.domainScale.valueString = @snap(x - @sine.domainTranslate.getValue())
    @sine.rangeScale.valueString  = @snap(y - @sine.rangeTranslate.getValue())

  render: ->
    R.span {},
      R.PointControlView {
        x: @sine.domainTranslate.getValue()
        y: @sine.rangeTranslate.getValue()
        onChange: @handleTranslateChange
      }
      R.PointControlView {
        x: @sine.domainTranslate.getValue() + @sine.domainScale.getValue()
        y: @sine.rangeTranslate.getValue()  + @sine.rangeScale.getValue()
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
        bounds = @lookup("appRoot").bounds

        x = (e.clientX - rect.left) / rect.width
        y = (e.clientY - rect.top)  / rect.height

        x = util.lerp(x, 0, 1, bounds.xMin, bounds.xMax)
        y = util.lerp(y, 1, 0, bounds.yMin, bounds.yMax)

        @onChange(x, y)
    }


  style: ->
    bounds = @lookup("appRoot").bounds
    top  = util.lerp(@y, bounds.yMin, bounds.yMax, 100, 0) + "%"
    left = util.lerp(@x, bounds.xMin, bounds.xMax, 0, 100) + "%"
    return {top, left}

  render: ->
    R.div {
      className: "PointControl"
      style: @style()
      onMouseDown: @handleMouseDown
    }
