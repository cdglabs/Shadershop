R.create "AppRootView",
  propTypes:
    appRoot: C.AppRoot

  render: ->
    R.div {},
      R.DefinitionsView {appRoot: @appRoot}
      R.MainPlotView {definition: UI.selectedDefinition}
      R.OutlineView {definition: UI.selectedDefinition}
