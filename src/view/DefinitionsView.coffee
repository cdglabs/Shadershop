R.create "DefinitionsView",
  propTypes:
    appRoot: C.AppRoot

  render: ->
    R.div {className: "Definitions"},
      @appRoot.definitions.map (definition) =>
        R.DefinitionView {definition}


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
    childReference = new C.Reference()
    childReference.definition = @definition
    UI.selectedDefinition.childReferences.push(childReference)

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
