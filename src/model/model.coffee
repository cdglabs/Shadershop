
class C.Variable
  constructor: (@valueString = "0") ->
    @getValue() # to initialize @_lastWorkingValue

  getValue: ->
    value = @_lastWorkingValue
    try
      if /^[-+]?[0-9]*\.?[0-9]+$/.test(@valueString)
        value = parseFloat(@valueString)
      else
        value = util.evaluate(@valueString)
    @_lastWorkingValue = value
    return value



class C.Fn
  constructor: ->


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
    @label = ""
    @combiner = "sum"
    @childFns = []
    @bounds = {
      xMin: -6
      xMax: 6
      yMin: -6
      yMax: 6
    }

  evaluate: (x) ->
    if @combiner == "composition"
      for childFn in @childFns
        x = childFn.evaluate(x)
      return x

    if @combiner == "sum"
      reducer = (result, childFn) ->
        numeric.add(result, childFn.evaluate(x))
      return _.reduce(@childFns, reducer, [0,0,0,0])

    if @combiner == "product"
      reducer = (result, childFn) ->
        numeric.mul(result, childFn.evaluate(x))
      return _.reduce(@childFns, reducer, [1,1,1,1])


  getExprString: (parameter) ->
    if @combiner == "composition"
      exprString = parameter
      for childFn in @childFns
        exprString = childFn.getExprString(exprString)
      return exprString

    childExprStrings = @childFns.map (childFn) =>
      childFn.getExprString(parameter)

    if @combiner == "sum"
      childExprStrings.unshift(util.glslString([0,0,0,0]))
      return "(" + childExprStrings.join(" + ") + ")"

    if @combiner == "product"
      childExprStrings.unshift(util.glslString([1,1,1,1]))
      return "(" + childExprStrings.join(" * ") + ")"



class C.ChildFn extends C.Fn
  constructor: ->
    @fn = null
    @domainTranslate = new C.Variable("0")
    @domainScale = new C.Variable("1")
    @rangeTranslate = new C.Variable("0")
    @rangeScale = new C.Variable("1")

  getDomainTranslate: ->
    v = @domainTranslate.getValue()
    [v, 0, 0, 0]

  getDomainTransform: ->
    v = @domainScale.getValue()
    [[v, 0, 0, 0], [0,1,0,0], [0,0,1,0], [0,0,0,1]]

  getRangeTranslate: ->
    v = @rangeTranslate.getValue()
    [v, 0, 0, 0]

  getRangeTransform: ->
    v = @rangeScale.getValue()
    [[v, 0, 0, 0], [0,1,0,0], [0,0,1,0], [0,0,0,1]]

  evaluate: (x) ->
    domainTranslate    = @getDomainTranslate()
    domainTransformInv = numeric.inv(@getDomainTransform())
    rangeTranslate     = @getRangeTranslate()
    rangeTransform     = @getRangeTransform()

    x = numeric.dot(domainTransformInv, numeric.sub(x, domainTranslate))
    x = @fn.evaluate(x)
    x = numeric.add(numeric.dot(rangeTransform, x), rangeTranslate)
    return x

  getExprString: (parameter) ->
    domainTranslate    = util.glslString(@getDomainTranslate())
    domainTransformInv = util.glslString(numeric.inv(@getDomainTransform()))
    rangeTranslate     = util.glslString(@getRangeTranslate())
    rangeTransform     = util.glslString(@getRangeTransform())

    exprString = "(#{domainTransformInv} * (#{parameter} - #{domainTranslate}))"
    exprString = @fn.getExprString(exprString)
    exprString = "(#{rangeTransform} * #{exprString} + #{rangeTranslate})"

    return exprString





class C.AppRoot
  constructor: ->
    @fns = [
      new C.CompoundFn()
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
