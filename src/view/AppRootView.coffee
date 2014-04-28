R.create "AppRootView",
  propTypes:
    appRoot: C.AppRoot

  render: ->
    R.div {},
      R.DefinitionsView {appRoot: @appRoot}
      R.MainPlotView {fn: UI.selectedFn}
      R.OutlineView {compoundFn: UI.selectedFn}
