R.create "OutlineView",
  propTypes:
    compoundFn: C.CompoundFn

  render: ->
    R.div {className: "Outline"},
      R.CombinerView {compoundFn: @compoundFn}

      @compoundFn.childFns.map (childFn, index) =>
        R.TransformedFnView {
          transformedFn: childFn
          compoundFn: @compoundFn
          index: index
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



R.create "TransformedFnView",
  propTypes:
    transformedFn: C.TransformedFn
    compoundFn: C.CompoundFn
    index: Number

  handleMouseDown: ->
    UI.selectChildFn(@transformedFn)

  remove: ->
    UI.removeChildFn(@compoundFn, @index)

  render: ->
    className = R.cx {
      Reference: true
      Selected: @transformedFn == UI.selectedChildFn
    }
    R.div {className, onMouseDown: @handleMouseDown},
      R.div {className: "FnName"}, @transformedFn.fn.label
      R.div {},
        R.span {className: "TransformLabel"}, "+"
        R.VariableView {variable: @transformedFn.domainTranslate}
        R.VariableView {variable: @transformedFn.rangeTranslate}
      R.div {},
        R.span {className: "TransformLabel"}, "*"
        R.VariableView {variable: @transformedFn.domainScale}
        R.VariableView {variable: @transformedFn.rangeScale}
      R.div {className: "Extras"},
        R.div {className: "TextButton", onClick: @remove}, "remove"
