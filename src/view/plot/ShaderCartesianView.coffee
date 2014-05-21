R.create "ShaderCartesianView",
  propTypes:
    plot: C.Plot
    exprs: Array # [{exprString, color}]
    isThumbnail: Boolean

  render: ->
    R.div {className: "Shader"}
