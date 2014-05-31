#Overloadable
Not so big, yet easy to use and elegant JavaScript function overloading. Allows you to overload functions basing on: type of arguments,  what arguments are instance of, whether they match regexp, whether they have defined set of properties and more!

**Check [how to use it](#how-to-use-it) for more info about the usage.**

#Table of contents
- [Motivation](#motivation)
- [How to use it](#how-to-use-it)
    - [Creating overloadable functions](#creating-overloadable-functions)
    - [Function overloading](#function-overloading)
    - [Prevent further overloading](#prevent-further-overloading)
- [Matchers](#matchers)
    - [Class matcher](#class-matcher)
    - [Instanceof matcher](#instanceof-matcher)
    - [RegExp matcher](#regexp-matcher)
    - [Alternative matcher](#alternative-matcher)
    - [Property matcher](#property-matcher)
- [API](#api)
- [Future plans/wishes](#future-plans-wishes)
    - [Rule matcher](#rule-matcher)
    - [Open-ended signature](#open-ended-signature)
    - [Signature builder](#signature-builder)
    - [Same signature prevention](#same-signature-prevention)

#Motivation
If you have ever been writing a JavaScript code that you wanted to have as generic API as it could (*one method to make it all!*) but at the same time to be internally kept as a set of small, SRP-conforming functions, you probably encountered the obstacle that JavaScript doesn't support function overloading (which is what you may have expected from a loosely typed language). Function overloading was actually possible to achieve, but those functions had tendencies to grow and become harder and harder to maintain. Let's look at some example of a not-so-elegant overloading, done in native JS:

```JS
jQueer.fn.init = function (selector) {
    if (typeof selector === "string") {
        //maaany lines of code here, not pasted on purpose, to keep the example readable
    } else if (selector.nodeType) {
        this.context = this[0] = selector;
        this.length = 1;
        return this;
    } else if (jQueer.isFunction(selector)) {
        return typeof rootjQueer.ready !== "undefined" ?
            rootjQueer.ready(selector) :
            // Execute immediately if ready is not present
            selector(jQueer);
    } 
}
```

Kinda ugly, isn't it? The function is long (notice the comment about many lines of code), parameter names are mixed and don't relate to its roles (variable called `selector` is used with 3 different responsibilities, and its name matches only one of them) - this isn't good. But what if we could change this to something like that:

```JS
jQueer.fn.init = new Overloadable;
jQueer.fn.init.overload(["string"], function (selector) {
    //do something with string selector, get some nodes, etc
});

jQueer.fn.init.overload([HTMLElement], function (elementToWrap) {
    this.context = this[0] = elementToWrap;
    this.length = 1;
    return this;
});

jQueer.fn.init.overload(["function"], function (readyFunction) {
    return typeof rootjQueer.ready !== "undefined" ?
            rootjQueer.ready(readyFunction) :
            // Execute immediately if ready is not present
            readyFunction(jQueer);
});
```

That's quite better, you'll probably agree - one long function can be split into a set of smaller ones, parameters' names are correct and tell you exactly what they do (no longer `selector` which is not a selector), everyone's happy. So basically what you get from Overloadable is the ability to create functions (yeah, pure functions, no objects with `.call` or `.invoke` method) that can be easily overloaded and, when called, take care of invoking the proper overload, with the same set of arguments and `this` value.

#How to use it
This quick tutorial will help you to learn what Overloadable offers.

####Creating overloadable functions
In order to create an overloadable function just call `Overloadable` constructor. This constructor takes one optional parameter, the *defaultFunction*. This is the function that gets called, when arguments that you invoked your function with, don't match any overloads you set. If no default function was provided a `TypeError` will be thrown in such a situation.

```JS
var ov = new Overloadable;
ov();
//TypeError: No overloads matches given signature

var someFunc = function () { console.log("..."); };
var ov2 = new Overloadable(someFunc);
ov2();
//console: "..."
```

####Function overloading
The most essential part is the `overload` method. This method adds an *overload* to the overloadable function. An *overload* is a pair of signature (which tells Overloadable what arguments the overload expects) and function that will be called if arguments match the signature. The `overload` method takes 2 arguments, the signature and the function. Let's look at a simple example:

```JS
var ov = new Overloadable;
//okay, we have an overloadable function, let's add some overloads

//You probably don't know at this moment what signatures should consist of.
//Don't worry - we'll cover it later, the only thing you need to know now is that
//the first overload (the one we are about to add) will expect only one number argument
ov.overload(["number"], function(num) {
  console.log(num);
});

//and let's add another, this time expecting one string argument
ov.overload(["string"], function(str) {
  console.log("I got a string, but I can handle it!");
  console.log(str);
});

ov(1);
//console: 1

ov("foo");
//console: "I got string, but I can handle it!"
//console: "foo"
```

What happened? First, we created our overloadable function. Then we added an overload to it - we called `overload` method, passing a signature and a function, which basically tells 'hey, when you get such arguments that I described in the first argument, call the function that I passed as a second argument'. 

Signature is an array, in which the n-th element (called a *matcher*) describes the n-th invocation argument. This description bases both on the type and the value of the matcher. In the first overload we have only one matcher, of type string and value `"number"`. The string type means *Class Matcher* - it will check the type of an argument (more specifically, it'll check it's `[[Class]]` internal slot, hence the name). And this one, having value `"number"`, tells that this overload expects an argument, which `[[Class]]` internal slot is "number", so numbers and number wrappers. Class matchers aren't the only one, there are also other matchers, based on other JavaScript types, allowing you to do more detailed checks on arguments. You'll find more info about them in [matchers section](#matchers).

Let's back to the example, analogously we set up the second overload, this time expecting a string argument.

Next we call our overloadable function, what happens then? Well, basically it iterates over all its overloads (in the order they were defined), and tries to match invocation arguments against each saved signature (until it finds the one that matches the arguments). In the example the first invocation was done with argument `1`, so the function looked into its overloads, got the first one, and began to compare arguments to the signature. The only argument was `1`, the matcher for it was `"number"`, and since 1 is a number, this argument matched. This was the only passed argument, and the only one expected, so the iteration stopped adn the function that was assigned to the signature was called - "1" was written to the console. 

During the second call the situation was analogous, but this time argument `"foo"` didn't match signature `["number"]`. So the first function wasn't called, and the overloadable function proceeded to check its arguments against the second signature. This time there was a match - argument `"foo"` matched `["string"]` signature and the second function was called.

Pretty simple isn't it?

####Prevent further overloading
In order to block overloading, simply call `Object.preventExtensions` passing an overloadable function and no more overloads can be added to it.

```JS
var ov = new Overloadable;
ov.overload(["number"], function (num) {
    console.log(num);
});
ov.overload(["string"], function(str) {
    console.log("I got a string, but I can handle it!");
    console.log(str);
});

//block further overloading
Object.preventExtensions(ov);

//now if we try to overload, error will be thrown
ov.overload(["boolean"], function () {});
//TypeError: You cannot overload a non-extensible function

//overloads added before still work fine
ov(1);
//console: 1

ov("foo");
//console: "I got a string, but I can handle it!"
//console: "foo"
```

That's all you need to know about basic usage of Overloadable. Now let's go and find out how you can describe the invocation arguments using different matchers.

#Matchers
###Class matcher
####(type: string)
Class matcher gets argument's `[[Class]]` internal slot, normalizes it to lowercase, and checks against the value of the matcher. So for example

```JS
var someFunc = function () { /*...*/ };
var ov = new Overloadable;

ov.overload(["boolean"], someFunc);
```

`someFunc` will get called only if the only parameter passed to `ov` function has it's `[[Class]]` property set to `"boolean"` (the value of `[[Class]]` internal slot, as said before, is normalized by Overloadable to lowercase. The values that you pass to signature, however, are not, so please mind what you type because signature ["Boolean"] wouldn't match here). It means that `someFunc` will get called only after calling `ov` either with a boolean or a boolean wrapper object.

```JS
ov(true) //someFunc gets called
ov(new Boolean) //someFunc gets called
ov(null) //no match :( `[[Class]]` internal property of null is "Null"
```

###Instanceof matcher
####(type: function)
Instanceof matcher will perform `argument instanceof matcherValue` and returns its result. More info about `instanceof` operator and how it works you'll find [here](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/instanceof). Let's have an example:

```JS
var someFunc = function () { /*...*/ };
var ov = new Overloadable;

var MyConstructor = function () { /*...*/ }
ov.overload([MyConstructor], someFunc);
```

in this case, `someFunc` will get called only if `argument instanceof MyConstructor === true`

```JS
var obj = new MyConstructor();
ov(obj); //someFunc gets called, because `obj instanceof MyConstructor` returns true
var OtherConstructor = function () { /*...*/ }
var obj2 = new OtherConstructor();
ov(obj2); //no match this time, obj2 is an instance of OtherConstructor
```

###RegExp matcher
####(type: regexp)
RegExp matcher is a really simple one, all it does is checking whether the string representation of argument matches regular expression passed as the matcher value. It's literally `matcherValue.test(argument)`, simple as that. Note that `RegExp.prototype.test` function will automatically convert its argument to string.

```JS
var someFunc = function () { /*...*/ };
var ov = new Overloadable;

ov.overload([/^\d$/], someFunc);
```

`someFunc` will get called only after passing something that converted to string matches this regular expression, so

```JS
ov(1); //someFunc gets called (string representation of 1 is "1" and it matches)
ov("1"); //someFunc gets called
ov("11"); //no match - "11" doesn't match /^\d$/
```

###Alternative matcher
####(type: array)
Alternative matcher is an array of matchers and returns true if at least one of them returns true. Example will tell everything:

```JS
var someFunc = function () { /*...*/ };
var ov = new Overloadable;

ov.overload([["number", "string"]], someFunc);
```

`someFunc` will get called if `ov` gets either a number or a string.

```JS
ov(1); //someFunc gets called
ov("foo"); //someFunc gets called
ov(true); //no match - this is not a string nor a number so it doesn't conform
          //the alternative matcher we passed
```

and, of course, matchers don't have to be the same type, as it was shown in the previous example - we can mix them

```JS
var someFunc = function () { /*...*/ };
var ov = new Overloadable;

ov.overload([["array", Constructor, /\w+/]], someFunc);

ov([]); //someFunc gets called - argument is an array 
ov(new Constructor); //someFunc gets called - argument is an instance of Constructor
ov("foo"); //someFunc gets called - argument's string representation matches /\w+/
ov(1); //no match
```

###Property matcher
####(type: object)
When we define a property matcher, we expect that the corresponding argument:
- will have a property with the same name
- value of that property will conform the matcher of that property

If it sounds non-understandable, look at the example:

```JS
var someFunc = function () { /*...*/ };
var ov = new Overloadable;

ov.overload([{
    foo: Array,
    bar: [/\d+/, "number"]
}], someFunc);
```

we now set `ov` function, to accept an object that has at least two properties - foo and bar. But we don't want them just to be present, foo needs to conform Instanceof matcher (with value Array, so we need foo to be an instance of Array) and bar has to be either a number or, when converted to a string, has to match /\d+/ regexp.

```JS
ov({
    foo: [],
    bar: 1
});
//someFunc gets called, foo is an instance of Array and bar is a number, everything as expected

ov({
    foo: [],
    bar: 1,
    baz: true
});
//someFunc also gets called here, nothing prevents us from adding any additional properties.

ov({
    foo: []
});
//this time no match - we wanted our argument to have at least foo and bar properties.
//foo is present, but bar is missing

ov({
    foo: {},
    bar: "1"
});
//also no match - although both properties are present, foo doesn't conform its matcher,
//which expects it to be an instance of Array 
```

Those checked properties have to be the own properties of the argument, but you can tell the matcher to check also for inherited properties - just prefix their names with '^' character:

```JS
var someFunc = function () { /*...*/ };
var ov = new Overloadable;

ov.overload([{
    foo: "boolean",
}], someFunc);

var obj = {
    foo: true
};
var obj2 = Object.create(obj); //an object that has inherited foo property

ov(obj2); //no match, obj2 doesn't have own property foo

ov = new Overloadable;
ov.overload([{
    '^foo': "boolean",
}], someFunc);

ov(obj2); //this time everything works
```

#API
###new Overloadable(*[defaultFunction]*)

Creates and returns a new overloadable function.

| Argument | Type | Description
| --- | --- | ---
| defaultFunction (optional) | `(...any) => any` | will be called if the overloadable function invocation doesn't match any overload

**Returns** `(...any) => any` - an overloadable function

**Important note:** in ECMAScript, up to version 5, it is not possible to change the prototype of a function. In version 6, however, there is `Object.setPrototypeOf`, but it's currently considered to be a very slow operation. It means, that inheritance in case of overloadable functions will be done by simple copying properties from `Overloadable.prototype` to overloadable functions. Which also means, that `(new Overloadable) instanceof Overloadable` will be false! 

###Overloadable.prototype.overload(signature, functionToCall)

Adds a new overload to the overloadable function.

| Argument | Type | Description
| --- | --- | ---
| signature | `any[]` | an array consisting of various types of matchers, indicating signature of an overload
| functionToCall | `(...any) => any` | a function that will be called if invocation of overloadable function matches a signature

**Returns** `number` - actual number of saved overloads

###Overloadable.prototype.match(args...)

Returns a function that matches given set of arguments or default function, if there was no match. You can pass any number of arguments, of any type.

| Argument | Type | Description
| --- | --- | ---
| ... | `any` | any argument

**Returns** `(...any) => any` - function which signature matches given arguments <br>
**Returns** `null` - if no function matches and no default function was set

#Future plans/wishes
Here are listed some ideas that are to be further considered. Please note that they can make it to the master but they don't have to - it may turn out for some of them that they are stupid, impossible to be done or whatever else which blocks them from being ever implemented.

###Rule matcher
This is an extension to the property matcher - technically this also is an object matcher. The main idea is to make the matcher recognize special properties, that actually won't be expected to be present in argument, but which will invoke some custom functions. Those special properties will differ from ordinary ones by a prefix (which can be changed by user, default "__" (two underscores)). For example passing an object matcher with `__proto` property won't cause search for that property in argument, but will check if argument has specified prototype.

```JS
var ov = new Overloadable;
ov.overload([{
    proto: "null"
}], function () {});
//this matcher is a regular property matcher, it will check whether argument has
//property named "proto", which value is of null type

var ov = new Overloadable;
ov.overload([{
    __proto: null
}], function () {});
//this matcher, however, won't check for any properties. Instead it will check if the
//argument's prototype is null

//nothing stops us actually from mixing the matchers
ov.overload([{
    __proto: null,
    proto: "null"
}], function () {});
//this one will perform both checks - if argument has property "proto" of null type
//and if argument's prototype is null
```

Please note the difference in how those special "__" properties (called rules) treats its values. The regular properties uses their values as matchers (as we saw before and in the first example moment ago, where `proto: "null"` meant class matcher), whereas functions that implement rules get the exact rule value (so in the example, there is a function that implements "proto" rule and it will get `null` passed).

Overloadable will provide some predefined set of rules, ie:
- proto (check whether rule value is argument's prototype)
- isProtoOf (checks whether argument is a prototype of rule value)
- isA (checks whether argument === ruleValue)
- eqeq (similar to above, but with double equality operator)
- equals (similar to Jasmine toEqual matcher)
- instanceOf (same as instance matcher)
- regexp (same as regexp matcher)
- type (same as class matcher)
- typeOf (performs `typeof argument === ruleValue`)
- and maybe more?

Overloadable will also provide the ability to add custom rules. For example if we wanted to add a rule that checks if argument is a function that has n declared arguments (we can check it by `length` property) we would write:

```JS
Overloadable.addRule("nArgsFunction", function (utils) {
    //the first argument will be a special object providing things that may
    //be useful for rule checking, eg. argument, rule value, or access to matchers

    //the other approach is injecting, known from angular, but please note
    //that it's based on a non-standard behaviour, so I'm not fully for it
    var functionToCheck = utils.argument;
    var expectedDeclaredArgsCount = utils.value;

    return typeof functionToCheck === "function" && functionToCheck.length === expectedDeclaredArgsCount;
});

//and usage:
var ov = new Overloadable;
ov.overload([{
    __nArgFunction: 3
}], function () {});

ov(function(a,b,c) {}); //this will match, the parameter function has 3 declared arguments
ov(function(a,b) {}); //this won't
```

Note that we can write rules that won't even use the value that is passed to rule, but some value has to be passed in order to conform object literal notation. In this situation pass whatever, I myself find null to be the nicest choice. For example let's turn our "nArgsFunction" to "oneArgFunction":

```JS
Overloadable.addRule("oneArgFunction", function (utils) {
    var functionToCheck = utils.argument;

    return typeof functionToCheck === "function" && functionToCheck.length === 1;
});

var ov = new Overloadable;
ov.overload([{
    __nArgFunction: null //pass whatever here since we don't even use the value
}], function () {});
```

###Open-ended signature
The idea is to allow for adding overloads, in which we do not specify strictly the number of arguments (now when you define a signature with 3 elements, the matching invocation must have 3 arguments), but specify only maximum amount of expected arguments. This can be helpful when defining functions with ES6's rest parameters.

If we liked to create such signature, we would then pass a matcher (although it probably wouldn't be technically implemented as a matcher) which type is number. The value of that matcher would tell the maximum count of arguments that we expect in function invocation. Let's see it in action.

```JS
var someFunc = function () { /*...*/ };
var ov = new Overloadable;
ov.overload(["string", 3], someFunc); 
//here we are telling that after some string argument, ov will expect from one
//up to three rest arguments - they can be any arguments

var someFunc = function(arg1, ...restArg) { /* ... */ }
//note that rest parameter was used here. This is a feature of ES6 and is not
//available in the versions before the 6th

ov("whatever"); //no match, we wanted at least one rest argument

ov("whatever", 1, 2); //this time invocation matched, we passed two rest arguments
//which, since we used ES6's rest parameter, will be available in restArg array

ov("whatever", 1, 2, 3, 4); //again no match, we limited rest arguments only to 3
```

If you don't want to limit count of rest arguments, simply pass `Infinity` to the signature.
There is also a proposition to distinct between positive and negative numbers, and one would mean 0..X rest arguments, whereas the other 1..X rest arguments (as it was shown in the example) but this solution isn't the best in my opinion.

###Signature builder
Since signatures are now described by mixing various JavaScript types & values, it may be sometimes hard to read those signature. So the idea is to add a builder, to improve readability. This builder will work basing on chaining functions describing arguments. Its result will be a ready-to-use signature.  This could be its syntax:

```JS
var signature = Overloadable
    .signatureBuilder(3) 
    //this call would set up a new signature, its argument would be expected count of arguments
    //the second parameter could be also count of rest arguments
    .argument(1) 
    //we proceed to describe the first argument
        .ofType("number")
        .or()
        .matchingRegExp(/\d+/)
        .end() 
    //we told that the first argument can be either a number or has numeric string representation
    .argument(2) //now the second argument
        .instanceOf(Object)
        .and() 
        //and() would automatically result in a rule matcher, there is no other way to make conjunction
        .hasOwnProperty("length")
        //since this will create property matcher, we now have to describe the property. This
        //means all chained invocations from now, up to the next end(), will describe that property
            .ofType("number")
            .end() 
        //now we're back to describing the second argument
        .end() //but we have nothing more to add
    .argument(3)
        .hasProto(null)
        .isProtoOf(someObject)
        .end()
    .end() //final end call will compile the signature

//this has the same effect as if we wrote:
signature = [["number", /\d+/], {
    __instanceOf: Object,
    length: "number"
}, {
    __proto: null,
    __isProtoOf: someObject
}];
```

The builder is much more typing (although I do believe people haven't stuck in medieval and use editors with syntax completion. Very helpful would be those with intelligent syntax completion, like WebStorm or Visual Studio.), but it's also much more readable. However, functions should not have such strict signatures which would result in completely unreadable signatures definition, so this is the idea that needs further thinking.

###Same signature prevention
Currently if you add a signature, that is identical to some that you already added, nothing happens. I.e. this signature is added and will never be matched (because the previous one always will). The idea is to add a feature, that would warn the user if the overload they want to add already exists in function overloads.
```JS
var someFunc = function () { /*...*/ };
var ov = new Overloadable;
ov.overload(["string"], someFunc);

ov.overload(["string"], someFunc);
//Error: Signature ["string"] already exists
//(or it could just have no effect in non-strict mode)
```

This would also recognize rules matchers which have the same effects as standard matchers

```JS
var someFunc = function () { /*...*/ };
var ov = new Overloadable;
ov.overload(["string"], someFunc);

ov.overload([{
    __type: "string"
}], someFunc);
//Error
```

Another case is that you would also get noticed, if this function detects shadowing, ie. if you add less detailed signature and more detailed one after, for example:
```JS
var someFunc = function () { /*...*/ };
var ov = new Overloadable;
ov.overload(["object"], someFunc);

ov.overload([{
    __type: "object",
    "foo", "number"
}], someFunc);
//Error - despite these signatures aren't identical, the latter is shadowed by 
//the former (it'll never be reached, since all objects would match the former)
```