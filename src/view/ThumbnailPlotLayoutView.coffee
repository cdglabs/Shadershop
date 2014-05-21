R.create "ThumbnailPlotLayoutView",
  propTypes:
    plotLayout: C.PlotLayout
    fn: C.Fn

  render: ->
    plot = @plotLayout.getMainPlot()

    R.div {className: "PlotContainer"},
      R.GridView {plot: plot}

      R.ShaderCartesianView {
        plot: plot
        exprs: [
          {
            exprString: Compiler.getExprString(@fn, "x")
            color: config.color.main
          }
        ]
      }
