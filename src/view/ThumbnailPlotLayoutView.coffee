R.create "ThumbnailPlotLayoutView",
  propTypes:
    plotLayout: C.PlotLayout
    fn: C.Fn

  render: ->
    plot = @plotLayout.getMainPlot()

    R.div {className: "PlotContainer"},
      R.GridView {plot: plot, isThumbnail: true}

      R.ShaderCartesianView {
        plot: plot
        isThumbnail: true
        exprs: [
          {
            exprString: Compiler.getExprString(@fn, "inputVal")
            color: config.color.main
          }
        ]
      }
