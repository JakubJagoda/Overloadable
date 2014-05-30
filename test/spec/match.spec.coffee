describe("Matching functions", ->
  overloadableFunc = null
  spiedFunction = jasmine.createSpy()

  beforeEach(->
    overloadableFunc = new Overloadable
    spiedFunction.reset()
  )

  it("should correctly match a function, basing on its arguments",->
    overloadableFunc.overload(["number"], spiedFunction)
    matchResult = overloadableFunc.match(1)
    expect(matchResult).toBe(spiedFunction)
  )

  it("should match proper function when there are more overloads",->
    overloadableFunc.overload([Array], ->)
    overloadableFunc.overload(["number"], spiedFunction)
    overloadableFunc.overload([/\w+/], ->)
    matchResult = overloadableFunc.match(1)
    expect(matchResult).toBe(spiedFunction)
  )

  it("should return null when there is no matching function", ->
    overloadableFunc.overload(["string"], spiedFunction)
    matchResult = overloadableFunc.match(1)
    expect(matchResult).toBe(null)
  )
)