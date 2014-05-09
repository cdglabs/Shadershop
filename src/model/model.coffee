
class C.Variable
  constructor: (@valueString = "0") ->
    @valueString = @valueString.toString()
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
        return [0,0,0,0]

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
    if @combiner == "last"
      if @childFns.length > 0
        return _.last(@childFns).getExprString(parameter)
      else
        return util.glslString([0,0,0,0])

    if @combiner == "composition"
      exprString = parameter
      for childFn in @childFns
        exprString = childFn.getExprString(exprString)
      return exprString

    childExprStrings = @childFns.map (childFn) =>
      childFn.getExprString(parameter)

    if @combiner == "sum"
      if childExprStrings.length == 0
        return util.glslString([0,0,0,0])
      else
        return "(" + childExprStrings.join(" + ") + ")"

    if @combiner == "product"
      if childExprStrings.length == 0
        return util.glslString([1,1,1,1])
      else
        return "(" + childExprStrings.join(" * ") + ")"


class C.DefinedFn extends C.CompoundFn
  constructor: ->
    super()
    @combiner = "last"
    @bounds = {
      xMin: -5
      xMax: 5
      yMin: -5
      yMax: 5
    }



class C.ChildFn extends C.Fn
  constructor: (@fn) ->
    @domainTranslate = [0, 0, 0, 0].map (v) ->
      new C.Variable(v)
    @domainTransform = numeric.identity(4).map (row) ->
      row.map (v) ->
        new C.Variable(v)

    @rangeTranslate = [0, 0, 0, 0].map (v) ->
      new C.Variable(v)
    @rangeTransform = numeric.identity(4).map (row) ->
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

    if domainTranslate != util.glslString([0,0,0,0])
      exprString = "(#{exprString} - #{domainTranslate})"

    if domainTransformInv != util.glslString(numeric.identity(4))
      exprString = "(#{domainTransformInv} * #{exprString})"

    exprString = @fn.getExprString(exprString)

    if rangeTransform != util.glslString(numeric.identity(4))
      exprString = "(#{rangeTransform} * #{exprString})"

    if rangeTranslate != util.glslString([0,0,0,0])
      exprString = "(#{exprString} + #{rangeTranslate})"

    return exprString





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
