num = numeric


# Given a vector a, return a unit vector in the same direction as a.
normalize = (a) ->
  return num.div(a, num.norm2(a))


# Given a unit vector n, return a matrix which performs the reflection in the
# hyperplane perpendicular to n.
reflectionMatrix = (n) ->
  # http://en.wikipedia.org/wiki/Householder_transformation
  # http://en.wikipedia.org/wiki/Transformation_matrix#Reflection_2
  I = num.identity(n.length)
  return num.sub(I, num.mul(2, num.dot(num.transpose([n]), [n])))


# Given unit vectors a and b, return a matrix which performs the simplest
# (most direct) rotation that takes a to b.
rotationMatrix = (a, b) ->
  # Geometric Algebra for Physicists pg 47, fig 2.10

  # n is the unit vector between a and b
  n = normalize(num.add(a, b))

  # First reflect perpendicular to n, then reflect perpendicular to b
  Rn = reflectionMatrix(n)
  Rb = reflectionMatrix(b)
  return num.dot(Rb, Rn)


# Given vectors a and b, return a matrix which performs the simplest rotation
# and scaling that takes a to b.
rotationScalingMatrix = (a, b) ->
  aUnit = normalize(a)
  bUnit = normalize(b)

  scaleFactor = num.norm2(b) / num.norm2(a)
  I = num.identity(a.length)
  S = num.mul(scaleFactor, I)

  R = rotationMatrix(aUnit, bUnit)
  return num.dot(S, R)



