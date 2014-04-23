R.create "TextFieldView",
  propTypes: {
    value: String
    className: String
    onInput: Function
    onBackSpace: Function
    onFocus: Function
    onBlur: Function
    allowEnter: Boolean
  }
  getDefaultProps: ->
    {
      value: ""
      className: ""
      onInput: (newValue) ->
      onBackSpace: ->
      onEnter: ->
      onFocus: ->
      onBlur: ->
      allowEnter: false
    }

  shouldComponentUpdate: (nextProps) ->
    return @_isDirty or nextProps.value != @props.value

  refresh: ->
    el = @getDOMNode()
    if el.textContent != @value
      el.textContent = @value
    @_isDirty = false

    UI.attemptAutoFocus(this)

  componentDidMount: -> @refresh()
  componentDidUpdate: -> @refresh()

  handleInput: ->
    @_isDirty = true
    el = @getDOMNode()
    newValue = el.textContent
    @onInput(newValue)

  handleKeyDown: (e) ->
    host = util.selection.getHost()
    if e.keyCode == 37 # left
      if util.selection.isAtStart()
        previousHost = findAdjacentHost(host, -1)
        if previousHost
          e.preventDefault()
          util.selection.setAtEnd(previousHost)

    else if e.keyCode == 39 # right
      if util.selection.isAtEnd()
        nextHost = findAdjacentHost(host, 1)
        if nextHost
          e.preventDefault()
          util.selection.setAtStart(nextHost)

    else if e.keyCode == 8 # backspace
      if util.selection.isAtStart()
        e.preventDefault()
        @onBackSpace()

    else if e.keyCode == 13 # enter
      unless @allowEnter
        e.preventDefault()
        @onEnter()

  handleFocus: ->
    @onFocus()

  handleBlur: ->
    @onBlur()

  selectAll: ->
    el = @getDOMNode()
    util.selection.setAll(el)

  isFocused: ->
    el = @getDOMNode()
    host = util.selection.getHost()
    return el == host


  render: ->
    R.div {
      className: @className
      contentEditable: true
      onInput: @handleInput
      onKeyDown: @handleKeyDown
      onFocus: @handleFocus
      onBlur: @handleBlur
    }





findAdjacentHost = (el, direction) ->
  hosts = document.querySelectorAll("[contenteditable]")
  hosts = _.toArray(hosts)
  index = hosts.indexOf(el)
  return hosts[index + direction]