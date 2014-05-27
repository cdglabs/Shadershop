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

Element::getClippingRect = ->
  rect = @getBoundingClientRect()
  rect = {
    left: rect.left
    right: rect.right
    top: rect.top
    bottom: rect.bottom
  }
  el = this.parentNode
  while el?.nodeType == Node.ELEMENT_NODE
    if el.matches(".Scroller")
      scrollerRect = el.getBoundingClientRect()
      rect.left   = Math.max(rect.left,   scrollerRect.left)
      rect.right  = Math.min(rect.right,  scrollerRect.right)
      rect.top    = Math.max(rect.top,    scrollerRect.top)
      rect.bottom = Math.min(rect.bottom, scrollerRect.bottom)
    el = el.parentNode
  rect.width  = rect.right  - rect.left
  rect.height = rect.bottom - rect.top
  return rect


# =============================================================================
# Util functions
# =============================================================================

util.preventDefault = (e) ->
  e.preventDefault()
  util.selection.set(null)


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
  # Hard-coded optimizations
  if value == 0
    return "0."
  if value == 1
    return "1."

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
    string = ""
    for component, index in value
      string += util.glslString(component)
      string += "," if index < length - 1
    string = util.glslVectorType(length) + "(" + string + ")"
    return string

  if _.isArray(value) and _.isArray(value[0])
    # Matrix. Note: Numeric stores matrices as an array of arrays in row major
    # order, but glsl needs values in column major order.
    length = value.length # assume square matrix
    if length == 1
      return util.glslString(value[0][0])
    strings = []
    string = ""
    for col in [0...length]
      for row in [0...length]
        string += util.glslString(value[row][col])
        string += "," if row < length - 1 or col < length - 1
    string = util.glslMatrixType(length) + "(" + string + ")"
    return string


util.glslMatrixArray = (matrix) ->
  # Note: Numeric stores matrices as array of arrays in row major order, but
  # glsl array needs to be in column major order.
  result = []
  length = matrix.length
  for col in [0...length]
    for row in [0...length]
      result.push matrix[row][col]
  return result


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


util.constructVector = (dimensions, value) ->
  return [0...dimensions].map -> value


util.safeInv = (m) ->
  if m.length == 1 and m[0][0] == 0
    return numeric.identity(1)

  try
    return numeric.inv(m)
  catch
    return numeric.identity(m.length)

util.vectorMask = (a, b, mask) ->
  # Takes components from a when mask is 1, b when mask is 0
  return numeric.add(
    numeric.mul(a, mask)
    numeric.mul(b, numeric.sub(1, mask))
  )




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
# Color
# =============================================================================

`
function RGBToHSL(r, g, b) {
  var
  min = Math.min(r, g, b),
  max = Math.max(r, g, b),
  diff = max - min,
  h = 0, s = 0, l = (min + max) / 2;

  if (diff != 0) {
    s = l < 0.5 ? diff / (max + min) : diff / (2 - max - min);

    h = (r == max ? (g - b) / diff : g == max ? 2 + (b - r) / diff : 4 + (r - g) / diff) * 60;
  }

  return [h, s, l];
}

function HSLToRGB(h, s, l) {
  if (s == 0) {
    return [l, l, l];
  }

  var temp2 = l < 0.5 ? l * (1 + s) : l + s - l * s;
  var temp1 = 2 * l - temp2;

  h /= 360;

  var
  rtemp = (h + 1 / 3) % 1,
  gtemp = h,
  btemp = (h + 2 / 3) % 1,
  rgb = [rtemp, gtemp, btemp],
  i = 0;

  for (; i < 3; ++i) {
    rgb[i] = rgb[i] < 1 / 6 ? temp1 + (temp2 - temp1) * 6 * rgb[i] : rgb[i] < 1 / 2 ? temp2 : rgb[i] < 2 / 3 ? temp1 + (temp2 - temp1) * 6 * (2 / 3 - rgb[i]) : temp1;
  }

  return rgb;
}
`

util.rgbToHsl = RGBToHSL
util.hslToRgb = HSLToRGB


# =============================================================================
# Additional
# =============================================================================

require("./selection")
require("./canvas")
require("./evaluate")
require("./vector")
