Glod = require("./glod")


R.create "ShaderCartesianView",
  propTypes:
    bounds: Object
    plots: Array # [{exprString, color}]

  initialize: ->
    @_glod = new Glod()
    canvasEl = @getDOMNode()
    rect = canvasEl.getBoundingClientRect()
    canvasEl.width = rect.width
    canvasEl.height = rect.height
    @_glod.canvas(canvasEl, {antialias: true})

    @_numSamples = rect.width / config.resolution
    bufferCartesianSamples(@_glod, @_numSamples)

    @_programs = {}

  getName: (plot, i) ->
    return "p"+i

  draw: ->
    for plot, i in @plots
      name = @getName(plot, i)

      unless @_programs[name] == plot.exprString
        createCartesianProgram(@_glod, name, plot.exprString)
        @_programs[name] = plot.exprString

    for plot, i in @plots
      name = @getName(plot, i)
      drawCartesianProgram(@_glod, name, @_numSamples, plot.color, @bounds)


  componentDidMount: ->
    @initialize()
    @draw()

  componentDidUpdate: ->
    @draw()

  shouldComponentUpdate: ->
    return true

  render: ->
    R.canvas {}


# =============================================================================

createProgramFromSrc = (glod, name, vertex, fragment) ->
  Glod.preprocessed[name] = {name, fragment, vertex}

  delete glod._programs[name]
  glod.createProgram(name)


createCartesianProgram = (glod, name, expr) ->

  vertex = """
  precision highp float;
  precision highp int;

  attribute vec4 sample;
  uniform float xMin;
  uniform float xMax;
  uniform float yMin;
  uniform float yMax;

  float lerp(float x, float dMin, float dMax, float rMin, float rMax) {
    float ratio = (x - dMin) / (dMax - dMin);
    return ratio * (rMax - rMin) + rMin;
  }

  void main() {
    float x = lerp(sample.x, 0., 1., xMin, xMax);
    float y = #{expr};

    float px = lerp(x, xMin, xMax, -1., 1.);
    float py = lerp(y, yMin, yMax, -1., 1.);

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
    x = i / numSamples
    samplesArray.push(x, 0, 0, 1)

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

  glod.ready().lineStrip().drawArrays(0, numSamples)

  glod.end()








