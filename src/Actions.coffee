window.Actions = Actions = {}


# =============================================================================
# Manipulating Fn hierarchy
# =============================================================================

findParentIndexOf = (childFnTarget) ->
  recurse = (compoundFn) ->
    index = compoundFn.childFns.indexOf(childFnTarget)
    if index != -1
      return {
        parent: compoundFn
        index: index
      }

    for childFn in compoundFn.childFns
      if childFn.fn instanceof C.CompoundFn
        if found = recurse(childFn.fn)
          return found

    return null
  recurse(UI.selectedFn)

getExpandedChildFns = ->
  result = []
  recurse = (childFns) ->
    for childFn in childFns
      continue unless childFn.visible
      result.push(childFn)
      if UI.isChildFnExpanded(childFn) and childFn.fn instanceof C.CompoundFn
        recurse(childFn.fn.childFns)
  recurse(UI.selectedFn.childFns)
  return result


Actions.addDefinedFn = ->
  fn = new C.DefinedFn()
  appRoot.fns.push(fn)
  Compiler.setDirty()
  Actions.selectFn(fn)

Actions.addChildFn = (fn) ->
  selectedChildFnVisible = (UI.selectedChildFn and _.contains(getExpandedChildFns(), UI.selectedChildFn))

  if selectedChildFnVisible
    possibleParent = UI.selectedChildFn.fn
    takesChildren = (possibleParent instanceof C.CompoundFn and UI.isChildFnExpanded(UI.selectedChildFn))
    if takesChildren
      parent = possibleParent
      index = parent.childFns.length
    else
      {parent, index} = findParentIndexOf(UI.selectedChildFn)
      index = index + 1 # insert it after the selectedChildFn

  else
    if UI.selectedFn.childFns.length == 1
      onlyChild = UI.selectedFn.childFns[0]
      possibleParent = onlyChild.fn
      takesChildren = (possibleParent instanceof C.CompoundFn and UI.isChildFnExpanded(onlyChild))
      if takesChildren
        parent = possibleParent
        index = parent.childFns.length

  if !parent?
    parent = UI.selectedFn
    index = parent.childFns.length

  childFn = new C.ChildFn(fn)
  Actions.insertChildFn(parent, childFn, index)
  Actions.selectChildFn(childFn)
  return parent

Actions.addCompoundFn = ->
  fn = new C.CompoundFn()
  fn.childFns = UI.selectedFn.childFns
  childFn = new C.ChildFn(fn)
  UI.selectedFn.childFns = [childFn]
  Compiler.setDirty()

Actions.removeChildFn = (parentCompoundFn, childFn) ->
  index = parentCompoundFn.childFns.indexOf(childFn)
  return if index == -1
  parentCompoundFn.childFns.splice(index, 1)
  Compiler.setDirty()

Actions.insertChildFn = (parentCompoundFn, childFn, index) ->
  parentCompoundFn.childFns.splice(index, 0, childFn)
  Compiler.setDirty()


# =============================================================================
# Manipulating Fn incidentals
# =============================================================================

Actions.setFnLabel = (fn, newValue) ->
  fn.label = newValue

Actions.setCompoundFnCombiner = (compoundFn, combiner) ->
  compoundFn.combiner = combiner
  Compiler.setDirty()

Actions.setVariableValueString = (variable, newValueString) ->
  variable.valueString = newValueString
  Compiler.setDirty()

Actions.toggleChildFnVisible = (childFn) ->
  Actions.setChildFnVisible(childFn, !childFn.visible)

Actions.setChildFnVisible = (childFn, newVisible) ->
  childFn.visible = newVisible
  Compiler.setDirty()


# =============================================================================
# Manipulating Plots
# =============================================================================

Actions.panPlot = (plot, domainOffset, rangeOffset) ->
  plot.domainCenter = numeric.add(plot.domainCenter, domainOffset)
  plot.rangeCenter  = numeric.add(plot.rangeCenter,  rangeOffset)

Actions.zoomPlot = (plot, domainCenter, rangeCenter, scaleFactor) ->
  # scaleFactor > 1 is zoom "out"
  domainOffset = numeric.sub(plot.domainCenter, domainCenter)
  rangeOffset  = numeric.sub(plot.rangeCenter,  rangeCenter)

  plot.domainCenter = numeric.add(domainCenter, numeric.mul(scaleFactor, domainOffset))
  plot.rangeCenter  = numeric.add(rangeCenter,  numeric.mul(scaleFactor, rangeOffset))

  plot.scale *= scaleFactor


# =============================================================================
# Changing UI state (selection, hover, expanded)
# =============================================================================

Actions.selectFn = (fn) ->
  return unless fn instanceof C.DefinedFn
  UI.selectedFn = fn
  UI.selectedChildFn = null

Actions.selectChildFn = (childFn) ->
  UI.selectedChildFn = childFn

Actions.hoverChildFn = (childFn) ->
  UI.hoveredChildFn = childFn

Actions.toggleChildFnExpanded = (childFn) ->
  expanded = UI.isChildFnExpanded(childFn)
  Actions.setChildFnExpanded(childFn, !expanded)

Actions.setChildFnExpanded = (childFn, expanded) ->
  id = C.id(childFn)
  UI.expandedChildFns[id] = expanded



