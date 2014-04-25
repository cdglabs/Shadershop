
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
    childExprStrings = @childReferences.map (childReference) =>
      childReference.getExprString(parameter)
    childExprStrings.unshift("0")
    return childExprStrings.join(" + ")



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
      new C.BuiltInDefinition("identity", "Line")
      new C.BuiltInDefinition("abs", "Abs")
      new C.BuiltInDefinition("fract", "Fract")
      new C.BuiltInDefinition("floor", "Floor")
      new C.BuiltInDefinition("sin", "Sine")
      new C.CompoundDefinition()
    ]








# class C.Sine
#   constructor: ->
#     @domainTranslate = new C.Variable("0")
#     @domainScale = new C.Variable("1")
#     @rangeTranslate = new C.Variable("0")
#     @rangeScale = new C.Variable("1")

#   exprString: ->
#     fn = "sin"
#     domainTranslate = @domainTranslate.getValue()
#     domainScale = @domainScale.getValue()
#     rangeTranslate = @rangeTranslate.getValue()
#     rangeScale = @rangeScale.getValue()
#     return "(#{fn}((x - (#{domainTranslate})) / (#{domainScale})) * (#{rangeScale}) + (#{rangeTranslate}))"

#   fnString: ->
#     return "(function (x) { return #{@exprString()}; })"


# class C.AppRoot
#   constructor: ->
#     @sines = []
#     @bounds = {
#       xMin: -10
#       xMax: 10
#       yMin: -10
#       yMax: 10
#     }
