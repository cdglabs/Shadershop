util.vector = vector = {}

zipWith = (f, a, b) ->
  result = []
  for aItem, index in a
    bItem = b[index]
    result.push(f(aItem, bItem))
  return result

add = (x, y) ->
  return null unless x? and y?
  return x + y

sub = (x, y) ->
  return null unless x? and y?
  return x - y

vector.add = (a, b) ->
  zipWith(add, a, b)

vector.sub = (a, b) ->
  zipWith(sub, a, b)

merge = (original, extension) ->
  if extension? then extension else original

vector.merge = (original, extension) ->
  zipWith(merge, original, extension)
