window.util = util = {}


# =============================================================================
# Underscore Addons
# =============================================================================

_.concatMap = (array, fn) ->
  _.flatten(_.map(array, fn), true)


# =============================================================================
# DOM Addons
# =============================================================================

Element::matches ?= Element::webkitMatchesSelector ? Element::mozMatchesSelector ? Element::oMatchesSelector

Element::closest = (selector) ->
  if _.isString(selector)
    fn = (el) -> el.matches(selector)
  else
    fn = selector

  if fn(this)
    return this
  else
    parent = @parentNode
    if parent? && parent.nodeType == Node.ELEMENT_NODE
      return parent.closest(fn)
    else
      return undefined

Element::getMarginRect = ->
  rect = @getBoundingClientRect()
  style = window.getComputedStyle(this)
  result = {
    top: rect.top - parseInt(style["margin-top"], 10)
    left: rect.left - parseInt(style["margin-left"], 10)
    bottom: rect.bottom + parseInt(style["margin-bottom"], 10)
    right: rect.right + parseInt(style["margin-right"], 10)
  }
  result.width = result.right - result.left
  result.height = result.bottom - result.top
  return result

Element::isOnScreen = ->
  rect = @getBoundingClientRect()
  screenWidth = window.innerWidth
  screenHeight = window.innerHeight
  vertical = (0 <= rect.top <= screenHeight or 0 <= rect.bottom <= screenHeight)
  horizontal = (0 <= rect.left <= screenWidth or 0 <= rect.right <= screenWidth)
  return vertical and horizontal


# =============================================================================
# Util functions
# =============================================================================

util.lerp = (x, dMin, dMax, rMin, rMax) ->
  ratio = (x - dMin) / (dMax - dMin)
  return ratio * (rMax - rMin) + rMin


util.floatToString = (value, precision = 0.1, removeExtraZeros = false) ->
  if precision < 1
    digitPrecision = -Math.round(Math.log(precision)/Math.log(10))
    string = value.toFixed(digitPrecision)
  else
    string = value.toFixed(0)

  if removeExtraZeros
    string = string.replace(/\.?0*$/, "")

  if /^-0(\.0*)?$/.test(string)
    # Remove extraneous negative sign
    string = string.slice(1)

  return string


util.glslString = (value) ->
  if _.isNumber(value)
    # Float.
    string = value.toString()
    unless /\./.test(string)
      string = string + "."
    return string

  if _.isArray(value) and _.isNumber(value[0])
    # Vector.
    length = value.length
    if length == 1
      return util.glslString(value[0])
    strings = value.map(util.glslString)
    string = util.glslVectorType(length) + "(" + strings.join(",") + ")"
    return string

  if _.isArray(value) and _.isArray(value[0])
    # Matrix. Note: Numeric stores matrices as an array of arrays in row major
    # order, but glsl needs values in column major order.
    length = value.length # assume square matrix
    if length == 1
      return util.glslString(value[0][0])
    strings = []
    for col in [0...length]
      for row in [0...length]
        strings.push(util.glslString(value[row][col]))
    string = util.glslMatrixType(length) + "(" + strings.join(",") + ")"
    return string


util.glslVectorType = (dimensions) ->
  return "float" if dimensions == 1
  return "vec"+dimensions


util.glslMatrixType = (dimensions) ->
  return "float" if dimensions == 1
  return "mat"+dimensions


util.glslGetComponent = (expr, dimensions, component) ->
  return expr if dimensions == 1
  return expr + "[" + component + "]"


util.glslSetComponent = (expr, dimensions, component, value) ->
  return expr + " = " + value if dimensions == 1
  return expr + "[" + component + "]" + " = " + value


util.constructVector = (dimensions, value = 0) ->
  return [0...dimensions].map -> value


util.safeInv = (m) ->
  if m.length == 1 and m[0][0] == 0
    return numeric.identity(1)

  try
    return numeric.inv(m)
  catch
    return numeric.identity(m.length)



util.onceDragConsummated = (downEvent, callback, notConsummatedCallback=null) ->
  consummated = false
  originalX = downEvent.clientX
  originalY = downEvent.clientY

  handleMove = (moveEvent) ->
    dx = moveEvent.clientX - originalX
    dy = moveEvent.clientY - originalY
    d  = Math.max(Math.abs(dx), Math.abs(dy))
    if d > 3
      consummated = true
      removeListeners()
      callback?(moveEvent)

  handleUp = (upEvent) ->
    if !consummated
      notConsummatedCallback?(upEvent)
    removeListeners()

  removeListeners = ->
    window.removeEventListener("mousemove", handleMove)
    window.removeEventListener("mouseup", handleUp)

  window.addEventListener("mousemove", handleMove)
  window.addEventListener("mouseup", handleUp)


# =============================================================================
# Additional
# =============================================================================

require("./selection")
require("./canvas")
require("./evaluate")
