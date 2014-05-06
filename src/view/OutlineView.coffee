R.create "OutlineView",
  propTypes:
    compoundFn: C.CompoundFn

  render: ->
    nodeViews = []

    recurse = (fn, path) ->
      nodeView = R.OutlineNodeView {
        fn: fn
        path: path
        key: UI.getPathString(path)
      }
      nodeViews.push(nodeView)

      if UI.isPathExpanded(path)
        fn = fn.fn ? fn
        if fn instanceof C.CompoundFn
          for childFn in fn.childFns
            recurse(childFn, path.concat(childFn))

    recurse(@compoundFn, [])

    R.div {className: "Outline"},
      R.table {className: "OutlineContainer"},
        nodeViews
      if UI.selectedChildFn
        R.OutlineControlsView {fn: UI.selectedChildFn}


# =============================================================================

R.create "OutlineNodeView",
  propTypes:
    fn: C.Fn
    path: Array

  select: ->
    if @path.length == 1
      UI.selectChildFn(@fn)

  render: ->
    indentLevel = @path.length
    className = R.cx {
      Selected: @fn == UI.selectedChildFn
    }
    R.tbody {className: className, onMouseDown: @select},
      R.tr {},
        R.td {className: "OutlineNodeMain", rowSpan: 1, style: {paddingLeft: indentLevel * config.outlineIndent}},
          R.OutlineMainView {fn: @fn, path: @path}


# =============================================================================

R.create "OutlineMainView",
  propTypes:
    fn: C.Fn
    path: Array

  toggleExpanded: ->
    expanded = UI.isPathExpanded(@path)
    UI.setPathExpanded(@path, !expanded)

  render: ->
    fn = @fn.fn ? @fn
    expanded = UI.isPathExpanded(@path)

    disclosureClassName = R.cx {
      DisclosureTriangle: true
      Expanded: expanded
      Hidden: fn instanceof C.BuiltInFn
    }

    R.div {},
      R.div {className: disclosureClassName, onClick: @toggleExpanded}
      R.div {className: "OutlineMainContent"},
        R.LabelView {fn}
        if fn instanceof C.CompoundFn and expanded
          R.CombinerView {compoundFn: fn}


R.create "LabelView",
  propTypes:
    fn: C.Fn

  handleInput: (newValue) ->
    @fn.label = newValue

  render: ->
    R.TextFieldView {
      className: "OutlineNodeLabel"
      value: @fn.label
      onInput: @handleInput
    }


R.create "CombinerView",
  propTypes:
    compoundFn: C.CompoundFn

  handleChange: (e) ->
    value = e.target.selectedOptions[0].value
    @compoundFn.combiner = value

  render: ->
    R.div {},
      R.select {value: @compoundFn.combiner, onChange: @handleChange},
        R.option {value: "sum"}, "Add"
        R.option {value: "product"}, "Multiply"
        R.option {value: "composition"}, "Compose"

# =============================================================================

R.create "OutlineControlsView",
  propTypes:
    fn: C.ChildFn

  render: ->
    R.table {},
      R.tr {},
        @fn.domainTranslate.map (variable) =>
          R.td {},
            R.VariableView {variable}
        @fn.rangeTranslate.map (variable) =>
          R.td {},
            R.VariableView {variable}

      for coordIndex in [0...4]
        R.tr {},
          for rowIndex in [0...4]
            R.td {},
              R.VariableView {variable: @fn.domainTransform[rowIndex][coordIndex]}
          for rowIndex in [0...4]
            R.td {},
              R.VariableView {variable: @fn.rangeTransform[rowIndex][coordIndex]}
