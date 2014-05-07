window.UI = UI = new class
  constructor: ->
    @dragging = null
    @autofocus = null

    @selectedFn = _.last(appRoot.fns)

    @selectedChildFn = null

    @expandedPaths = {}


    @registerEvents()

  registerEvents: ->
    window.addEventListener("mousemove", @handleWindowMouseMove)
    window.addEventListener("mouseup", @handleWindowMouseUp)


  # ===========================================================================
  # Event Util
  # ===========================================================================

  preventDefault: (e) ->
    e.preventDefault()
    util.selection.set(null)


  # ===========================================================================
  # Dragging and Mouse Position
  # ===========================================================================

  handleWindowMouseMove: (e) =>
    @mousePosition = {x: e.clientX, y: e.clientY}
    @dragging?.onMove?(e)

  handleWindowMouseUp: (e) =>
    @dragging?.onUp?(e)
    @dragging = null
    if @hoverIsActive
      @hoverData = null
      @hoverIsActive = false

  getElementUnderMouse: ->
    draggingOverlayEl = document.querySelector(".draggingOverlay")
    draggingOverlayEl?.style.pointerEvents = "none"

    el = document.elementFromPoint(@mousePosition.x, @mousePosition.y)

    draggingOverlayEl?.style.pointerEvents = ""

    return el

  getViewUnderMouse: ->
    el = @getElementUnderMouse()
    el = el?.closest (el) -> el.dataFor?
    return el?.dataFor


  # ===========================================================================
  # Controller
  # ===========================================================================

  selectFn: (fn) ->
    return unless fn instanceof C.DefinedFn
    @selectedFn = fn
    @selectedChildFn = null

  selectChildFn: (childFn) ->
    @selectedChildFn = childFn

  addFn: (appRoot) ->
    fn = new C.DefinedFn()
    appRoot.fns.push(fn)
    @selectFn(fn)

  addChildFn: (fn) ->
    childFn = new C.ChildFn(fn)
    @selectedFn.childFns.push(childFn)
    @selectChildFn(childFn)

  removeChildFn: (fn, childFnIndex) ->
    [removedChildFn] = fn.childFns.splice(childFnIndex, 1)
    if @selectedChildFn == removedChildFn
      @selectChildFn(null)


  getPathString: (path) ->
    pathIds = path.map (childFn) -> C.id(childFn)
    return pathString = pathIds.join(",")

  isPathExpanded: (path) ->
    pathString = @getPathString(path)
    if !@expandedPaths[pathString]?
      return true
    return @expandedPaths[pathString]

  setPathExpanded: (path, expanded) ->
    pathString = @getPathString(path)
    @expandedPaths[pathString] = expanded


  # ===========================================================================
  # Scrubbing variables
  # ===========================================================================

  startVariableScrub: (opts) ->
    variable = opts.variable
    cursor = opts.cursor
    onMove = opts.onMove
    # onMove should be a function which returns a valueString

    UI.dragging = {
      cursor
      onMove: (e) =>
        newValueString = onMove(e)
        variable.valueString = newValueString
    }



  # ===========================================================================
  # Auto Focus
  # ===========================================================================

  setAutoFocus: (opts) ->
    opts.descendantOf ?= []
    if !_.isArray(opts.descendantOf)
      opts.descendantOf = [opts.descendantOf]

    opts.props ?= {}

    opts.location ?= "end"

    @autofocus = opts

  attemptAutoFocus: (textFieldView) ->
    return unless @autofocus

    matchesDescendantOf = _.every @autofocus.descendantOf, (ancestorView) =>
      textFieldView.lookupView(ancestorView)
    return unless matchesDescendantOf

    matchesProps = _.every @autofocus.props, (propValue, propName) =>
      textFieldView.lookup(propName) == propValue
    return unless matchesProps

    # Found a match, focus it.
    el = textFieldView.getDOMNode()
    if @autofocus.location == "start"
      util.selection.setAtStart(el)
    else if @autofocus.location == "end"
      util.selection.setAtEnd(el)

    @autofocus = null

