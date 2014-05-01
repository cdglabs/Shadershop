'use strict';

module.exports = Glod;

function GlodError(message, data) {
  this.message = message;
  this.data = data;
}
GlodError.prototype = Object.create(Error.prototype);

function die(message, data) {
  var error = new GlodError(message || 'Glod: die', data);

  // try {
  //   throw new Error(message || 'die');
  // }
  // catch(err) {
  //   error = err;
  // }

  // var line = error.stack.split('\n')[3];
  // var at = line.indexOf('at ');
  // var origin = line.slice(at + 3, line.length);

  // error.name = 'at ' + origin;

  throw error;
}

function Glod() {
  // Prevent instantiation without new.
  if (!Glod.prototype.isPrototypeOf(this)) {
    die('Glod: instantiate with `new Glod()`')
  }

  this._canvas            = null;
  this._gl                = null;
  this._vbos              = {};
  this._fbos              = {};
  this._rbos              = {};
  this._programs          = {};
  this._textures          = {};
  this._extensions        = {};

  this._variables         = {};

  this._mode              = -1;
  this._activeProgram     = null;
  this._contextLost       = false;
  this._onContextLost     = this.onContextLost.bind(this);
  this._onContextRestored = this.onContextRestored.bind(this);
  this.loseContext        = null;
  this.restoreContext     = null;
  this._initIds           = {};
  this._allocIds          = {};
  this._versionedIds      = {};

  this._optional  = {};
  this._optionalv = {};

  this._state = 0;
}

Glod.preprocessed = {};

// this should probably be called "cache shader" or something like that
Glod.preprocess = function(source) {
  var line_re      = /\n|\r/;
  var directive_re = /^\/\/!\s*(.*)$/;

  var vertex   = [];
  var fragment = [];

  var lines = source.split(line_re);

  var name = null;

  var section = "common";

  for (var i = 0; i < lines.length; i++) {
    var line  = lines[i];
    var match = directive_re.exec(line);

    if (match) {
      var tokens = match[1].split(/\s+/);

      switch(tokens[0]) {
        case "name":     name    = tokens[1];  break;
        case "common":   section = "common";   break;
        case "vertex":   section = "vertex";   break;
        case "fragment": section = "fragment"; break;
        default: die('gl.preprocess: bad directive: ' + tokens[0]);
      }
    }

    switch(section) {
      case "common":   vertex.push(line); fragment.push(line); break;
      case "vertex":   vertex.push(line); fragment.push(''  ); break;
      case "fragment": vertex.push(''  ); fragment.push(line); break;
    }
  }

  var fragment_src = fragment.join('\n');
  var vertex_src   = vertex  .join('\n');

  name         || die('gl.preprocess: no name');
  vertex_src   || die('gl.preprocess: no vertex source: ' + name);
  fragment_src || die('gl.preprocess: no fragment source: ' + name);

  var o = {
    name:     name,
    vertex:   vertex_src,
    fragment: fragment_src
  };

  Glod.preprocessed[o.name] && die('Glod: duplicate shader name: '+ o.name);
  Glod.preprocessed[o.name] = o;
};

Glod.prototype.isInactive      = function() { return this._state === 0;     };
Glod.prototype.isPreparing     = function() { return this._state === 1;     };
Glod.prototype.isDrawing       = function() { return this._state === 2;     };
Glod.prototype.isProgramActive = function() { return !!this._activeProgram; };

Glod.prototype.startInactive  = function() { this._state = 0; return this; };
Glod.prototype.startPreparing = function() { this._state = 1; return this; };
Glod.prototype.startDrawing   = function() { this._state = 2; return this; };

Glod.prototype.assertInactive      = function() { this.isInactive()      || this.outOfPhase(0); return this; };
Glod.prototype.assertPreparing     = function() { this.isPreparing()     || this.outOfPhase(1); return this; };
Glod.prototype.assertDrawing       = function() { this.isDrawing()       || this.outOfPhase(2); return this; };
Glod.prototype.assertProgramActive = function() { this.isProgramActive() || this.outOfPhase(1); return this; };

Glod.prototype.outOfPhase = function(expected, actual) {
  function s(n) {
    return n === 0 ? 'inactive'  :
           n === 1 ? 'preparing' :
           n === 2 ? 'drawing'   :
                     'unknown (' + n + ')';
  }

  die('Glod: out of phase: expected to be ' + s(expected) + ' but was ' + s(this._state));
};


// todo: print string names and type instead of [object WebGLProgram]
// function throwOnGLError(err, funcName, args) {
//   throw WebGLDebugUtils.glEnumToString(err) + " was caused by call to: " + funcName;
// }

// function validateNoneOfTheArgsAreUndefined(functionName, args) {
//   for (var ii = 0; ii < args.length; ++ii) {
//     if (args[ii] === undefined) {
//       console.error("undefined passed to gl." + functionName + "(" +
//                     WebGLDebugUtils.glFunctionArgsToString(functionName, args) + ")");
//     }
//   }
// }

// function logGLCall(functionName, args) {
//   console.log("gl." + functionName + "(" +
//       WebGLDebugUtils.glFunctionArgsToString(functionName, args) + ")");
// }

// function logAndValidate(functionName, args) {
//   logGLCall(functionName, args);
//   validateNoneOfTheArgsAreUndefined (functionName, args);
// }


Glod.prototype.initContext = function() {
  var gl = this._gl;

  var supported = gl.getSupportedExtensions();

  for (var i = 0; i < supported.length; i++) {
    var name = supported[i];
    this._extensions[name] = gl.getExtension(name);
  }

  var lc = this.extension('WEBGL_lose_context');

  this.loseContext    = lc.loseContext.bind(lc);
  this.restoreContext = lc.restoreContext.bind(lc);
};

Glod.prototype.gl = function() {
  this._gl || die('Glod.gl: no gl context');
  return this._gl;
};

Glod.prototype.extension = function() {
  var l = arguments.length;
  for (var i = 0; i < l; i++) {
    var e = this._extensions[arguments[i]];
    if (e) return e;
  }
  die('Glod.extension: extension not found: ' + arguments);
};

Glod.prototype.canvas = function(canvas, options) {
  if (arguments.length === 0) {
    this.hasCanvas() || die('Glod.canvas: no canvas');
    return this._canvas;
  }

  if (this.hasCanvas()) {
    this._canvas.removeEventListener('webglcontextlost', this._onContextLost);
    this._canvas.removeEventListener('webglcontextrestored', this._onContextRestored);
  }

  this._canvas = canvas || null;

  if (canvas && !this.hasCanvas()) {
    die('Glod.canvas: bad canvas: ' + canvas);
  }

  if (this.hasCanvas()) {
    this._canvas.addEventListener('webglcontextlost', this._onContextLost);
    this._canvas.addEventListener('webglcontextrestored', this._onContextRestored);
    var opts = options || { antialias: false };
    var gl = this._canvas.getContext('webgl', options);
    gl || (gl = this._canvas.getContext('experimental-webgl', opts));
    gl || (die('Glod.canvas: failed to create context'));
    // wrap && (gl = WebGLDebugUtils.makeDebugContext(gl, throwOnGLError, logAndValidate));
    this._gl = gl;
    this.initContext();
  }
  else {
    this._gl = null;
  }

  return this;
};

Glod.prototype.hasCanvas = function() {
  return !!(this._canvas); // && this._canvas.length == 1);
};

Glod.prototype.hasVBO     = function(name) { return this._vbos    .hasOwnProperty(name); };
Glod.prototype.hasFBO     = function(name) { return this._fbos    .hasOwnProperty(name); };
Glod.prototype.hasRBO     = function(name) { return this._rbos    .hasOwnProperty(name); };
Glod.prototype.hasTexture = function(name) { return this._textures.hasOwnProperty(name); };
Glod.prototype.hasProgram = function(name) { return this._programs.hasOwnProperty(name); };

Glod.prototype.createVBO = function(name) {
  this.hasVBO(name) && die('Glod.createVBO: duplicate name: ' + name);
  this._vbos[name] = this.gl().createBuffer();
  return this;
};

Glod.prototype.createFBO = function(name) {
  this.hasFBO(name) && die('Glod.createFBO: duplicate resource name: ' + name);
  this._fbos[name] = this.gl().createFramebuffer();
  return this;
};

Glod.prototype.createRBO = function(name) {
  this.hasRBO(name) && die('Glod.createRBO: duplicate resource name: ' + name);
  this._rbos[name] = this.gl().createRenderbuffer();
  return this;
};

Glod.prototype.createTexture = function(name) {
  this.hasTexture(name) && die('Glod.createTexture: duplicate resource name: ' + name);
  this._textures[name] = this.gl().createTexture();
  return this;
};

Glod.prototype.deleteVBO = function(name) {
  var vbo = this.vbo(name);
  this.gl().deleteBuffer(vbo);
  delete this._vbos[name];
  return this;
};

var NRF = function(type, name) {
  die('Glod.' + type + ': no resource found: ' + name);
};

Glod.prototype.vbo     = function(name) { this.hasVBO(name) || NRF('vbo', name); return this._vbos[name]; };
Glod.prototype.fbo     = function(name) { this.hasFBO(name) || NRF('fbo', name); return this._fbos[name]; };
Glod.prototype.rbo     = function(name) { this.hasRBO(name) || NRF('rbo', name); return this._rbos[name]; };

Glod.prototype.program = function(name) {
  this.hasProgram(name) || NRF('program', name); return this._programs[name];
};

Glod.prototype.texture = function(name) {
  this.hasTexture(name) || NRF('texture', name); return this._textures[name];
};

Glod.prototype.onContextLost = function(e) {
  e.preventDefault();
  this._contextLost = true;
};

Glod.prototype.onContextRestored = function(e) {
  this._contextLost = false;

  var name;
  for (name in this._vbos    ) { delete this._vbos    [name]; this.createVBO    (name); }
  for (name in this._fbos    ) { delete this._fbos    [name]; this.createFBO    (name); }
  for (name in this._rbos    ) { delete this._rbos    [name]; this.createRBO    (name); }
  for (name in this._textures) { delete this._textures[name]; this.createTexture(name); }
  for (name in this._programs) { delete this._programs[name]; this.createProgram(name); }

  this.initContext();
  this._allocIds     = {};
  this._versionedIds = {};
};

Glod.prototype.createProgram = function(name) {
  name || die('bad program name: ' + name);

  var o = Glod.preprocessed[name];

  o          || die('Glod.createProgram: program not preprocessed: ' + name);
  o.name     || die('Glod.createProgram: no name specified');
  o.vertex   || die('Glod.createProgram: no vertex source');
  o.fragment || die('Glod.createProgram: no fragment source');

  name             = o.name;
  var vertex_src   = o.vertex;
  var fragment_src = o.fragment;

  this.hasProgram(name) && die('Glod.createProgram: duplicate program name: ' + name);

  var gl = this.gl();
  var program = gl.createProgram();
  this._programs[name] = program;

  function shader(type, source) {
    var s = gl.createShader(type);

    gl.shaderSource(s, source);
    gl.compileShader(s);

    if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) {
      var log = gl.getShaderInfoLog(s);
      console.log(log);
      die('Glod.createProgram: compilation failed', log);
    }

    gl.attachShader(program, s);
  }

  shader(gl.VERTEX_SHADER,   vertex_src);
  shader(gl.FRAGMENT_SHADER, fragment_src);

  for (var pass = 0; pass < 2; pass++) {
    gl.linkProgram(program);

    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      console.log(gl.getProgramInfoLog(program));
      die('Glod.createProgram: linking failed');
    }

    gl.validateProgram(program);
    if (!gl.getProgramParameter(program, gl.VALIDATE_STATUS)) {
      console.log(gl.getProgramInfoLog(program));
      die('Glod.createProgram: validation failed');
    }

    if (pass === 0) {
      var active = [];

      var activeAttributes = gl.getProgramParameter(program, gl.ACTIVE_ATTRIBUTES);
      for (var i = 0; i < activeAttributes; i++) {
        var info = gl.getActiveAttrib(program, i);
        var re = new RegExp('^\\s*attribute\\s+([a-z0-9A-Z_]+)\\s+' + info.name + '\\s*;', 'm');
        var sourcePosition = vertex_src.search(re);
        sourcePosition >= 0 || die('couldn\'t find active attribute "' + info.name + '" in source');
        active.push([info.name, sourcePosition]);
      }

      var layout = active.sort(function(a, b) { return a[1] > b[1]; })
                         .map (function(x   ) { return x[0];        });

      for (var i = 0; i < layout.length; i++) {
        gl.bindAttribLocation(program, i, layout[i]);
      }

      continue;
    }

    var variables = this._variables[name] = {};

    var addVariable = function(index, attrib) {
      var info = attrib ? gl.getActiveAttrib (program, i) :
                          gl.getActiveUniform(program, i);

      var name = info.name;

      variables[name] && die('Glod: duplicate variable name: ' + name);

      var location = attrib ? gl.getAttribLocation (program, name) :
                              gl.getUniformLocation(program, name) ;

      var type = info.type;

      var count = type === gl.BYTE           ? 1  :
                  type === gl.UNSIGNED_BYTE  ? 1  :
                  type === gl.SHORT          ? 1  :
                  type === gl.UNSIGNED_SHORT ? 1  :
                  type === gl.INT            ? 1  :
                  type === gl.UNSIGNED_INT   ? 1  :
                  type === gl.FLOAT          ? 1  :
                  type === gl.BOOL           ? 1  :
                  type === gl.SAMPLER_2D     ? 1  :
                  type === gl.SAMPLER_CUBE   ? 1  :

                  type === gl.  INT_VEC2     ? 2  :
                  type === gl.FLOAT_VEC2     ? 2  :
                  type === gl. BOOL_VEC2     ? 2  :

                  type === gl. INT_VEC3      ? 3  :
                  type === gl.FLOAT_VEC3     ? 3  :
                  type === gl. BOOL_VEC3     ? 3  :

                  type === gl.  INT_VEC4     ? 4  :
                  type === gl.FLOAT_VEC4     ? 4  :
                  type === gl. BOOL_VEC4     ? 4  :

                  type === gl.FLOAT_MAT2     ? 4  :
                  type === gl.FLOAT_MAT3     ? 9  :
                  type === gl.FLOAT_MAT4     ? 16 :
                  die('Glod: unknown variable type: ' + type);

      var matrix = type === gl.FLOAT_MAT2 || type === gl.FLOAT_MAT3 || type === gl.FLOAT_MAT4;

      var float = type === gl.FLOAT      ||
                  type === gl.FLOAT_VEC2 || type === gl.FLOAT_VEC3 || type === gl.FLOAT_VEC4 ||
                  type === gl.FLOAT_MAT2 || type === gl.FLOAT_MAT3 || type === gl.FLOAT_MAT4;

      variables[name] = {
        location: location,
        info:     info,
        attrib:   attrib,
        count:    count,
        float:    float,
        matrix:   matrix,
        ready:    false
      };
    }

    var activeUniforms = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS);
    for (var i = 0; i < activeUniforms; i++) addVariable(i, false);
    var activeAttributes = gl.getProgramParameter(program, gl.ACTIVE_ATTRIBUTES);
    for (var i = 0; i < activeAttributes; i++) addVariable(i, true);
  }

  var error = this.gl().getError();
  if (error !== 0) die('unexpected error: ' + error);

  return this;
};

Glod.prototype.variable = function(name) {
  this.assertProgramActive()
  var variable = this._variables[this._activeProgram][name];
  // TODO(ryan): Maybe add a flag for this? It can be useful to know when
  // variables are unused, but also annoying if you want to set them regardless.
  // variable || die('Glod.variable: variable not found: ' + name);
  return variable;
};

Glod.prototype.location = function(name) { return this.variable(name).location; };
Glod.prototype.info     = function(name) { return this.variable(name).info;     };
Glod.prototype.isAttrib = function(name) { return this.variable(name).attrib;   };

Glod.prototype.uploadCCWQuad = function() {
  var positions = new Float32Array([1, -1, 0, 1, 1, 1, 0, 1, -1, 1, 0, 1, -1, 1, 0, 1, -1, -1, 0, 1, 1, -1, 0, 1]);

  return function(name) {
    var gl = this.gl();
    gl.bindBuffer(gl.ARRAY_BUFFER, this.vbo(name));
    gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW);
    return this;
  };
}();

Glod.prototype.uploadPlaceholderTexture = function() {
  var rgba = new Uint8Array([255, 255, 255, 255, 0, 255, 255, 255, 255, 0, 255, 255, 255, 255, 0, 255]);

  return function(name) {
    var gl  = this.gl();
    var tex = this.texture(name);

    gl.bindTexture(gl.TEXTURE_2D, tex);
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, 1);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 2, 2, 0, gl.RGBA, gl.UNSIGNED_BYTE, rgba);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.bindTexture(gl.TEXTURE_2D, null);

    return this;
  };
}();

Glod.prototype.bindFramebuffer = function(name) {
  var fbo = name === null ? null : this.fbo(name);
  var gl = this.gl();
  gl.bindFramebuffer(gl.FRAMEBUFFER, fbo);
  return this;
};


// todo:
//   use the vbo's type to determine which target to bind it to
//   support stream and dynamic draw
//   support passing a normal JS array
Glod.prototype.bufferDataStatic = function(targetName) {
  var al  = arguments.length;
  var gl  = this.gl();
  var vbo = this.vbo(targetName);

  gl.bindBuffer(gl.ARRAY_BUFFER, vbo);

  var a;
  if (al === 2) {
    a = arguments[1];
    Array.prototype.isPrototypeOf(a) && (a = new Float32Array(a));
    gl.bufferData(gl.ARRAY_BUFFER, a, gl.STATIC_DRAW);
  }
  else if (al === 3) {
    a = arguments[1];
    Array.prototype.isPrototypeOf(a) && (a = new Float32Array(a));
    gl.bufferSubData(gl.ARRAY_BUFFER, a, arguments[2]);
  }
  else {
    die('Glod.bufferData: bad argument count: ' + al);
  }

  return this;
};

// todo:
//   support aperture base and opening
//   support scale factor
Glod.prototype.viewport = function() {
  var gl = this.gl();
  var x, y, w, h;

  var al = arguments.length;
  if (al === 4) {
    x = arguments[0];
    y = arguments[1];
    w = arguments[2];
    h = arguments[3];
  }
  else if (al === 0) {
    var canvas = this.canvas();
    x = y = 0;
    w = canvas.width;
    h = canvas.height;
  }
  else {
    die('Glod.viewport: bad argument count: ' + al);
  }

  gl.viewport(x, y, w, h);
  gl.scissor(x, y, w, h);

  return this;
}

Glod.prototype.begin = function(programName) {
  this.assertInactive().startPreparing();

  this.gl().useProgram(this.program(programName));

  this._activeProgram = programName;
  this._mode = -1;

  var variables = this._variables[programName];

  for (var name in variables) {
    variables[name].ready = false;
  }

  return this;
};

Glod.prototype.ready = function() {
  this.assertPreparing().startDrawing();

  var variables = this._variables[this._activeProgram];

  for (var name in variables) {
    var ov = this._optional[name];
    if (!variables[name].ready && ov) {
      switch(ov.length) {
        case 4: this.value(name, ov[0], ov[1], ov[2], ov[3]); break;
        case 3: this.value(name, ov[0], ov[1], ov[2]       ); break;
        case 2: this.value(name, ov[0], ov[1]              ); break;
        case 1: this.value(name, ov[0]                     ); break;
      }
    }

    variables[name].ready || die('Glod.ready: variable not ready: ' + name);
  }

  return this;
};

Glod.prototype.end = function() {
  this.assertDrawing().startInactive();
  this._activeProgram = null;
  return this;
};

Glod.prototype.manual = function() {
  this.assertProgramActive();
  for (var i = 0; i < arguments.length; i++) {
    this.variable(arguments[i]).ready = true;
  }
  return this;
};

Glod.prototype.value = function(name, a, b, c, d) {
  var v  = this.variable(name);

  // Bail if the variable does not exist.
  if (!v) return this;

  var gl = this.gl();
  var l  = arguments.length - 1;
  var loc = v.location;

  if (v.attrib) {
    l === 1 ? gl.vertexAttrib1f(loc, a         ) :
    l === 2 ? gl.vertexAttrib2f(loc, a, b      ) :
    l === 3 ? gl.vertexAttrib3f(loc, a, b, c   ) :
    l === 4 ? gl.vertexAttrib4f(loc, a, b, c, d) :
              die('Glod.value: bad length: ' + l);
  }
  else {
    var type = v.info.type;
    l === 1 ? (v.float ? gl.uniform1f(loc, a         ) : gl.uniform1i(loc, a         )) :
    l === 2 ? (v.float ? gl.uniform2f(loc, a, b      ) : gl.uniform2i(loc, a, b      )) :
    l === 3 ? (v.float ? gl.uniform3f(loc, a, b, c   ) : gl.uniform3i(loc, a, b, c   )) :
    l === 4 ? (v.float ? gl.uniform4f(loc, a, b, c, d) : gl.uniform4i(loc, a, b, c, d)) :
              die('Glod.value: bad length: ' + l);
  }
  v.ready = true;
  return this;
};

Glod.prototype.valuev = function(name, s, transpose) {
  s || die('Glod.valuev: bad vector: ' + s);

  var v = this.variable(name);

  // Bail if the variable does not exist.
  if (!v) return this;

  var gl = this.gl();
  var l = v.count;
  var loc = v.location;

  if (v.attrib) {
    l === s.length || die('Glod.valuev: bad vector length: ' + s.length);
    gl.disableVertexAttribArray(loc);
    l === 1 ? gl.vertexAttrib1fv(loc, s) :
    l === 2 ? gl.vertexAttrib2fv(loc, s) :
    l === 3 ? gl.vertexAttrib3fv(loc, s) :
    l === 4 ? gl.vertexAttrib4fv(loc, s) :
              die('Glod.valuev: bad length: ' + l);
  }
  else {
    if (v.matrix) {
      l === 4  ? gl.uniformMatrix2fv(loc, !!transpose, s) :
      l === 9  ? gl.uniformMatrix3fv(loc, !!transpose, s) :
      l === 16 ? gl.uniformMatrix4fv(loc, !!transpose, s) :
                 die('Glod.valuev: bad length: ' + l);
    }
    else {
      l === 1 ? (v.float ? gl.uniform1fv(loc, s) : gl.uniform1iv(loc, s)) :
      l === 2 ? (v.float ? gl.uniform2fv(loc, s) : gl.uniform2iv(loc, s)) :
      l === 3 ? (v.float ? gl.uniform3fv(loc, s) : gl.uniform3iv(loc, s)) :
      l === 4 ? (v.float ? gl.uniform4fv(loc, s) : gl.uniform4iv(loc, s)) :
                die('Glod.valuev: bad length: ' + l);
    }
  }

  v.ready = true;

  return this;
};

Glod.prototype.optional = function(name, a, b, c, d) {
  var l = arguments.length - 1;

  if (l === 1 && a === undefined) {
    delete this._optional[name];
    return this;
  }

  var v = this._optional[name] || [];
  this._optional[name] = v;
  v.length = l;

  switch (l) {
    case 4: v[3] = d;
    case 3: v[2] = c;
    case 2: v[1] = b;
    case 1: v[0] = a;
  }

  return this;
};

Glod.prototype.optionalv = function(name, s, transpose) {
  // WARNING: I'm not sure this actually works.
  if (arguments.length === 2 && s === undefined) {
    delete this._optionalv[name];
    return this;
  }

  var v = this._optionalv[name] || [];
  var l = s.length;
  this._optionalv[name] = v;
  v.length = s.length;
  v.TRANSPOSE = !!transpose;
  for (var i = 0; i < l; i++) {
    v[i] = s[i];
  }

  return this;
};

Glod.prototype.pack = function(vboName) {
  var vbo = this.vbo(vboName);
  var gl  = this.gl();

  gl.bindBuffer(gl.ARRAY_BUFFER, vbo);

  arguments.length < 2 && die('Glod.pack: no attribute provided');

  var stride = 0;
  var counts = [];
  var vars = [];
  for (var i = 1; i < arguments.length; i++) {
    var name = arguments[i];
    var v = this.variable(name);
    v.attrib || die('Glod.pack: tried to pack uniform: ' + name);
    v.ready  && die('Glod.pack: variable already ready: ' + name);
    var count = v.count;
    stride += count;
    counts.push(count);
    vars.push(v);
  }

  var offset = 0;
  for (var i = 1; i < arguments.length; i++) {
    var name = arguments[i];
    var v = vars[i - 1];
    var loc = v.location;
    gl.enableVertexAttribArray(loc);
    gl.vertexAttribPointer(loc, v.count, gl.FLOAT, false, stride * 4, offset * 4);
    offset += v.count;
    v.ready = true;
  }

  return this;
};

Glod.prototype.primitive = function(mode) {
  (mode >= 0 && mode <= 6) || die('Glod.mode: bad mode: ' + mode);
  this._mode = mode
  return this;
};

Glod.prototype.points        = function() { this._mode = this._gl.POINTS;         return this; };
Glod.prototype.lines         = function() { this._mode = this._gl.LINES;          return this; };
Glod.prototype.lineLoop      = function() { this._mode = this._gl.LINE_LOOP;      return this; };
Glod.prototype.lineStrip     = function() { this._mode = this._gl.LINE_STRIP;     return this; };
Glod.prototype.triangles     = function() { this._mode = this._gl.TRIANGLES;      return this; };
Glod.prototype.triangleStrip = function() { this._mode = this._gl.TRIANGLE_STRIP; return this; };
Glod.prototype.triangleFan   = function() { this._mode = this._gl.TRIANGLE_FAN;   return this; };

Glod.prototype.drawArrays = function(first, count) {
  var mode = this._mode;
  (mode >= 0 && mode <= 6) || die('Glod.drawArrays: mode not set');
  var gl = this.gl();
  gl.drawArrays(mode, first, count);
  return this;
};

Glod.prototype.clearColor   = function(r, g, b, a) { this.gl().clearColor  (r, g, b, a); return this; };
Glod.prototype.clearDepth   = function(d         ) { this.gl().clearDepth  (d         ); return this; };
Glod.prototype.clearStencil = function(s         ) { this.gl().clearStencil(s         ); return this; };

Glod.prototype.clearColorv = function(s) {
  return this.clearColor(s[0], s[1], s[2], s[3]);
};

Glod.prototype.clear = function(color, depth, stencil) {
  var gl = this.gl();

  var clearBits = 0;
  color   && (clearBits |= gl.  COLOR_BUFFER_BIT);
  depth   && (clearBits |= gl.  DEPTH_BUFFER_BIT);
  stencil && (clearBits |= gl.STENCIL_BUFFER_BIT);

  clearBits && gl.clear(clearBits);
  return this;
};

Glod.prototype.bindArrayBuffer = function(name) {
  var gl = this._gl;
  gl.bindBuffer(gl.ARRAY_BUFFER, this.vbo(name));
  return this;
};

Glod.prototype.bindElementBuffer = function(name) {
  var gl = this._gl;
  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.vbo(name));
  return this;
};

Glod.prototype.bindTexture2D = function(name) {
  var texture = name === null ? null : this.texture(name);
  var gl = this._gl;
  gl.bindTexture(gl.TEXTURE_2D, texture);
  return this;
};

Glod.prototype.activeTexture = function(unit) {
  var gl = this._gl;
  gl.activeTexture(gl.TEXTURE0 + unit);
  return this;
};

Glod.prototype.init = function(id, f) {
  this._initIds[id] || f();
  this._initIds[id] = true;
  return this;
};

Glod.prototype.alloc = function(id, f) {
  this._allocIds[id] || f();
  this._allocIds[id] = true;
  return this;
};

Glod.prototype.allocv = function(id, v, f) {
  if (this._versionedIds[id] !== v) {
    this._versionedIds[id] = v;
    f();
  }
  return this;
};
