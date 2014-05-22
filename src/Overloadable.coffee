ERRORS =
  INVALID_OVERLOAD_SIGNATURE: "You should pass a nonempty array of arguments as a signature"
  INVALID_OVERLOAD_FUNCTION: "You should pass a function that will be assigned to set of arguments"
  NO_MATCHING_OVERLOADS: "No overloads matches given signature"
  INVALID_DEFAULT_FUNCTION: "If passed, argument defaultFunction must be a function"
  FUNCTION_NOT_EXTENSIBLE: "You cannot overload a non-extensible function"
  NO_SUCH_MATCHER: "That type of matcher doesn't exist"
  UNSUPPORTED_SIGNATURE_ELEMENT: "Tried to add overload with unsupported argument type"

class Utils
  @lockOwnProperties: (object) ->
    for own property of object
      Object.defineProperty(object, property,
        enumerable: false
        writable: false
        configurable: false)

  @getClassOf: (what) ->
    whatAsString = Object::toString.call(what)
    /\[object (\w+)\]/.exec(whatAsString)[1].toLowerCase()

class Overloadable
  @_inheritFromOverloadable: do ->
    if typeof Object.setPrototypeOf is "function"
      Object.setPrototypeOf(Overloadable.prototype, Function.prototype)

      return (overloadableFunction) ->
        Object.setPrototypeOf(overloadableFunction, Overloadable.prototype)
    else return (overloadableFunction) ->
      prototypeProperties = Object.getOwnPropertyNames(Overloadable.prototype)
      for property in prototypeProperties when property isnt "constructor"
        Object.defineProperty(overloadableFunction, property,
          value: Overloadable.prototype[property])

  constructor: (defaultFunction = null) ->
    if defaultFunction? and typeof defaultFunction isnt "function"
      throw new TypeError(ERRORS.INVALID_DEFAULT_FUNCTION)

    overloadableFunction = ->
      overloadableFunction._invoke(this, arguments...)

    overloadableFunction._overloads = []
    overloadableFunction._defaultFunction = defaultFunction;

    Utils.lockOwnProperties(overloadableFunction)

    Overloadable._inheritFromOverloadable(overloadableFunction)

    return overloadableFunction

  _invoke: (thisArg, passedArguments...) ->
    matchedFunction = @match(passedArguments...)
    return matchedFunction.apply(thisArg, passedArguments) if matchedFunction?

    throw new TypeError(ERRORS.NO_MATCHING_OVERLOADS)

  _getDefaultFunction: -> @_defaultFunction

  overload: (signature, functionToCall) ->
    unless Object.isExtensible(this)
      throw new TypeError(ERRORS.FUNCTION_NOT_EXTENSIBLE)

    unless Array.isArray(signature)
      throw new Error(ERRORS.INVALID_OVERLOAD_SIGNATURE)

    if typeof functionToCall isnt "function"
      throw new Error(ERRORS.INVALID_OVERLOAD_FUNCTION)

    overload = new Overload(signature, functionToCall)
    @_overloads.push(overload)

  match: (passedArguments...) ->
    for overload in @._overloads
      if overload.isSignatureMatchingArguments(passedArguments)
        return overload.getAssignedFunction()

    @_getDefaultFunction()

Utils.lockOwnProperties(Overloadable)
Utils.lockOwnProperties(Overloadable.prototype)

class Overload
  constructor: (signature, @_assignedFunction) ->
    compiledSignature = for signatureElement in signature
      try
        matcher = AbstractMatcher.getMatcher(signatureElement)
      catch e
        throw new TypeError(ERRORS.UNSUPPORTED_SIGNATURE_ELEMENT)
      matcher.compile(signatureElement)

    @_signature = compiledSignature

  getSignature: -> @_signature[..]

  getAssignedFunction: -> @_assignedFunction

  isSignatureMatchingArguments: (passedArguments) ->
    signature = @getSignature()
    return false unless passedArguments.length is signature.length

    for compiledMatcher, index in signature
      argument = passedArguments[index]
      return false unless compiledMatcher.match(argument)

    true


class MatcherFactory
  constructor: () ->
    @_matchers = Object.create(null)

  registerMatcher: (argumentClass, matcher) ->
    if @_matchers[argumentClass]? then throw new Error

    @_matchers[argumentClass] = matcher

  getMatcher: (argumentClass) ->
    unless @_matchers[argumentClass]? then throw new Error

    new @_matchers[argumentClass]()

matcherFactory = new MatcherFactory()

class AbstractMatcher
  @getMatcher: (argument) ->
    argumentClass = Utils.getClassOf(argument)
    matcherFactory.getMatcher(argumentClass)

  compile: (value) ->
    new CompiledMatcher(this, value)

class ClassMatcher extends AbstractMatcher
  match: (argument, overloadSignatureElement) ->
    Utils.getClassOf(argument) is overloadSignatureElement

  matcherFactory.registerMatcher("string", ClassMatcher)

class AlternativeMatcher extends AbstractMatcher
  match: (argument, overloadSignatureElement) ->
    for element in overloadSignatureElement
      matcher = AbstractMatcher.getMatcher(element)
      if matcher.match(argument, element) then return true

    false

  compile: (matcherValue) ->
    flattenedArray = @flattenArray(matcherValue)
    super(flattenedArray)

  flattenArray: (array) ->
    arrayCount = -1;
    flattenedArray = array

    while arrayCount isnt 0
      previousStepResult = flattenedArray
      arrayCount = 0
      flattenedArray = []
      for element in previousStepResult
        if Utils.getClassOf(element) is "array"
          flattenedArray.push(element...)
          arrayCount += 1
        else
          flattenedArray.push(element)

    flattenedArray

  matcherFactory.registerMatcher("array", AlternativeMatcher)

class InstanceofMatcher extends AbstractMatcher
  match: (argument, overloadSignatureElement) ->
    argument instanceof overloadSignatureElement

  matcherFactory.registerMatcher("function", InstanceofMatcher)

class RegExpMatcher extends AbstractMatcher
  match: (argument, overloadSignatureElement) ->
    overloadSignatureElement.test(argument)

  matcherFactory.registerMatcher("regexp", RegExpMatcher)

class PropertyMatcher extends AbstractMatcher
  @_INHERITED_PROPERTY_PREFIX: "^"
  match: (argument, overloadSignatureElement) ->
    for own property of overloadSignatureElement
      if property.charAt(0) is PropertyMatcher._INHERITED_PROPERTY_PREFIX
        propertyName = property.slice(1)
        hasProperty = propertyName of argument
      else
        propertyName = property
        hasProperty = Object.prototype.hasOwnProperty.call(argument, propertyName)

      if hasProperty isnt true then return false

      element = overloadSignatureElement[property]
      matcher = AbstractMatcher.getMatcher(element)
      unless matcher.match(argument[propertyName], element) then return false

    true

  matcherFactory.registerMatcher("object", PropertyMatcher)


class CompiledMatcher
  constructor: (@_matcher, @_value) ->

  getMatcher: () -> @_matcher

  getValue: () -> @_value

  match: (argument) -> @getMatcher().match(argument, @getValue())

@Overloadable = Overloadable