R.create "PaletteView",
  propTypes:
    appRoot: C.AppRoot

  render: ->
    R.div {className: "Palette"},

      R.div {className: "DragHint"}, "Drag →"

      R.div {className: "Header"},
        "Library"

      R.div {className: "Scroller"},

        R.div {className: "PaletteHeader"}, "Built In Functions"

        builtIn.fns.map (fn) =>
          R.DefinitionView {fn, key: C.id(fn)}

        R.div {className: "PaletteHeader"}, "Custom Functions"

        @appRoot.fns.map (fn) =>
          R.DefinitionView {fn, key: C.id(fn)}

        R.div {className: "AddDefinition"},
          R.button {className: "AddButton", onClick: @_onAddButtonClick}

  _onAddButtonClick: ->
    Actions.addDefinedFn()


R.create "DefinitionView",
  propTypes:
    fn: C.Fn

  render: ->
    if @fn instanceof C.BuiltInFn
      plotLayout = builtIn.defaultPlotLayout
    else
      plotLayout = @fn.plotLayout

    className = R.cx {
      Definition: true
      Selected: UI.selectedFn == @fn
    }

    R.div {
      className: className
      onMouseDown: @_onMouseDown
    },
      R.ThumbnailPlotLayoutView {plotLayout, fn: @fn}
      R.LabelView {
        fn: @fn
      }

  _onMouseDown: (e) ->
    return if e.target.matches(".Interactive")
    util.preventDefault(e)

    x = e.clientX
    y = e.clientY

    addChildFn = =>
      Actions.addChildFn(@fn)

    selectFn = =>
      if @fn instanceof C.BuiltInFn
        @_showDragHint(x, y)
      else
        Actions.selectFn(@fn)

    util.onceDragConsummated(e, addChildFn, selectFn)

  _showDragHint: (x, y) ->
    el = document.querySelector(".DragHint")
    el.style.left = x + "px"
    el.style.top = y + "px"
    el.style.opacity = "1"
    setTimeout (-> el.style.opacity = "0"), 1600



