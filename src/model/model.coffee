
class C.Variable
  constructor: (@valueString = "0") ->
    @getValue() # to initialize @_lastWorkingValue

  getValue: ->
    value = @_lastWorkingValue
    try
      value = util.evaluate(@valueString)
    @_lastWorkingValue = value
    return value


class C.Sine
  constructor: ->
    @domainTranslate = new C.Variable("0")
    @domainScale = new C.Variable("1")
    @rangeTranslate = new C.Variable("0")
    @rangeScale = new C.Variable("1")

  exprString: ->
    fn = "sin"
    domainTranslate = @domainTranslate.getValue()
    domainScale = @domainScale.getValue()
    rangeTranslate = @rangeTranslate.getValue()
    rangeScale = @rangeScale.getValue()
    return "(#{fn}((x - (#{domainTranslate})) / (#{domainScale})) * (#{rangeScale}) + (#{rangeTranslate}))"

  fnString: ->
    return "(function (x) { return #{@exprString()}; })"


class C.AppRoot
  constructor: ->
    @sines = []
    @bounds = {
      xMin: -10
      xMax: 10
      yMin: -10
      yMax: 10
    }
