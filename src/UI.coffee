window.UI = UI = new class
  constructor: ->
    @dragging = null
    @mousePosition = {x: 0, y: 0}
    @autofocus = null

    @selectedFn = _.last(appRoot.fns)

    @selectedChildFns = []
    @hoveredChildFn = null

    @expandedChildFns = {}

    @showSymbolic = false

    @registerEvents()

  registerEvents: ->
    window.addEventListener("mousemove", @handleWindowMouseMove)
    window.addEventListener("mouseup", @handleWindowMouseUp)


  # ===========================================================================
  # Helpers
  # ===========================================================================

  isChildFnExpanded: (childFn) ->
    id = C.id(childFn)
    expanded = @expandedChildFns[id]
    if !expanded?
      if childFn.fn instanceof C.DefinedFn
        return false
      else
        return true
    return expanded

  getSingleSelectedChildFn: ->
    if @selectedChildFns.length == 1
      return @selectedChildFns[0]
    else
      return null


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

