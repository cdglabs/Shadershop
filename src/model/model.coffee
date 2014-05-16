
class C.Variable
  constructor: (@valueString = "0") ->
    @valueString = @valueString.toString()
    @_lastValueString = null
    @_lastWorkingValue = null
    @getValue() # to initialize @_lastWorkingValue

  getValue: ->
    if @valueString == @_lastValueString
      return @_lastWorkingValue

    value = @_lastWorkingValue
    try
      if /^[-+]?[0-9]*\.?[0-9]+$/.test(@valueString)
        value = parseFloat(@valueString)
      else
        value = util.evaluate(@valueString)
    value = @_lastWorkingValue unless _.isFinite(value)

    @_lastWorkingValue = value
    @_lastValueString = @valueString
    return value



class C.Fn
  constructor: ->
  getExprString: (parameter) -> throw "Not implemented"
  evaluate: (x) -> throw "Not implemented"


class C.BuiltInFn extends C.Fn
  constructor: (@fnName, @label) ->

  getExprString: (parameter) ->
    if @fnName == "identity"
      return parameter

    return "#{@fnName}(#{parameter})"

  evaluate: (x) ->
    return builtIn.fnEvaluators[@fnName](x)


class C.CompoundFn extends C.Fn
  constructor: ->
    @combiner = "sum"
    @childFns = []

  evaluate: (x) ->
    if @combiner == "last"
      if @childFns.length > 0
        return _.last(@childFns).evaluate(x)
      else
        return util.constructVector(config.dimensions, 0)

    if @combiner == "composition"
      for childFn in @childFns
        x = childFn.evaluate(x)
      return x

    if @combiner == "sum"
      reducer = (result, childFn) ->
        numeric.add(result, childFn.evaluate(x))
      return _.reduce(@childFns, reducer, util.constructVector(config.dimensions, 0))

    if @combiner == "product"
      reducer = (result, childFn) ->
        numeric.mul(result, childFn.evaluate(x))
      return _.reduce(@childFns, reducer, util.constructVector(config.dimensions, 1))

  getExprString: (parameter) ->
    visibleChildFns = _.filter @childFns, (childFn) -> childFn.visible

    if @combiner == "last"
      if visibleChildFns.length > 0
        return _.last(visibleChildFns).getExprString(parameter)
      else
        return util.glslString(util.constructVector(config.dimensions, 0))

    if @combiner == "composition"
      exprString = parameter
      for childFn in visibleChildFns
        exprString = childFn.getExprString(exprString)
      return exprString

    childExprStrings = visibleChildFns.map (childFn) =>
      childFn.getExprString(parameter)

    if @combiner == "sum"
      if childExprStrings.length == 0
        return util.glslString(util.constructVector(config.dimensions, 0))
      else
        return "(" + childExprStrings.join(" + ") + ")"

    if @combiner == "product"
      if childExprStrings.length == 0
        return util.glslString(util.constructVector(config.dimensions, 1))
      else
        return "(" + childExprStrings.join(" * ") + ")"


class C.DefinedFn extends C.CompoundFn
  constructor: ->
    super()
    @combiner = "last"
    @plot = new C.Plot()



class C.ChildFn extends C.Fn
  constructor: (@fn) ->
    @visible = true
    @domainTranslate = util.constructVector(config.dimensions, 0).map (v) ->
      new C.Variable(v)
    @domainTransform = numeric.identity(config.dimensions).map (row) ->
      row.map (v) ->
        new C.Variable(v)

    @rangeTranslate = util.constructVector(config.dimensions, 0).map (v) ->
      new C.Variable(v)
    @rangeTransform = numeric.identity(config.dimensions).map (row) ->
      row.map (v) ->
        new C.Variable(v)

  getDomainTranslate: ->
    @domainTranslate.map (v) -> v.getValue()

  getDomainTransform: ->
    @domainTransform.map (row) ->
      row.map (v) ->
        v.getValue()

  getRangeTranslate: ->
    @rangeTranslate.map (v) -> v.getValue()

  getRangeTransform: ->
    @rangeTransform.map (row) ->
      row.map (v) ->
        v.getValue()

  evaluate: (x) ->
    domainTranslate    = @getDomainTranslate()
    domainTransformInv = util.safeInv(@getDomainTransform())
    rangeTranslate     = @getRangeTranslate()
    rangeTransform     = @getRangeTransform()

    x = numeric.dot(domainTransformInv, numeric.sub(x, domainTranslate))
    x = @fn.evaluate(x)
    x = numeric.add(numeric.dot(rangeTransform, x), rangeTranslate)
    return x

  getExprString: (parameter) ->
    domainTranslate    = util.glslString(@getDomainTranslate())
    domainTransformInv = util.glslString(util.safeInv(@getDomainTransform()))
    rangeTranslate     = util.glslString(@getRangeTranslate())
    rangeTransform     = util.glslString(@getRangeTransform())

    exprString = parameter

    if domainTranslate != @_zeroVectorString
      exprString = "(#{exprString} - #{domainTranslate})"

    if domainTransformInv != @_identityMatrixString
      exprString = "(#{domainTransformInv} * #{exprString})"

    exprString = @fn.getExprString(exprString)

    if rangeTransform != @_identityMatrixString
      exprString = "(#{rangeTransform} * #{exprString})"

    if rangeTranslate != @_zeroVectorString
      exprString = "(#{exprString} + #{rangeTranslate})"

    return exprString

  _zeroVectorString: util.glslString(util.constructVector(config.dimensions, 0))
  _identityMatrixString: util.glslString(numeric.identity(config.dimensions))




class C.Plot
  constructor: ->
    @domainCenter = util.constructVector(config.dimensions, 0)
    @rangeCenter = util.constructVector(config.dimensions, 0)
    @scale = 5 # minimum distance that can be "seen" from the center

    @type = "cartesian"

  getBounds: (width, height) ->
    # TODO: This will be removed at some point...
    minDimension = Math.min(width, height)
    w = width  / minDimension
    h = height / minDimension
    return {
      xMin: @domainCenter[0] - @scale * w
      xMax: @domainCenter[0] + @scale * w
      yMin: @rangeCenter[0]  - @scale * h
      yMax: @rangeCenter[0]  + @scale * h
    }

  getPixelSize: (width, height) ->
    # How "wide" a pixel is in world coordinates
    minDimension = Math.min(width, height)
    return 2 * @scale / minDimension

  getDimensions: ->
    # TODO: should be based on @type
    return [
      {space: "domain", coord: 0}
      {space: "range",  coord: 0}
    ]

  toWorld: (width, height, {x, y}) ->
    pixelSize = @getPixelSize(width, height)
    center = {
      domain: @domainCenter
      range:  @rangeCenter
    }
    dimensions = @getDimensions()

    xOffset = x - width/2
    yOffset = -(y - height/2)

    result = {
      domain: util.constructVector(config.dimensions, null)
      range:  util.constructVector(config.dimensions, null)
    }
    result[dimensions[0].space][dimensions[0].coord] = center[dimensions[0].space][dimensions[0].coord] + xOffset * pixelSize
    result[dimensions[1].space][dimensions[1].coord] = center[dimensions[1].space][dimensions[1].coord] + yOffset * pixelSize

    return result

  toPixel: (width, height, {domain, range}) ->
    pixelSize = @getPixelSize(width, height)
    center = {
      domain: @domainCenter
      range:  @rangeCenter
    }
    dimensions = @getDimensions()

    offset = {
      domain: util.vector.sub(domain, center.domain)
      range:  util.vector.sub(range,  center.range)
    }

    xOffset = offset[dimensions[0].space][dimensions[0].coord] / pixelSize
    yOffset = offset[dimensions[1].space][dimensions[1].coord] / pixelSize

    x = width/2 + xOffset
    y = height/2 - yOffset

    return {x, y}




class C.AppRoot
  constructor: ->
    @fns = [
      new C.DefinedFn()
    ]



window.builtIn = builtIn = {}

builtIn.fns = [
  new C.BuiltInFn("identity", "Line")
  new C.BuiltInFn("abs", "Abs")
  new C.BuiltInFn("fract", "Fract")
  new C.BuiltInFn("floor", "Floor")
  new C.BuiltInFn("sin", "Sine")
]

builtIn.fnEvaluators = {
  identity: (x) -> x
  abs: numeric.abs
  fract: (x) -> numeric.sub(x, numeric.floor(x))
  floor: numeric.floor
  sin: numeric.sin
}

builtIn.defaultPlot = new C.Plot()
