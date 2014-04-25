
class C.Variable
  constructor: (@valueString = "0") ->
    @getValue() # to initialize @_lastWorkingValue

  getValue: ->
    value = @_lastWorkingValue
    try
      value = util.evaluate(@valueString)
    @_lastWorkingValue = value
    return value




class C.Definition
  constructor: ->


class C.BuiltInDefinition extends C.Definition
  constructor: (@fnName, @label) ->

  getExprString: (parameter) ->
    "#{@fnName}(#{parameter})"


class C.CompoundDefinition extends C.Definition
  constructor: ->
    @label = ""
    @combiner = "sum"
    @childReferences = []
    @bounds = {
      xMin: -6
      xMax: 6
      yMin: -6
      yMax: 6
    }

  getExprString: (parameter) ->
    if @combiner == "composition"
      exprString = parameter
      for childReference in @childReferences
        exprString = childReference.getExprString(exprString)
      return exprString

    childExprStrings = @childReferences.map (childReference) =>
      childReference.getExprString(parameter)

    if @combiner == "sum"
      childExprStrings.unshift("0")
      return childExprStrings.join(" + ")

    if @combiner == "product"
      childExprStrings.unshift("1")
      return childExprStrings.join(" * ")



class C.Reference
  constructor: ->
    @definition = null
    @domainTranslate = new C.Variable("0")
    @domainScale = new C.Variable("1")
    @rangeTranslate = new C.Variable("0")
    @rangeScale = new C.Variable("1")

  getExprString: (parameter) ->
    domainTranslate = @domainTranslate.getValue()
    domainScale = @domainScale.getValue()
    rangeTranslate = @rangeTranslate.getValue()
    rangeScale = @rangeScale.getValue()

    exprString = "((#{parameter} - #{domainTranslate}) / #{domainScale})"
    exprString = @definition.getExprString(exprString)
    exprString = "(#{exprString} * #{rangeScale} + #{rangeTranslate})"
    return exprString





class C.AppRoot
  constructor: ->
    @definitions = [
      new C.CompoundDefinition()
    ]



window.builtIn = builtIn = {}

builtIn.definitions = [
  new C.BuiltInDefinition("identity", "Line")
  new C.BuiltInDefinition("abs", "Abs")
  new C.BuiltInDefinition("fract", "Fract")
  new C.BuiltInDefinition("floor", "Floor")
  new C.BuiltInDefinition("sin", "Sine")
]

