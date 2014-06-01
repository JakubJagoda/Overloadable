(function() {
  var AbstractMatcher, AlternativeMatcher, ClassMatcher, CompiledMatcher, ERRORS, InstanceofMatcher, MatcherFactory, Overload, Overloadable, PropertyMatcher, RegExpMatcher, Utils, matcherFactory,
    __hasProp = {}.hasOwnProperty,
    __slice = [].slice,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  ERRORS = {
    INVALID_OVERLOAD_SIGNATURE: "You should pass a nonempty array of arguments as a signature",
    INVALID_OVERLOAD_FUNCTION: "You should pass a function that will be assigned to set of arguments",
    NO_MATCHING_OVERLOADS: "No overloads match given signature",
    INVALID_DEFAULT_FUNCTION: "If passed, argument defaultFunction must be a function",
    FUNCTION_NOT_EXTENSIBLE: "You cannot overload a non-extensible function",
    NO_SUCH_MATCHER: "That type of matcher doesn't exist",
    UNSUPPORTED_SIGNATURE_ELEMENT: "Tried to add overload with unsupported argument type"
  };

  Utils = (function() {
    function Utils() {}

    Utils.lockOwnProperties = function(object) {
      var property, _results;
      _results = [];
      for (property in object) {
        if (!__hasProp.call(object, property)) continue;
        _results.push(Object.defineProperty(object, property, {
          enumerable: false,
          writable: false,
          configurable: false
        }));
      }
      return _results;
    };

    Utils.getClassOf = function(what) {
      var whatAsString;
      whatAsString = Object.prototype.toString.call(what);
      return /\[object (\w+)\]/.exec(whatAsString)[1].toLowerCase();
    };

    return Utils;

  })();

  Overloadable = (function() {
    Overloadable._inheritFromOverloadable = function(overloadableFunction) {
      var property, prototypeProperties, _i, _len, _results;
      prototypeProperties = Object.getOwnPropertyNames(Overloadable.prototype);
      _results = [];
      for (_i = 0, _len = prototypeProperties.length; _i < _len; _i++) {
        property = prototypeProperties[_i];
        if (property !== "constructor") {
          _results.push(Object.defineProperty(overloadableFunction, property, {
            value: Overloadable.prototype[property]
          }));
        }
      }
      return _results;
    };

    function Overloadable(defaultFunction) {
      var overloadableFunction;
      if (defaultFunction == null) {
        defaultFunction = null;
      }
      if ((defaultFunction != null) && typeof defaultFunction !== "function") {
        throw new TypeError(ERRORS.INVALID_DEFAULT_FUNCTION);
      }
      overloadableFunction = function() {
        return overloadableFunction._invoke.apply(overloadableFunction, [this].concat(__slice.call(arguments)));
      };
      overloadableFunction._overloads = [];
      overloadableFunction._defaultFunction = defaultFunction;
      Utils.lockOwnProperties(overloadableFunction);
      Overloadable._inheritFromOverloadable(overloadableFunction);
      return overloadableFunction;
    }

    Overloadable.prototype._invoke = function() {
      var matchedFunction, passedArguments, thisArg;
      thisArg = arguments[0], passedArguments = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      matchedFunction = this.match.apply(this, passedArguments);
      if (matchedFunction != null) {
        return matchedFunction.apply(thisArg, passedArguments);
      } else {
        throw new TypeError(ERRORS.NO_MATCHING_OVERLOADS);
      }
    };

    Overloadable.prototype._getDefaultFunction = function() {
      return this._defaultFunction;
    };

    Overloadable.prototype.overload = function(signature, functionToCall) {
      var overload;
      if (!Object.isExtensible(this)) {
        throw new TypeError(ERRORS.FUNCTION_NOT_EXTENSIBLE);
      }
      if (!Array.isArray(signature)) {
        throw new Error(ERRORS.INVALID_OVERLOAD_SIGNATURE);
      }
      if (typeof functionToCall !== "function") {
        throw new Error(ERRORS.INVALID_OVERLOAD_FUNCTION);
      }
      overload = new Overload(signature, functionToCall);
      return this._overloads.push(overload);
    };

    Overloadable.prototype.match = function() {
      var overload, passedArguments, _i, _len, _ref;
      passedArguments = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      _ref = this._overloads;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        overload = _ref[_i];
        if (overload.isSignatureMatchingArguments(passedArguments)) {
          return overload.getAssignedFunction();
        }
      }
      return this._getDefaultFunction();
    };

    return Overloadable;

  })();

  Utils.lockOwnProperties(Overloadable);

  Utils.lockOwnProperties(Overloadable.prototype);

  Overload = (function() {
    function Overload(signature, _assignedFunction) {
      var compiledSignature, e, matcher, signatureElement;
      this._assignedFunction = _assignedFunction;
      compiledSignature = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = signature.length; _i < _len; _i++) {
          signatureElement = signature[_i];
          try {
            matcher = AbstractMatcher.getMatcher(signatureElement);
          } catch (_error) {
            e = _error;
            throw new TypeError(ERRORS.UNSUPPORTED_SIGNATURE_ELEMENT);
          }
          _results.push(matcher.compile(signatureElement));
        }
        return _results;
      })();
      this._signature = compiledSignature;
    }

    Overload.prototype.getSignature = function() {
      return this._signature.slice(0);
    };

    Overload.prototype.getAssignedFunction = function() {
      return this._assignedFunction;
    };

    Overload.prototype.isSignatureMatchingArguments = function(passedArguments) {
      var argument, compiledMatcher, index, signature, _i, _len;
      signature = this.getSignature();
      if (passedArguments.length !== signature.length) {
        return false;
      }
      for (index = _i = 0, _len = signature.length; _i < _len; index = ++_i) {
        compiledMatcher = signature[index];
        argument = passedArguments[index];
        if (!compiledMatcher.match(argument)) {
          return false;
        }
      }
      return true;
    };

    return Overload;

  })();

  MatcherFactory = (function() {
    function MatcherFactory() {
      this._matchers = Object.create(null);
    }

    MatcherFactory.prototype.registerMatcher = function(argumentClass, matcher) {
      if (this._matchers[argumentClass] != null) {
        throw new Error;
      }
      return this._matchers[argumentClass] = matcher;
    };

    MatcherFactory.prototype.getMatcher = function(argumentClass) {
      if (this._matchers[argumentClass] == null) {
        throw new Error;
      }
      return new this._matchers[argumentClass];
    };

    return MatcherFactory;

  })();

  matcherFactory = new MatcherFactory();

  AbstractMatcher = (function() {
    function AbstractMatcher() {}

    AbstractMatcher.getMatcher = function(argument) {
      var argumentClass;
      argumentClass = Utils.getClassOf(argument);
      return matcherFactory.getMatcher(argumentClass);
    };

    AbstractMatcher.prototype.compile = function(value) {
      return new CompiledMatcher(this, value);
    };

    return AbstractMatcher;

  })();

  ClassMatcher = (function(_super) {
    __extends(ClassMatcher, _super);

    function ClassMatcher() {
      return ClassMatcher.__super__.constructor.apply(this, arguments);
    }

    ClassMatcher.prototype.match = function(argument, overloadSignatureElement) {
      return Utils.getClassOf(argument) === overloadSignatureElement;
    };

    matcherFactory.registerMatcher("string", ClassMatcher);

    return ClassMatcher;

  })(AbstractMatcher);

  AlternativeMatcher = (function(_super) {
    __extends(AlternativeMatcher, _super);

    function AlternativeMatcher() {
      return AlternativeMatcher.__super__.constructor.apply(this, arguments);
    }

    AlternativeMatcher.prototype.match = function(argument, overloadSignatureElement) {
      var element, matcher, _i, _len;
      for (_i = 0, _len = overloadSignatureElement.length; _i < _len; _i++) {
        element = overloadSignatureElement[_i];
        matcher = AbstractMatcher.getMatcher(element);
        if (matcher.match(argument, element)) {
          return true;
        }
      }
      return false;
    };

    AlternativeMatcher.prototype.compile = function(matcherValue) {
      var flattenedArray;
      flattenedArray = this.flattenArray(matcherValue);
      return AlternativeMatcher.__super__.compile.call(this, flattenedArray);
    };

    AlternativeMatcher.prototype.flattenArray = function(array) {
      var arrayCount, element, flattenedArray, previousStepResult, _i, _len;
      arrayCount = -1;
      flattenedArray = array;
      while (arrayCount !== 0) {
        previousStepResult = flattenedArray;
        arrayCount = 0;
        flattenedArray = [];
        for (_i = 0, _len = previousStepResult.length; _i < _len; _i++) {
          element = previousStepResult[_i];
          if (Utils.getClassOf(element) === "array") {
            flattenedArray.push.apply(flattenedArray, element);
            arrayCount += 1;
          } else {
            flattenedArray.push(element);
          }
        }
      }
      return flattenedArray;
    };

    matcherFactory.registerMatcher("array", AlternativeMatcher);

    return AlternativeMatcher;

  })(AbstractMatcher);

  InstanceofMatcher = (function(_super) {
    __extends(InstanceofMatcher, _super);

    function InstanceofMatcher() {
      return InstanceofMatcher.__super__.constructor.apply(this, arguments);
    }

    InstanceofMatcher.prototype.match = function(argument, overloadSignatureElement) {
      return argument instanceof overloadSignatureElement;
    };

    matcherFactory.registerMatcher("function", InstanceofMatcher);

    return InstanceofMatcher;

  })(AbstractMatcher);

  RegExpMatcher = (function(_super) {
    __extends(RegExpMatcher, _super);

    function RegExpMatcher() {
      return RegExpMatcher.__super__.constructor.apply(this, arguments);
    }

    RegExpMatcher.prototype.match = function(argument, overloadSignatureElement) {
      return overloadSignatureElement.test(argument);
    };

    matcherFactory.registerMatcher("regexp", RegExpMatcher);

    return RegExpMatcher;

  })(AbstractMatcher);

  PropertyMatcher = (function(_super) {
    __extends(PropertyMatcher, _super);

    function PropertyMatcher() {
      return PropertyMatcher.__super__.constructor.apply(this, arguments);
    }

    PropertyMatcher._INHERITED_PROPERTY_PREFIX = "^";

    PropertyMatcher.prototype.match = function(argument, overloadSignatureElement) {
      var element, hasProperty, matcher, property, propertyName;
      for (property in overloadSignatureElement) {
        if (!__hasProp.call(overloadSignatureElement, property)) continue;
        if (property.charAt(0) === PropertyMatcher._INHERITED_PROPERTY_PREFIX) {
          propertyName = property.slice(1);
          hasProperty = propertyName in argument;
        } else {
          propertyName = property;
          hasProperty = Object.prototype.hasOwnProperty.call(argument, propertyName);
        }
        if (hasProperty !== true) {
          return false;
        }
        element = overloadSignatureElement[property];
        matcher = AbstractMatcher.getMatcher(element);
        if (!matcher.match(argument[propertyName], element)) {
          return false;
        }
      }
      return true;
    };

    matcherFactory.registerMatcher("object", PropertyMatcher);

    return PropertyMatcher;

  })(AbstractMatcher);

  CompiledMatcher = (function() {
    function CompiledMatcher(_matcher, _value) {
      this._matcher = _matcher;
      this._value = _value;
    }

    CompiledMatcher.prototype.getMatcher = function() {
      return this._matcher;
    };

    CompiledMatcher.prototype.getValue = function() {
      return this._value;
    };

    CompiledMatcher.prototype.match = function(argument) {
      return this.getMatcher().match(argument, this.getValue());
    };

    return CompiledMatcher;

  })();

  if ((typeof define !== "undefined" && define !== null ? define.amd : void 0) != null) {
    define(function() {
      return Overloadable;
    });
  } else if ((typeof module !== "undefined" && module !== null ? module.exports : void 0) != null) {
    module.exports = Overloadable;
  } else {
    this.Overloadable = Overloadable;
  }

}).call(this);
