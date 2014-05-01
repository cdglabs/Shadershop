
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

  getExprString: (parameter) ->
    if @combiner == "composition"
      exprString = parameter
      for childFn in @childFns
        exprString = childFn.getExprString(exprString)
      return exprString

    childExprStrings = @childFns.map (childFn) =>
      childFn.getExprString(parameter)

    if @combiner == "sum"
      childExprStrings.unshift("0.")
      return "(" + childExprStrings.join(" + ") + ")"

    if @combiner == "product"
      childExprStrings.unshift("1.")
      return "(" + childExprStrings.join(" * ") + ")"



class C.ChildFn extends C.Fn
  constructor: ->
    @fn = null
    @domainTranslate = new C.Variable("0")
    @domainScale = new C.Variable("1")
    @rangeTranslate = new C.Variable("0")
    @rangeScale = new C.Variable("1")

  getExprString: (parameter) ->
    domainTranslate = util.glslFloatToString(@domainTranslate.getValue())
    domainScale     = util.glslFloatToString(@domainScale.getValue())
    rangeTranslate  = util.glslFloatToString(@rangeTranslate.getValue())
    rangeScale      = util.glslFloatToString(@rangeScale.getValue())

    exprString = "((#{parameter} - #{domainTranslate}) / #{domainScale})"
    exprString = @fn.getExprString(exprString)
    exprString = "(#{exprString} * #{rangeScale} + #{rangeTranslate})"
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

