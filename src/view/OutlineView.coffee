R.create "OutlineView",
  propTypes:
    compoundFn: C.CompoundFn

  getNodes: ->
    # Return a list of {fn, indentLevel} for the outline display
    nodes = []
    recurse = (fn, indentLevel) ->
      nodes.push {fn, indentLevel}
      fn = fn.fn ? fn
      if fn instanceof C.CompoundFn
        for childFn in fn.childFns
          recurse(childFn, indentLevel + 1)
    recurse(@compoundFn, 0)
    return nodes

  render: ->
    R.div {className: "Outline"},
      R.table {className: "OutlineContainer"},
        @getNodes().map ({fn, indentLevel}) ->
          R.OutlineNodeView {fn, indentLevel}


# =============================================================================

R.create "OutlineNodeView",
  propTypes:
    fn: C.Fn
    indentLevel: Number

  render: ->
    className = R.cx {
      Selected: @fn == UI.selectedChildFn
    }
    R.tbody {className: className},
      R.tr {},
        R.td {className: "OutlineNodeMain", rowSpan: 2, style: {paddingLeft: @indentLevel * config.outlineIndent}},
          R.OutlineMainView {fn: @fn}
        R.td {},
          if @fn instanceof C.TransformedFn
            R.VariableView {variable: @fn.domainTranslate}
        R.td {},
          if @fn instanceof C.TransformedFn
            R.VariableView {variable: @fn.rangeTranslate}
      R.tr {},
        R.td {},
          if @fn instanceof C.TransformedFn
            R.VariableView {variable: @fn.domainScale}
        R.td {},
          if @fn instanceof C.TransformedFn
            R.VariableView {variable: @fn.rangeScale}


# =============================================================================

R.create "OutlineMainView",
  propTypes:
    fn: C.Fn

  render: ->
    fn = @fn.fn ? @fn
    R.div {},
      R.div {className: "DisclosureTriangle"}
      R.div {className: "OutlineMainContent"},
        R.LabelView {fn}
        if fn instanceof C.CompoundFn
          R.CombinerView {compoundFn: fn}


R.create "LabelView",
  propTypes:
    fn: C.Fn

  render: ->
    R.TextFieldView {
      className: "OutlineNodeLabel"
      value: @fn.label
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
