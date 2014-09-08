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
      R.PlotLayoutView {fn: UI.selectedFn}
      R.PaletteView {appRoot: @appRoot}
      R.OutlineView {definedFn: UI.selectedFn}
      R.InspectorView {}
      R.SymbolicView {}
      # R.DebugView {}
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


R.create "DebugView",
  render: ->
    R.div {
      style: {
        position: "absolute"
        bottom: 10
        left: 10
        zIndex: 99999
      }
    },
      R.button {onClick: reset}, "Reset"


key "ctrl+R", ->
  reset()
