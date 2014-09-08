R.create "SymbolicView",
  render: ->
    return R.div() if !UI.showSymbolic

    string = stringifyFn(UI.selectedFn, "x", true)

    R.div {},
      if string
        R.div {className: "Symbolic"},
          R.span {},
            stringifyFn(UI.selectedFn, "x", true)



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
  size = nonIdentitySize(m)
  if size == 0
    return null

  if size == 1
    return m[0][0]

  return "M#{size}"

formatVector = (v) ->
  size = 0
  for d in [0 ... config.dimensions]
    if v[d] != 0
      size = d + 1

  if size == 0
    return null
  if size == 1
    return v[0]

  return "V#{size}"


stringifyFn = (fn, freeVariable="x", force=false) ->
  if fn instanceof C.BuiltInFn
    if fn.label == "Line"
      return freeVariable
    else
      return fn.label + "( #{freeVariable} )"

  if fn instanceof C.DefinedFn and !force
    return fn.label + "( #{freeVariable} )"

  if fn instanceof C.CompoundFn
    if fn.combiner == "last"
      return stringifyFn(_.last(fn.childFns), freeVariable)

    if fn.combiner == "composition"
      s = freeVariable
      for childFn in fn.childFns
        s = stringifyFn(childFn, s)
      return s

    if fn.combiner == "sum"
      strings = for childFn in fn.childFns
        stringifyFn(childFn, freeVariable)
      return strings.join(" + ")

    if fn.combiner == "product"
      strings = for childFn in fn.childFns
        "(#{stringifyFn(childFn, freeVariable)})"
      return strings.join(" * ")

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
