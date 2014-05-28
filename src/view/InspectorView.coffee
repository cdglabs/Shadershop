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
    R.table {},

      R.tr {},
        R.th {}
        for coordIndex in [0...config.dimensions]
          R.th {}, "d"+(coordIndex+1)

      R.tr {className: "Translate"},
        R.td {className: "icon-move"}
        @fn.domainTranslate.map (variable) =>
          R.td {key: C.id(variable)},
            R.VariableView {variable}

      for coordIndex in [0...config.dimensions]
        className = R.cx {
          "icon-resize-full-alt": coordIndex == 0
        }
        R.tr {key: coordIndex},
          R.td {className}
          for rowIndex in [0...config.dimensions]
            variable = @fn.domainTransform[rowIndex][coordIndex]
            R.td {key: C.id(variable)},
              R.VariableView {variable}

      R.tr {},
        R.th {}
        for coordIndex in [0...config.dimensions]
          R.th {}, "r"+(coordIndex+1)

      R.tr {className: "Translate"},
        R.td {className: "icon-move"}
        @fn.rangeTranslate.map (variable) =>
          R.td {key: C.id(variable)},
            R.VariableView {variable}

      for coordIndex in [0...config.dimensions]
        className = R.cx {
          "icon-resize-full-alt": coordIndex == 0
        }
        R.tr {key: coordIndex},
          R.td {className}
          for rowIndex in [0...config.dimensions]
            variable = @fn.rangeTransform[rowIndex][coordIndex]
            R.td {key: C.id(variable)},
              R.VariableView {variable}