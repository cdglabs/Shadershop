R.create "ThumbnailPlotView",
  propTypes:
    plot: C.Plot
    fn: C.Fn

  render: ->
    R.div {className: "PlotContainer"},
      R.GridView {plot: @plot}

      R.ShaderCartesianView {
        plot: @plot
        exprs: [
          {
            exprString: Compiler.getExprString(@fn, "x")
            color: config.color.main
          }
        ]
      }
