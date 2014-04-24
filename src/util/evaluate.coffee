evaluate = (jsString) ->
  eval(jsString)

evaluateFn = (exprString) ->
  evaluate("(function (x) { return #{@exprString}; })")



identity = (a) -> a

add = (a, b) -> a + b
sub = (a, b) -> a - b
mul = (a, b) -> a * b
div = (a, b) -> a / b

abs = Math.abs
fract = (a) -> a - Math.floor(a)
floor = Math.floor
ceil = Math.ceil

min = Math.min
max = Math.max

sin = Math.sin
cos = Math.cos
sqrt = Math.sqrt
pow = (a, b) -> Math.pow(Math.abs(a), b)




util.evaluate = evaluate
util.evaluateFn = evaluateFn