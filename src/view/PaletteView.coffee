R.create "PaletteView",
  propTypes:
    appRoot: C.AppRoot

  render: ->
    R.div {className: "Palette"},

      R.div {className: "Header"},
        "Functions"

      R.div {className: "Scroller"},

        builtIn.fns.map (fn) =>
          R.DefinitionView {fn, key: C.id(fn)}

        R.div {className: "Divider"}

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
      plot = builtIn.defaultPlot
    else
      plot = @fn.plot

    className = R.cx {
      Definition: true
      Selected: UI.selectedFn == @fn
    }

    R.div {
      className: className
    },
      R.span {onMouseDown: @_onMouseDown},
        R.ThumbnailPlotView {plot, fn: @fn}

      R.LabelView {
        fn: @fn
      }

  _onMouseDown: (e) ->
    util.preventDefault(e)

    addChildFn = =>
      Actions.addChildFn(@fn)

    selectFn = =>
      Actions.selectFn(@fn)

    util.onceDragConsummated(e, addChildFn, selectFn)

