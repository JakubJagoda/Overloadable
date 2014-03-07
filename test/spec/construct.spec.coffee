describe "Library constructor", ->
    overloadableFunc = null;

    beforeEach ->
        overloadableFunc = new Overloadable();

    it "Should construct a function", ->
        expect(typeof overloadableFunc).toBe "function"

    it "Should have overload property, also a function", ->
        expect(typeof overloadableFunc.overload).toBe "function"

