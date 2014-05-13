R.create "ShaderCartesianView",
  propTypes:
    plot: C.Plot
    exprs: Array # [{exprString, color}]

  render: ->
    R.div {className: "Shader"}
