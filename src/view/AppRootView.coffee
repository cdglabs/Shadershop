R.create "AppRootView",
  propTypes:
    appRoot: C.AppRoot

  render: ->
    R.div {},
      R.div {className: "MainPlot"},
        R.div {className: "PlotContainer"},
          R.GridView {bounds: @appRoot.bounds}
          R.PlotCartesianView {
            bounds: @appRoot.bounds
            fnString: do =>
              exprStrings = @appRoot.sines.map (sine) =>
                sine.exprString()
              sumString = exprStrings.join(" + ")
              "(function (x) { return #{sumString}; })"
            style: {lineWidth: 1.5, strokeStyle: "#666"}
          }
          @appRoot.sines.map (sine) =>
            R.PlotSineView {sine}
          @appRoot.sines.map (sine) =>
            R.PlotSineControlsView {sine}

      R.div {className: "Sidebar"},
        @appRoot.sines.map (sine) =>
          R.SineView {sine}






R.create "SineView",
  propTypes:
    sine: C.Sine

  render: ->
    R.div {className: "Sine"},
      "Sine"
      R.div {},
        "Domain: + " + @sine.domainTranslate + ", * " + @sine.domainScale
      R.div {},
        "Range: + " + @sine.rangeTranslate + ", * " + @sine.rangeScale







R.create "PlotSineView",
  propTypes:
    sine: C.Sine

  render: ->
    bounds = @lookup("appRoot").bounds
    R.PlotCartesianView {
      bounds: bounds
      fnString: @sine.fnString()
      style: {lineWidth: 1.5, strokeStyle: "#00f"}
    }



R.create "PlotSineControlsView",
  propTypes:
    sine: C.Sine

  render: ->
    R.span {},
      R.PointControlView {
        x: @sine.domainTranslate
        y: @sine.rangeTranslate
        onChange: (x, y) =>
          @sine.domainTranslate = x
          @sine.rangeTranslate = y
      }
      R.PointControlView {
        x: @sine.domainTranslate + @sine.domainScale
        y: @sine.rangeTranslate  + @sine.rangeScale
        onChange: (x, y) =>
          @sine.domainScale = x - @sine.domainTranslate
          @sine.rangeScale  = y - @sine.rangeTranslate
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

        pixelWidth = (bounds.xMax - bounds.xMin) / rect.width
        digitPrecision = Math.floor(Math.log(pixelWidth) / Math.log(10))
        precision = Math.pow(10, digitPrecision)

        # x = util.floatToString(x, precision)
        # y = util.floatToString(y, precision)

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
