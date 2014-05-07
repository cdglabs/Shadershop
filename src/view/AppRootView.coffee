R.create "AppRootView",
  propTypes:
    appRoot: C.AppRoot

  refreshShaderOverlay: ->
    @refs.shaderOverlay.draw()

  componentDidMount: ->
    @refreshShaderOverlay()

  componentDidUpdate: ->
    @refreshShaderOverlay()

  render: ->
    R.div {},
      R.DefinitionsView {appRoot: @appRoot}
      R.MainPlotView {fn: UI.selectedFn}
      R.OutlineView {definedFn: UI.selectedFn}
      R.ShaderOverlayView {ref: "shaderOverlay"}
