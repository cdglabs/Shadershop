R.create "DefinitionsView",
  propTypes:
    appRoot: C.AppRoot

  addFn: ->
    UI.addFn(@appRoot)

  render: ->
    R.div {className: "Definitions"},

      builtIn.fns.map (fn) =>
        R.DefinitionView {fn}

      R.div {className: "Divider"}

      @appRoot.fns.map (fn) =>
        R.DefinitionView {fn}

      R.div {className: "AddDefinition"},
        R.button {className: "AddButton", onClick: @addFn}


defaultBounds = {
  xMin: -6
  xMax: 6
  yMin: -6
  yMax: 6
}

R.create "DefinitionView",
  propTypes:
    fn: C.Fn

  handleMouseDown: (e) ->
    UI.preventDefault(e)

    addChildFn = =>
      UI.addChildFn(@fn)

    selectFn = =>
      UI.selectFn(@fn)

    util.onceDragConsummated(e, addChildFn, selectFn)


  handleLabelInput: (newValue) ->
    @fn.label = newValue

  render: ->
    exprString = @fn.getExprString("x")
    fnString = "(function (x) { return #{exprString}; })"

    if @fn instanceof C.BuiltInFn
      bounds = defaultBounds
    else
      bounds = @fn.bounds

    className = R.cx {
      Definition: true
      Selected: UI.selectedFn == @fn
    }

    R.div {
      className: className
    },
      R.div {className: "PlotContainer", onMouseDown: @handleMouseDown},
        R.GridView {bounds}

        R.PlotCartesianView {
          bounds
          fnString
          style: config.style.main
        }

      if @fn instanceof C.BuiltInFn
        R.div {className: "Label"}, @fn.label
      else
        R.TextFieldView {
          className: "Label"
          value: @fn.label
          onInput: @handleLabelInput
        }

