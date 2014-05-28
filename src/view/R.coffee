window.R = R = {}


# =============================================================================
# Provide easy access to React.DOM and React.addons.classSet
# =============================================================================

for own key, value of React.DOM
  R[key] = value

R.cx = React.addons.classSet


# =============================================================================
# UniversalMixin gets mixed in to every component
# =============================================================================

R.UniversalMixin = {
  # Extra traversal powers
  ownerView: ->
    @_owner ? @props.__owner__ # undocumented React property

  lookup: (keyName) ->
    return this[keyName] ? @ownerView()?.lookup(keyName)

  lookupView: (viewName) ->
    return this if this == viewName or @viewName() == viewName
    return @ownerView()?.lookupView(viewName)

  lookupViewWithKey: (keyName) ->
    return this if this[keyName]?
    return @ownerView()?.lookupViewWithKey(keyName)

  # Move props to be actual properties on the view
  setPropsOnSelf: (nextProps) ->
    for own propName, propValue of nextProps
      continue if propName == "__owner__"
      this[propName] = propValue

  componentWillMount: ->
    @setPropsOnSelf(@props)

  componentWillUpdate: (nextProps) ->
    @setPropsOnSelf(nextProps)

  # Annotate the created DOM Node
  componentDidMount: ->
    el = @getDOMNode()
    el.dataFor ?= this

  componentWillUnmount: ->
    el = @getDOMNode()
    delete el.dataFor
}


# =============================================================================
# Extra stuff on React.create
# =============================================================================

desugarPropType = (propType, optional=false) ->
  if propType.optional
    propType = propType.optional
    required = false
  else if optional
    required = false
  else
    required = true

  if propType == Number
    propType = React.PropTypes.number
  else if propType == String
    propType = React.PropTypes.string
  else if propType == Boolean
    propType = React.PropTypes.bool
  else if propType == Function
    propType = React.PropTypes.func
  else if propType == Array
    propType = React.PropTypes.array
  else if propType == Object
    propType = React.PropTypes.object
  else if _.isArray(propType)
    # TODO: can't get this to work for some reason
    propType = React.PropTypes.any
    # childPropTypes = propType.map (childPropType) ->
    #   desugarPropType(childPropType, true)
    # propType = React.PropTypes.oneOfType(childPropTypes)
  else
    propType = React.PropTypes.instanceOf(propType)

  if required
    propType = propType.isRequired

  return propType

R.create = (name, opts) ->
  # add name stuff
  opts.displayName = name
  opts.viewName = -> name

  # desugar propTypes
  opts.propTypes ?= {}
  for own propName, propType of opts.propTypes
    opts.propTypes[propName] = desugarPropType(propType)

  # add the universal mixin
  opts.mixins ?= []
  opts.mixins.unshift(R.UniversalMixin)

  # create and register it
  R[name] = React.createClass(opts)


# =============================================================================
# Include all the view code
# =============================================================================

require("./ui/TextFieldView")

require("./AppRootView")

require("./ShaderOverlayView")

require("./PaletteView")
require("./PlotLayoutView")
require("./ThumbnailPlotLayoutView")
require("./OutlineView")
require("./InspectorView")
require("./VariableView")

require("./plot/GridView")
require("./plot/ShaderCartesianView")


