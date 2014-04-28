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
