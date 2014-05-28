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
        for coordIndex in [0...config.dimensions]
          R.th {}, "d"+(coordIndex+1)

      R.tr {},
        @fn.domainTranslate.map (variable) =>
          R.td {key: C.id(variable)},
            R.VariableView {variable}

      for coordIndex in [0...config.dimensions]
        R.tr {key: coordIndex},
          for rowIndex in [0...config.dimensions]
            variable = @fn.domainTransform[rowIndex][coordIndex]
            R.td {key: C.id(variable)},
              R.VariableView {variable}

      R.tr {},
        for coordIndex in [0...config.dimensions]
          R.th {}, "r"+(coordIndex+1)

      R.tr {},
        @fn.rangeTranslate.map (variable) =>
          R.td {key: C.id(variable)},
            R.VariableView {variable}

      for coordIndex in [0...config.dimensions]
        R.tr {key: coordIndex},
          for rowIndex in [0...config.dimensions]
            variable = @fn.rangeTransform[rowIndex][coordIndex]
            R.td {key: C.id(variable)},
              R.VariableView {variable}