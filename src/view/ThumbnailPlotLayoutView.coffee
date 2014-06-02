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
        fns: [
          {
            fn: @fn
            color: config.color.main
          }
        ]
      }
