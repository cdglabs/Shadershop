window.Actions = Actions = {}

# =============================================================================
# Manipulating Fn hierarchy
# =============================================================================

findParentOf = (childFnTarget) ->
  recurse = (compoundFn) ->
    if _.contains(compoundFn.childFns, childFnTarget)
      return compoundFn

    for childFn in compoundFn.childFns
      if childFn.fn instanceof C.CompoundFn
        if recurse(childFn.fn)
          return childFn.fn

    return null
  recurse(UI.selectedFn)


Actions.addDefinedFn = ->
  fn = new C.DefinedFn()
  appRoot.fns.push(fn)
  Actions.selectFn(fn)

Actions.addChildFn = (fn) ->
  if UI.selectedChildFn
    if UI.selectedChildFn.fn instanceof C.CompoundFn and UI.isChildFnExpanded(UI.selectedChildFn)
      parent = UI.selectedChildFn.fn
    else
      parent = findParentOf(UI.selectedChildFn)

  parent ?= UI.selectedFn
  childFn = new C.ChildFn(fn)
  parent.childFns.push(childFn)
  Actions.selectChildFn(childFn)


# =============================================================================
# Manipulating Fn incidentals
# =============================================================================

Actions.setFnLabel = (fn, newValue) ->
  fn.label = newValue

Actions.setFnBounds = (fn, newBounds) ->
  fn.bounds = newBounds

Actions.setVariableValueString = (variable, newValueString) ->
  variable.valueString = newValueString

# =============================================================================
# Changing UI state (selection, hover)
# =============================================================================

Actions.selectFn = (fn) ->
  return unless fn instanceof C.DefinedFn
  UI.selectedFn = fn
  UI.selectedChildFn = null

Actions.selectChildFn = (childFn) ->
  UI.selectedChildFn = childFn

Actions.hoverChildFn = (childFn) ->
  UI.hoveredChildFn = childFn




