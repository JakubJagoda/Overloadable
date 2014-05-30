describe("Overloading functions", ->
  overloadableFunc = null;

  beforeEach(->
    overloadableFunc = new Overloadable
  )

  it("should correctly overload a function when signature and function are provided", ->
    expect(->
      overloadableFunc.overload(["null"], ->)
    ).not.toThrow()
  )

  it("should not allow overloads on non-extensible object", ->
    Object.preventExtensions(overloadableFunc)

    expect(->
      overloadableFunc.overload(["null"], ->)
    ).toThrow()
  )

  it("should return current number of saved overloads", ->
    overloadableFunc.overload(["null"], ->)
    count = overloadableFunc.overload(["null"], ->)

    expect(count).toEqual(2)
  )

  it("should accept no arguments", ->
    expect(->
      overloadableFunc.overload([], ->)
    ).not.toThrow()
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
