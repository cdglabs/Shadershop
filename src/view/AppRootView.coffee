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
      R.DraggingView {}
      R.ShaderOverlayView {ref: "shaderOverlay"}


R.create "DraggingView",
  render: ->
    R.div {},
      if UI.dragging?.render
        R.div {
          className: "DraggingObject"
          style: {
            left: UI.mousePosition.x - UI.dragging.offset.x
            top:  UI.mousePosition.y - UI.dragging.offset.y
          }
        },
          UI.dragging.render()
      if UI.dragging
        R.div {className: "DraggingOverlay"}
