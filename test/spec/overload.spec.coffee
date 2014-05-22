describe("Overloading functions", ->
  overloadableFunc = null;

  beforeEach(->
    overloadableFunc = new Overloadable();
  )

  it("should not allow for passing incorrect arguments to 'overload' function", ->
    expect(->
      overloadableFunc.overload()
    ).toThrow()

    expect(->
      overloadableFunc.overload([null])
    ).toThrow()

    expect(->
      overloadableFunc.overload([null], null)
    ).toThrow()
  )

  it("should not allow overloads on non-extensible object", ->
    expect(->
      overloadableFunc.overload(["null"], ->)
    ).not.toThrow()

    Object.preventExtensions(overloadableFunc)

    expect(->
      overloadableFunc.overload(["null"], ->)
    ).toThrow()
  )

  it("should accept string arguments", ->
    expect(->
      overloadableFunc.overload(["null"], ->)
    ).not.toThrow()
  )

  it("should accept array arguments", ->
    expect(->
      overloadableFunc.overload([
        ["null", "null"]
      ], ->)
    ).not.toThrow()
  )

  it("should accept function arguments", ->
    expect(->
      overloadableFunc.overload([Object], ->)
    ).not.toThrow()
  )

  it("should accept regexp arguments", ->
    expect(->
      overloadableFunc.overload([/\./], ->)
    ).not.toThrow()
  )

  it("should accept object arguments", ->
    expect(->
      overloadableFunc.overload([
        {}
      ], ->)
    ).not.toThrow()
  )
)
