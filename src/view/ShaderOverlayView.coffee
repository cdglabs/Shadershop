Glod = require("./plot/glod")


R.create "ShaderOverlayView",

  initializeGlod: ->
    @glod = new Glod()
    canvas = @getDOMNode()
    @glod.canvas(canvas, {antialias: true})

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
      rect = shaderEl.getBoundingClientRect()
      @glod.viewport(rect.left, canvas.height - rect.bottom, rect.width, rect.height)

      shaderView = shaderEl.dataFor
      plots = shaderView.plots
      bounds = shaderView.bounds

      numSamples = rect.width / config.resolution

      for plot in plots
        name = plot.exprString
        unless @programs[name]
          # console.log "creating program", name
          createCartesianProgram(@glod, name, name)
          @programs[name] = true
        usedPrograms[name] = true

        drawCartesianProgram(@glod, name, numSamples, plot.color, bounds)

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

createProgramFromSrc = (glod, name, vertex, fragment) ->
  Glod.preprocessed[name] = {name, fragment, vertex}

  delete glod._programs[name]
  glod.createProgram(name)


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

    vec4 x = vec4(lerp(s, 0., 1., xMin, xMax), 0., 0., 0.);
    vec4 y = #{expr};

    float px = lerp(x.x, xMin, xMax, -1., 1.);
    float py = lerp(y.x, yMin, yMax, -1., 1.);

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


bufferCartesianSamples = (glod, numSamples) ->
  samplesArray = []
  for i in [0..numSamples]
    samplesArray.push(i)

  if glod.hasVBO("samples")
    glod.deleteVBO("samples")

  glod
    .createVBO("samples")
    .bufferDataStatic("samples", new Float32Array(samplesArray))


drawCartesianProgram = (glod, name, numSamples, color, bounds) ->
  gl = glod.gl()
  gl.lineWidth(1.25)

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
