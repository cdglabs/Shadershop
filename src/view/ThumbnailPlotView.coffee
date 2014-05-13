R.create "ThumbnailPlotView",
  propTypes:
    bounds: Object
    fn: C.Fn

  render: ->
    R.div {className: "PlotContainer"},
      R.GridView {@bounds}

      R.ShaderCartesianView {
        bounds: @bounds
        plots: [
          {
            exprString: Compiler.getExprString(@fn, "x")
            color: config.color.main
          }
        ]
      }
