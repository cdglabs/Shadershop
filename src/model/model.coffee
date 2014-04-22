class C.Sine
  constructor: ->
    @domainTranslate = 0
    @domainScale = 1
    @rangeTranslate = 0
    @rangeScale = 1

  exprString: ->
    fn = "sin"
    return "(#{fn}((x - (#{@domainTranslate})) / (#{@domainScale})) * (#{@rangeScale}) + (#{@rangeTranslate}))"

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
