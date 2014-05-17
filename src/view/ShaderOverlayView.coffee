Glod = require("./plot/glod")


R.create "ShaderOverlayView",

  initializeGlod: ->
    @glod = new Glod()
    canvas = @getDOMNode()
    @glod.canvas(canvas, {antialias: true})

    gl = @glod.gl()
    gl.enable(gl.SCISSOR_TEST)
    gl.lineWidth(1.25)

    bufferQuad(@glod)
    bufferCartesianSamples(@glod, 20000)

    @programs = {}

  sizeCanvas: ->
    canvas = @getDOMNode()
    rect = canvas.getBoundingClientRect()
    if canvas.width != rect.width or canvas.height != rect.height
      canvas.width = rect.width
      canvas.height = rect.height

  draw: ->
    canvas = @getDOMNode()

    usedPrograms = {}

    shaderEls = document.querySelectorAll(".Shader")
    for shaderEl in shaderEls
      continue unless shaderEl.isOnScreen()

      rect = shaderEl.getBoundingClientRect()
      clippingRect = shaderEl.getClippingRect()

      continue if clippingRect.height <= 0 or clippingRect.width <= 0

      setViewport(@glod, rect, clippingRect)

      shaderView = shaderEl.dataFor
      exprs = shaderView.exprs
      plot = shaderView.plot
      bounds = plot.getBounds(rect.width, rect.height)

      numSamples = rect.width / config.resolution

      for expr in exprs
        name = plot.type + "," + expr.exprString
        unless @programs[name]

          if plot.type == "cartesian"
            createCartesianProgram(@glod, name, expr.exprString)
          else if plot.type == "colorMap"
            createColorMapProgram(@glod, name, expr.exprString)

          @programs[name] = true
        usedPrograms[name] = true

        if plot.type == "cartesian"
          drawCartesianProgram(@glod, name, numSamples, expr.color, bounds)
        else if plot.type == "colorMap"
          drawColorMapProgram(@glod, name, bounds)

    # Delete unused programs
    for own name, junk of @programs
      unless usedPrograms[name]
        delete @glod._programs[name]
        delete @programs[name]


  # ===========================================================================
  # Lifecycle
  # ===========================================================================

  handleResize: ->
    @sizeCanvas()
    @draw()

  componentDidMount: ->
    @initializeGlod()
    @sizeCanvas()
    window.addEventListener("resize", @handleResize)

  componentWillUnmount: ->
    window.removeEventListener("resize", @handleResize)

  # ===========================================================================
  # Render
  # ===========================================================================

  render: ->
    R.canvas {className: "ShaderOverlay"}






# =============================================================================
# Glod
# =============================================================================

# =============================================================================
# Utility
# =============================================================================

createProgramFromSrc = (glod, name, vertex, fragment) ->
  Glod.preprocessed[name] = {name, fragment, vertex}

  delete glod._programs[name]
  glod.createProgram(name)

setViewport = (glod, rect, clippingRect) ->
  gl = glod.gl()
  canvas = glod.canvas()

  x = rect.left
  y = canvas.height - rect.bottom
  w = rect.width
  h = rect.height

  sx = clippingRect.left
  sy = canvas.height - clippingRect.bottom
  sw = clippingRect.width
  sh = clippingRect.height

  gl.viewport(x, y, w, h)
  gl.scissor(sx, sy, sw, sh)

  glod.viewport_ = {x, y, w, h}



# =============================================================================
# VBOs
# =============================================================================

bufferQuad = (glod) ->
  glod
    .createVBO("quad")
    .uploadCCWQuad("quad")

bufferCartesianSamples = (glod, numSamples) ->
  samplesArray = []
  for i in [0..numSamples]
    samplesArray.push(i)

  if glod.hasVBO("samples")
    glod.deleteVBO("samples")

  glod
    .createVBO("samples")
    .bufferDataStatic("samples", new Float32Array(samplesArray))


# =============================================================================
# Shader Programs
# =============================================================================

createCartesianProgram = (glod, name, expr) ->

  vertex = """
  precision highp float;
  precision highp int;

  attribute float sample;
  uniform float numSamples;
  uniform float xMin;
  uniform float xMax;
  uniform float yMin;
  uniform float yMax;

  float lerp(float x, float dMin, float dMax, float rMin, float rMax) {
    float ratio = (x - dMin) / (dMax - dMin);
    return ratio * (rMax - rMin) + rMin;
  }

  void main() {
    float s = sample / numSamples;

    #{util.glslVectorType(config.dimensions)} x, y;
    x = #{util.glslString(util.constructVector(config.dimensions, 0))};

    #{util.glslSetComponent("x", config.dimensions, 0, "lerp(s, 0., 1., xMin, xMax)")};
    y = #{expr};

    float px, py;
    px = #{util.glslGetComponent("x", config.dimensions, 0)};
    py = #{util.glslGetComponent("y", config.dimensions, 0)};

    px = lerp(px, xMin, xMax, -1., 1.);
    py = lerp(py, yMin, yMax, -1., 1.);

    gl_Position = vec4(px, py, 0., 1.);
  }
  """

  fragment = """
  precision highp float;
  precision highp int;

  uniform vec4 color;

  void main() {
    gl_FragColor = color;
  }
  """

  createProgramFromSrc(glod, name, vertex, fragment)

drawCartesianProgram = (glod, name, numSamples, color, bounds) ->
  glod.begin(name)

  glod.pack("samples", "sample")

  glod.valuev("color", color)
  glod.value("xMin", bounds.xMin)
  glod.value("xMax", bounds.xMax)
  glod.value("yMin", bounds.yMin)
  glod.value("yMax", bounds.yMax)

  glod.value("numSamples", numSamples)

  glod.ready().lineStrip().drawArrays(0, numSamples)

  glod.end()



createColorMapProgram = (glod, name, expr) ->

  vertex = """
  precision highp float;
  precision highp int;

  attribute vec4 position;

  void main() {
    gl_Position = position;
  }
  """

  # TODO: Needs proper support for config.dimensions
  fragment = """
  precision highp float;
  precision highp int;

  uniform float screenXMin, screenXMax, screenYMin, screenYMax;

  uniform float xMin;
  uniform float xMax;
  uniform float yMin;
  uniform float yMax;

  float lerp(float x, float dMin, float dMax, float rMin, float rMax) {
    float ratio = (x - dMin) / (dMax - dMin);
    return ratio * (rMax - rMin) + rMin;
  }

  void main() {
    vec4 x = vec4(
      lerp(gl_FragCoord.x, screenXMin, screenXMax, xMin, xMax),
      lerp(gl_FragCoord.y, screenYMin, screenYMax, yMin, yMax),
      0.,
      0.
    );
    vec4 y = #{expr};

    gl_FragColor = vec4(vec3(y.x), 1.);
  }
  """

  createProgramFromSrc(glod, name, vertex, fragment)

drawColorMapProgram = (glod, name, bounds) ->
  canvas = glod.canvas()

  glod.begin(name)

  glod.pack("quad", "position")

  glod.value("screenXMin", glod.viewport_.x)
  glod.value("screenXMax", glod.viewport_.x + glod.viewport_.w)
  glod.value("screenYMin", glod.viewport_.y)
  glod.value("screenYMax", glod.viewport_.y + glod.viewport_.h)

  glod.value("xMin", bounds.xMin)
  glod.value("xMax", bounds.xMax)
  glod.value("yMin", bounds.yMin)
  glod.value("yMax", bounds.yMax)

  glod.ready().triangles().drawArrays(0, 6)

  glod.end()






