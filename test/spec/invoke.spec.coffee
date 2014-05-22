describe("Invoking overloaded functions", ->
  overloadableFunction = null
  spiedFunction = jasmine.createSpy()

  describe("Default function", ->
    it("should throw error when called without any overloads and a default function", ->
      overloadableFunction = new Overloadable
      expect(overloadableFunction).toThrow()
    )

    it("should not throw error when called without any overloads but with a default function", ->
      overloadableFunction = new Overloadable(spiedFunction)
      expect(overloadableFunction).not.toThrow()
      expect(spiedFunction).toHaveBeenCalled()
    )

    it("should call the default function preserving this value", ->
      object = {}
      thisValues = [];

      defaultFunction = ->
        thisValues.push(this)

      defaultFunction.call(object)

      overloadableFunction = new Overloadable(defaultFunction)
      overloadableFunction.call(object)

      expect(thisValues[0]).toBe(thisValues[1])
    )

    it("should call the default function preserving original arguments list", ->
      overloadableFunction = new Overloadable(spiedFunction)
      overloadableFunction(7, true, "foo")

      expect(spiedFunction).toHaveBeenCalledWith(7, true, "foo")
    )
  )

  describe("No arguments", ->
    beforeEach(->
      overloadableFunction = new Overloadable
      spiedFunction.reset()
    )
    
    it("should allow for invoking and matching functions with no arguments", ->
      overloadableFunction.overload([], spiedFunction)
      overloadableFunction()
      expect(spiedFunction).toHaveBeenCalled()
    )
  )

  describe("String arguments", ->
    testedTypesAndExamples =
      number: 7
      boolean: true
      string: "foo"
      object: {}
      array: []
      function: ->
      regexp: /\./

    beforeEach(->
      overloadableFunction = new Overloadable
      spiedFunction.reset()
    )

    getOtherTypeThan = (type) ->
      types = Object.getOwnPropertyNames(testedTypesAndExamples)
      randomType = type

      while randomType is type
        randomType = types[Math.floor(Math.random() * types.length)]

      randomType

    for type, typeExample of testedTypesAndExamples
      do (type, typeExample) ->
        anotherType = getOtherTypeThan(type)
        anotherTypeExample = testedTypesAndExamples[anotherType]

        it("should match argument of type '#{type}'", ->
          overloadableFunction.overload([type], spiedFunction)
          overloadableFunction(typeExample)

          expect(spiedFunction).toHaveBeenCalled()
          expect(spiedFunction).toHaveBeenCalledWith(typeExample)
        )

        it("""shouldn't match argument of type '#{type}' when given argument of another type (randomly
                got '#{anotherType}')""", ->
          overloadableFunction.overload([type], spiedFunction)

          expect(->
            overloadableFunction(anotherTypeExample)
          ).toThrow()

          expect(spiedFunction).not.toHaveBeenCalled()
        )

        it("should choose correct signature when there are more than one", ->
          overloadableFunction.overload([type], spiedFunction)
          overloadableFunction.overload([anotherType], ->)

          overloadableFunction(typeExample)

          expect(spiedFunction).toHaveBeenCalled()
          expect(spiedFunction).toHaveBeenCalledWith(typeExample)
        )

    it("should not match if there are more arguments passed than were in the function signature", ->
      overloadableFunction.overload(["number"], ->)
      expect(->
        overloadableFunction(7, "foo")
      ).toThrow()
    )
  )

  describe("Array arguments", ->
    beforeEach(->
      overloadableFunction = new Overloadable
      spiedFunction.reset()
    )

    it("should recognize array arguments and use them as an alternative", ->
      overloadableFunction.overload([
        ["number", "string"]
      ], spiedFunction)

      overloadableFunction(1)
      overloadableFunction("a")

      expect(spiedFunction.callCount).toBe(2)
    )

    it("should deal with nested arrays", ->
      overloadableFunction.overload([
        ["number", ["string", "boolean"]]
      ], spiedFunction)

      overloadableFunction(1)
      overloadableFunction("a")
      overloadableFunction(true)

      expect(spiedFunction.callCount).toBe(3)
    )
  )

  describe("Function arguments", ->
    beforeEach(->
      overloadableFunction = new Overloadable
      spiedFunction.reset()
    )

    it("should recognize function arguments and use them as instanceof check", ->
      overloadableFunction.overload([Function], spiedFunction)
      overloadableFunction.overload([Array], spiedFunction)

      expect(->
        overloadableFunction(1)
      ).toThrow()

      overloadableFunction(->)
      overloadableFunction([])
      expect(spiedFunction.callCount).toBe(2)
    )
  )

  describe("RegExp arguments", ->
    beforeEach(->
      overloadableFunction = new Overloadable
      spiedFunction.reset()
    )

    it("should recognize regexp arguments and use them as regexp match check", ->
      overloadableFunction.overload([/\d+/], spiedFunction)

      expect(->
        overloadableFunction("a")
      ).toThrow()

      overloadableFunction("1")
      expect(spiedFunction.callCount).toBe(1)
    )

    it("should deal with other arguments than strings", ->
      overloadableFunction.overload([/\d+/], spiedFunction)

      expect(->
        overloadableFunction(1)
      ).not.toThrow()

      obj = {}
      obj.toString = ->
        "1"

      expect(->
        overloadableFunction(obj)
      ).not.toThrow()

      expect(spiedFunction.callCount).toBe(2)
    )
  )

  describe("Object arguments", ->
    beforeEach(->
      overloadableFunction = new Overloadable
      spiedFunction.reset()


      overloadableFunction.overload([
        foo: "boolean"
        bar: Array
        baz: [/\d+/, "number"]
      ], spiedFunction)
    )

    it("should recognize object arguments and use them as property check using other matchers", ->
      expect(->
        overloadableFunction(
          foo: true
          bar: []
          baz: 1
        )
      ).not.toThrow()

      expect(->
        overloadableFunction(
          foo: false
          bar: []
          baz: "1"
        )
      ).not.toThrow()

      expect(spiedFunction.callCount).toBe(2)
    )

    it("should throw when there's property missing", ->
      expect(->
        overloadableFunction(
          foo: true
        )
      ).toThrow()
    )

    it("should throw when properties don't match", ->
      expect(->
        overloadableFunction(
          foo: ""
          bar: []
          baz: 1
        )
      ).toThrow()
    )

    it("should check only own properties of objects", ->
      obj =
        foo: false
        bar: []
        baz: 1

      obj2 = Object.create(obj)

      expect(->
        overloadableFunction(obj2)
      ).toThrow()
    )

    it("should be able to check inherited properties, when preceeded by ^", ->
      overloadableFunction = new Overloadable
      overloadableFunction.overload([
        "^foo": "boolean"
        "^bar": Array
        "^baz": [/\d+/, "number"]
      ], spiedFunction)

      obj =
        foo: false
        bar: []
        baz: 1

      obj2 = Object.create(obj)

      expect(->
        overloadableFunction(obj2)
      ).not.toThrow()
    )
  )
)