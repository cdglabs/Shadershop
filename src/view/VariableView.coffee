R.create "VariableView",
  propTypes:
    variable: C.Variable

  render: ->
    R.TextFieldView {
      className: "Variable"
      value: @variable.valueString
      onInput: @_onInput
    }

  _onInput: (newValue) ->
    Actions.setVariableValueString(@variable, newValue)
