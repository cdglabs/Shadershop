R.create "SymbolicView",
  render: ->
    return R.div() if !UI.showSymbolic

    d = dimensionsToDisplay()
    if d == 1
      freeVariable = "x"
    else
      freeVariable = '<span class="SymbolVector"><span class="SymbolCell">x₁</span><span class="SymbolCell">x₂</span></span>'

    string = stringifyFn(UI.selectedFn, freeVariable, true)

    R.div {},
      if string
        R.div {className: "Symbolic", dangerouslySetInnerHTML: {__html: string}}


# HACK
dimensionsToDisplay = ->
  if UI.selectedFn.plotLayout.display2d then 2 else 1



isVectorIdentity = (v) ->
  return _.all v, (n) -> n == 0

isMatrixIdentity = (m) ->
  for row, rowIndex in m
    for value, colIndex in row
      return false if rowIndex == colIndex and value != 1
      return false if rowIndex != colIndex and value != 0
  return true





nonIdentityCell = (x, y, m) ->
  identityCell = if x == y then 1 else 0
  return m[x][y] != identityCell


nonIdentitySize = (m) ->
  size = 0
  for d in [0 ... config.dimensions]
    found = false

    y = d
    for x in [0 .. d]
      if nonIdentityCell(x, y, m)
        found = true

    x = d
    for y in [0 .. d]
      if nonIdentityCell(x, y, m)
        found = true

    if found
      size = d + 1

  return size

formatMatrix = (m) ->
  if isMatrixIdentity(m)
    return null

  size = dimensionsToDisplay()
  if size == 1
    return formatNumber m[0][0]

  rows = []
  for rowIndex in [0...size]
    row = []
    for colIndex in [0...size]
      row.push '<span class="SymbolCell">' + formatNumber(m[rowIndex][colIndex]) + '</span>'
    rows.push '<span class="SymbolRow">' + row.join("") + '</span>'
  return '<span class="SymbolMatrix">' + rows.join("") + '</span>'

formatVector = (v) ->
  if isVectorIdentity(v)
    return null

  size = dimensionsToDisplay()
  if size == 1
    return formatNumber v[0]

  cells = []
  for d in [0...size]
    cells.push '<span class="SymbolCell">' + formatNumber(v[d]) + '</span>'
  return '<span class="SymbolVector">' + cells.join("") + '</span>'



formatNumber = (n) ->
  s = n.toFixed(3)
  # remove excess 0s after decimal point
  if s.indexOf(".") != -1
    s = s.replace(/\.?0*$/, "")
  return s


stringifyFn = (fn, freeVariable, force=false) ->
  if fn instanceof C.BuiltInFn
    if fn.label == "Line"
      return freeVariable
    else
      return fn.label + "( #{freeVariable} )"

  if fn instanceof C.DefinedFn and !force
    return fn.label + "( #{freeVariable} )"

  if fn instanceof C.CompoundFn
    visibleChildFns = _.filter fn.childFns, (childFn) -> childFn.visible

    if fn.combiner == "last"
      return stringifyFn(_.last(visibleChildFns), freeVariable)

    if fn.combiner == "composition"
      s = freeVariable
      for childFn in visibleChildFns
        s = stringifyFn(childFn, s)
      return s

    if fn.combiner == "sum"
      if visibleChildFns.length == 0
        return "0"
      strings = for childFn in visibleChildFns
        stringifyFn(childFn, freeVariable)
      return "(" + strings.join(" + ") + ")"

    if fn.combiner == "product"
      if visibleChildFns.length == 0
        return "1"
      strings = for childFn in visibleChildFns
        "(#{stringifyFn(childFn, freeVariable)})"
      return "(" + strings.join(" * ") + ")"

    if fn.combiner == "min" or fn.combiner == "max"
      if visibleChildFns.length == 0
        return "0"
      strings = for childFn in visibleChildFns
        stringifyFn(childFn, freeVariable)
      return "#{fn.combiner}(" + strings.join(", ") + ")"


  if fn instanceof C.ChildFn
    domainTranslate = formatVector fn.getDomainTranslate()
    domainTransform = formatMatrix fn.getDomainTransform()
    rangeTranslate  = formatVector fn.getRangeTranslate()
    rangeTransform  = formatMatrix fn.getRangeTransform()

    s = freeVariable

    if domainTranslate?
      s = "(#{s} - #{domainTranslate})"
    if domainTransform?
      s = "#{s} / #{domainTransform}"

    s = stringifyFn(fn.fn, s)

    if rangeTransform?
      s = "#{s} * #{rangeTransform}"
    if rangeTranslate?
      s = "#{s} + #{rangeTranslate}"

    return s
