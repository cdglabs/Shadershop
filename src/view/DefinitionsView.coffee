R.create "DefinitionsView",
  propTypes:
    appRoot: C.AppRoot

  addDefinition: ->
    UI.addDefinition(@appRoot)

  render: ->
    R.div {className: "Definitions"},

      builtIn.definitions.map (definition) =>
        R.DefinitionView {definition}

      R.div {className: "Divider"}

      @appRoot.definitions.map (definition) =>
        R.DefinitionView {definition}

      R.div {className: "AddDefinition"},
        R.button {className: "AddButton", onClick: @addDefinition}


defaultBounds = {
  xMin: -6
  xMax: 6
  yMin: -6
  yMax: 6
}

R.create "DefinitionView",
  propTypes:
    definition: C.Definition

  handleMouseDown: (e) ->
    UI.preventDefault(e)

    addChildReference = =>
      UI.addChildReference(@definition)

    selectDefinition = =>
      UI.selectDefinition(@definition)

    util.onceDragConsummated(e, addChildReference, selectDefinition)


  render: ->
    exprString = @definition.getExprString("x")
    fnString = "(function (x) { return #{exprString}; })"

    if @definition instanceof C.BuiltInDefinition
      bounds = defaultBounds
    else
      bounds = @definition.bounds

    className = R.cx {
      Definition: true
      Selected: UI.selectedDefinition == @definition
    }

    R.div {
      className: className
      onMouseDown: @handleMouseDown
    },
      R.div {className: "PlotContainer"},
        R.GridView {bounds}

        R.PlotCartesianView {
          bounds
          fnString
          style: config.style.main
        }
