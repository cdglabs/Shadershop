R.create "OutlineView",
  propTypes:
    definedFn: C.DefinedFn

  addCompoundFn: ->
    fn = new C.CompoundFn()
    UI.addChildFn(fn)

  render: ->
    R.div {className: "Outline"},
      R.OutlineChildrenView {
        compoundFn: @definedFn
        path: []
      }

      R.div {className: "TextButton", onClick: @addCompoundFn}, "Add"

      if UI.selectedChildFn
        R.OutlineControlsView {fn: UI.selectedChildFn}


# =============================================================================

R.create "OutlineChildrenView",
  propTypes:
    compoundFn: C.CompoundFn
    path: Array

  render: ->
    R.div {className: "OutlineChildren"},
      for childFn in @compoundFn.childFns
        R.OutlineItemView {
          childFn: childFn
          path: @path.concat(childFn)
        }


# =============================================================================

R.create "OutlineItemView",
  propTypes:
    childFn: C.ChildFn
    path: Array

  toggleExpanded: ->
    expanded = UI.isPathExpanded(@path)
    UI.setPathExpanded(@path, !expanded)

  render: ->
    canHaveChildren = @childFn.fn instanceof C.CompoundFn
    expanded = UI.isPathExpanded(@path)
    selected = (@childFn == UI.selectedChildFn)

    className = R.cx {
      OutlineItem: true
      Selected: selected
    }

    disclosureClassName = R.cx {
      DisclosureTriangle: true
      Expanded: expanded
      Hidden: !canHaveChildren
    }

    R.div {className: className},
      R.div {},
        R.div {className: disclosureClassName, onClick: @toggleExpanded}
        R.OutlineInternalsView {fn: @childFn.fn}

      if canHaveChildren and expanded
        R.OutlineChildrenView {
          compoundFn: @childFn.fn
          path: @path
        }


# =============================================================================

R.create "OutlineInternalsView",
  propTypes:
    fn: C.Fn

  render: ->
    R.div {className: "OutlineInternals"},
      if @fn instanceof C.BuiltInFn
        R.LabelView {fn: @fn} # TODO but not editable

      else if @fn instanceof C.DefinedFn
        R.LabelView {fn: @fn}

      else if @fn instanceof C.CompoundFn
        R.CombinerView {compoundFn: @fn}


# =============================================================================

R.create "LabelView",
  propTypes:
    fn: C.Fn

  handleInput: (newValue) ->
    @fn.label = newValue

  render: ->
    R.TextFieldView {
      className: "OutlineLabel"
      value: @fn.label
      onInput: @handleInput
    }


# =============================================================================

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
