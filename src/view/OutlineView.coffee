R.create "OutlineView",
  propTypes:
    definition: C.Definition

  render: ->
    R.div {className: "Outline"},
      @definition.childReferences.map (childReference, index) =>
        R.ReferenceView {
          reference: childReference
          definition: @definition
          index: index
        }




R.create "ReferenceView",
  propTypes:
    reference: C.Reference
    definition: C.Definition
    index: Number

  handleMouseDown: ->
    UI.selectedChildReference = @reference

  remove: ->
    @definition.childReferences.splice(@index, 1)

  render: ->
    className = R.cx {
      Reference: true
      Selected: @reference == UI.selectedChildReference
    }
    R.div {className, onMouseDown: @handleMouseDown},
      R.div {className: "FnName"}, "Sine"
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

