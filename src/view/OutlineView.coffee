R.create "OutlineView",
  propTypes:
    definition: C.Definition

  render: ->
    R.div {className: "Outline"},
      R.CombinerView {definition: @definition}

      @definition.childReferences.map (childReference, index) =>
        R.ReferenceView {
          reference: childReference
          definition: @definition
          index: index
        }



R.create "CombinerView",
  propTypes:
    definition: C.Definition

  handleChange: (e) ->
    value = e.target.selectedOptions[0].value
    @definition.combiner = value

  render: ->
    R.div {},
      R.select {value: @definition.combiner, onChange: @handleChange},
        R.option {value: "sum"}, "Add"
        R.option {value: "product"}, "Multiply"
        R.option {value: "composition"}, "Compose"



R.create "ReferenceView",
  propTypes:
    reference: C.Reference
    definition: C.Definition
    index: Number

  handleMouseDown: ->
    UI.selectChildReference(@reference)

  remove: ->
    UI.removeChildReference(@definition, @index)

  render: ->
    className = R.cx {
      Reference: true
      Selected: @reference == UI.selectedChildReference
    }
    R.div {className, onMouseDown: @handleMouseDown},
      R.div {className: "FnName"}, @reference.definition.label
      R.div {},
        R.span {className: "TransformLabel"}, "+"
        R.VariableView {variable: @reference.domainTranslate}
        R.VariableView {variable: @reference.rangeTranslate}
      R.div {},
        R.span {className: "TransformLabel"}, "*"
        R.VariableView {variable: @reference.domainScale}
        R.VariableView {variable: @reference.rangeScale}
      R.div {className: "Extras"},
        R.div {className: "TextButton", onClick: @remove}, "remove"




R.create "VariableView",
  propTypes:
    variable: C.Variable

  handleInput: (newValue) ->
    @variable.valueString = newValue

  render: ->
    R.TextFieldView {
      className: "Variable"
      value: @variable.valueString
      onInput: @handleInput
    }

