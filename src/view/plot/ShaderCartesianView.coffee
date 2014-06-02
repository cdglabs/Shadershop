R.create "ShaderCartesianView",
  propTypes:
    plot: C.Plot
    fns: Array # [{fn, color}]
    isThumbnail: Boolean

  render: ->
    R.div {className: "Shader"}
