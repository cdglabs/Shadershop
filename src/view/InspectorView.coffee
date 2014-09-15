R.create "InspectorView",
  render: ->
    R.div {className: "Inspector"},
      R.div {className: "Header"}, "Inspector"
      R.div {className: "Scroller"},
        if UI.selectedChildFns.length == 1
          R.InspectorTableView {fn: UI.selectedChildFns[0]}


R.create "InspectorTableView",
  propTypes:
    fn: C.ChildFn

  render: ->
    # HACK
    dimensions = if UI.selectedFn.plotLayout.display2d then 2 else 1

    R.table {},
      R.tbody {},

        R.tr {style: {color: config.domainLabelColor}},
          R.th {}
          for coordIndex in [0...dimensions]
            R.th {key: coordIndex}, "d"+(coordIndex+1)

        R.tr {className: "Translate"},
          R.td {className: "icon-move"}
          for coordIndex in [0...dimensions]
            variable = @fn.domainTranslate[coordIndex]
            R.td {key: C.id(variable)},
              R.VariableView {variable}

        for coordIndex in [0...dimensions]
          className = R.cx {
            "icon-resize-full-alt": coordIndex == 0
          }
          R.tr {key: coordIndex},
            R.td {className}
            for rowIndex in [0...dimensions]
              variable = @fn.domainTransform[rowIndex][coordIndex]
              R.td {key: C.id(variable)},
                R.VariableView {variable}

        R.tr {style: {color: config.rangeLabelColor}},
          R.th {}
          for coordIndex in [0...dimensions]
            R.th {key: coordIndex}, "r"+(coordIndex+1)

        R.tr {className: "Translate"},
          R.td {className: "icon-move"}
          for coordIndex in [0...dimensions]
            variable = @fn.rangeTranslate[coordIndex]
            R.td {key: C.id(variable)},
              R.VariableView {variable}

        for coordIndex in [0...dimensions]
          className = R.cx {
            "icon-resize-full-alt": coordIndex == 0
          }
          R.tr {key: coordIndex},
            R.td {className}
            for rowIndex in [0...dimensions]
              variable = @fn.rangeTransform[rowIndex][coordIndex]
              R.td {key: C.id(variable)},
                R.VariableView {variable}