R.create "ShaderCartesianView",
  propTypes:
    bounds: Object
    plots: Array # [{exprString, color}]

  render: ->
    R.div {className: "Shader"}
