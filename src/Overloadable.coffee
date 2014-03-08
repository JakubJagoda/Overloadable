Overloadable = (defaultFunction) ->
    unless typeof defaultFunction is "function" or typeof defaultFunction is "undefined"
    	throw new TypeError "If passed, argument defaultFunction must be a function"
    
    signaturesContainer = []
    overloadableFunction = ->
        invoke.call this, signaturesContainer, arguments, defaultFunction
        
    overloadableFunction.overload = overload.bind signaturesContainer
    overloadableFunction.getDefault = ->
        defaultFunction
    
    overloadableFunction
    
Overloadable.getClassOf = (what) ->
    Object::toString
        .call(what)
        .match(/\[object (\w+)\]/)[1]
        .toLowerCase();

#overload is always bound to a signature container of an overloadable function
overload = (argumentsList, functionToCall) ->
    @push { argumentsList, functionToCall }

invoke = (signaturesContainer, invocationArguments, defaultFunction) ->
    argumentsList = Array::slice.call invocationArguments, 0
    
    matchedFunction = getFunctionMatchingArgumentsList signaturesContainer, argumentsList
    return matchedFunction.apply(this, argumentsList) if matchedFunction?
    
    return defaultFunction.apply(this, argumentsList) if defaultFunction?
    
    throw new Error "No overloaded signatures matches this one: #{argumentsList}"
    
getFunctionMatchingArgumentsList = (signaturesContainer, argumentsList) ->
    for signature in signaturesContainer
        matchingResult = isSignatureMatchingArgumentsList signature.argumentsList, argumentsList
        return signature.functionToCall if matchingResult is true
        
     null
        
isSignatureMatchingArgumentsList = (signatureArgumentsList, argumentsList) -> 
    for signatureArgument, i in signatureArgumentsList
        return false if signatureArgument isnt Overloadable.getClassOf argumentsList[i]
        
    true

@Overloadable = Overloadable
