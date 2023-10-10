// Zig’s if statements only accept bool values (i.e. true or false). There is no concept of truthy or falsy values.

const expect = @import("std").testing.expect;

test "if statement" {
    const a = true;
    var x: u16 = 0;
    if (a) {
        x += 1;
    } else {
        x += 2;
    }
    try expect(x == 1);
}

// If statements also work as expressions.
test "if statement expression" {
    const a = true;
    var x: u16 = 0;
    x += if (a) 1 else 2;
    try expect(x == 1);
}

//While
//Zig’s while loop has three parts - a condition, a block and a continue expression.

//Without a continue expression.
test "while" {
    var i: u8 = 2;
    while (i < 100) {
        i *= 2;
    }
    try expect(i == 128);
}

//With a continue expression.
test "while with continue expression" {
    var sum: u8 = 0;
    var i: u8 = 1;
    while (i <= 10) : (i += 1) {
        sum += i;
    }
    try expect(sum == 55);
}

// With a continue
test "while with continue" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) continue;
        sum += i;
    }
    try expect(sum == 4);
}

// With a break
test "while with break" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) break;
        sum += i;
    }
    try expect(sum == 1);
}

// FOR
test "for" {
    //character literals are equivalent to integer literals
    const string = [_]u8{ 'a', 'b', 'c' };

    for (string, 0..) |character, index| {
        _ = character;
        _ = index;
    }

    for (string) |character| {
        _ = character;
    }

    for (string, 0..) |_, index| {
        _ = index;
    }

    for (string) |_| {}
}

// FUNCTIONS
// All functions arguments are immutable

fn addFive(x: u32) u32 {
    return x + 5;
}

test "function" {
    const y = addFive(0);
    try expect(@TypeOf(y) == u32);
    try expect(y == 5);
}

//Recursion is allowed:
fn fibonacci(n: u16) u16 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "function recursion" {
    const x = fibonacci(10);
    try expect(x == 55);
}
//Values can be ignored using _ instead of a variable or const declaration. This does not work at the global scope (i.e. it only works inside functions and blocks) and is useful for ignoring the values returned from functions if you do not need them.

// DEFER
// defer is used to execute a statment while exiting the current block
test "defer" {
    var x: i16 = 5;
    {
        defer x += 2;
        try expect(x == 5);
    }
    try expect(x == 7);
}

//When there are multiple defers in a single block, they are executed in reverse order.
test "multi defer" {
    var x: f32 = 5;
    {
        defer x += 2;
        defer x /= 2;
    }
    try expect(x == 4.5);
}

//Errors #
//An error set is like an enum (details on Zig’s enums later), where each error in the set is a value. There are no exceptions in Zig; errors are values. Let’s create an error set.
const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};

//Error sets coerce to their supersets.

const AllocationError = error{OutOfMemory};

test "coerce error from a subset to a superset" {
    const err: FileOpenError = AllocationError.OutOfMemory;
    try expect(err == FileOpenError.OutOfMemory);
}

// An error set type and another type can be combined with the ! operator to form an error union type. Values of these types may be an error value or a value of the other type.
test "error union" {
    const maybe_error: AllocationError!u16 = 10;
    const no_error = maybe_error catch 0;

    try expect(@TypeOf(no_error) == u16);
    try expect(no_error == 10);
}

//Functions often return error unions. Here’s one using a catch, where the |err| syntax receives the value of the error. This is called payload capturing, and is used similarly in many places. We’ll talk about it in more detail later in the chapter. Side note: some languages use similar syntax for lambdas - this is not true for Zig.
fn failingFunction() error{Oops}!void {
    return error.Oops;
}

test "returning an error" {
    failingFunction() catch |err| {
        try expect(err == error.Oops);
        return;
    };
}

fn failFn() error{Oops}!i32 {
    try failingFunction();
    return 12;
}

test "try" {
    var v = failFn() catch |err| {
        try expect(err == error.Oops);
        return;
    };
    try expect(v == 12); // is never reached
}

//errdefer works like defer, but only executing when the function is returned from with an error inside of the errdefer’s block.
var problems: u32 = 98;

fn failFnCounter() error{Oops}!void {
    errdefer problems += 1;
    try failingFunction();
}

test "errdefer" {
    failFnCounter() catch |err| {
        try expect(err == error.Oops);
        try expect(problems == 99);
        return;
    };
}

//Error unions returned from a function can have their error sets inferred by not having an explicit error set. This inferred error set contains all possible errors that the function may return.

fn createFile() !void {
    return error.AccessDenied;
}

test "inferred error set" {
    //type coercion successfully takes place
    const x: error{AccessDenied}!void = createFile();

    //Zig does not let us ignore error unions via _ = x;
    //we must unwrap it with "try", "catch", or "if" by any means
    _ = x catch {};
}

//Error sets can be merged.

const A = error{ NotDir, PathNotFound };
const B = error{ OutOfMemory, PathNotFound };
const C = A || B;
//anyerror is the global error set, which due to being the superset of all error sets, can have an error from any set coerced to it. Its usage should be generally avoided.

//SWITCH
//Zig’s switch works as both a statement and an expression. The types of all branches must coerce to the type which is being switched upon. All possible values must have an associated branch - values cannot be left out. Cases cannot fall through to other branches.
test "switch statement" {
    var x: i8 = 10;
    switch (x) {
        -1...1 => {
            x = -x;
        },
        10, 100 => {
            //special considerations must be made
            //when dividing signed integers
            x = @divExact(x, 10);
        },
        else => {},
    }
    try expect(x == 1);
}

test "switch expression" {
    var x: i8 = 10;
    x = switch (x) {
        -1...1 => -x,
        10, 100 => @divExact(x, 10),
        else => x,
    };
    try expect(x == 1);
}

//RUNTIME SAFETY
//Zig provides a level of safety, where problems may be found during execution. Safety can be left on, or turned off. Zig has many cases of so-called detectable illegal behaviour, meaning that illegal behaviour will be caught (causing a panic) with safety on, but will result in undefined behaviour with safety off. Users are strongly recommended to develop and test their software with safety on, despite its speed penalties.

//For example, runtime safety protects you from out of bounds indices.
// test "out of bounds" {
//     const a = [3]u8{ 1, 2, 3 };
//     var index: u8 = 5;
//     const b = a[index];
//     _ = b;
// }

//The user may disable runtime safety for the current block using the built-in function @setRuntimeSafety.

test "out of bounds, no safety" {
    @setRuntimeSafety(false);
    const a = [3]u8{ 1, 2, 3 };
    var index: u8 = 5;
    const b = a[index];
    _ = b;
}

//POINTERS
//Normal pointers in Zig cannot have 0 or null as a value. They follow the syntax *T, where T is the child type.
//Referencing is done with &variable, and dereferencing is done with variable.*.
fn increment(num: *u8) void {
    num.* += 1;
}

test "pointers" {
    var x: u8 = 1;
    increment(&x);
    try expect(x == 2);
}
//Trying to set a *T to the value 0 is detectable illegal behaviour.
//Zig also has const pointers, which cannot be used to modify the referenced data. Referencing a const variable will yield a const pointer.

//POINTER SIZED INTEGERS
//usize and isize are given as unsigned and signed integers which are the same size as pointers.
test "usize" {
    try expect(@sizeOf(usize) == @sizeOf(*u8));
    try expect(@sizeOf(isize) == @sizeOf(*u8));
}

//SLICES
//Slices can be thought of as a pair of [*]T (the pointer to the data) and a usize (the element count). Their syntax is []T, with T being the child type. Slices are used heavily throughout Zig for when you need to operate on arbitrary amounts of data. Slices have the same attributes as pointers, meaning that there also exists const slices. For loops also operate over slices. String literals in Zig coerce to []const u8.
//Here, the syntax x[n..m] is used to create a slice from an array. This is called slicing, and creates a slice of the elements starting at x[n] and ending at x[m - 1]. This example uses a const slice, as the values to which the slice points need not be modified.
fn total(values: []const u8) usize {
    var sum: usize = 0;
    for (values) |v| sum += v;
    return sum;
}
test "slices" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = array[0..3];
    try expect(total(slice) == 6);
}
test "slices 2" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = array[0..3];
    try expect(@TypeOf(slice) == *const [3]u8);
}

//ENUMS
//Zig’s enums allow you to define types with a restricted set of named values.
//Let’s declare an enum.
const Direction = enum { north, south, east, west };
//Enums types may have specified (integer) tag types.

const Value = enum(u2) { zero, one, two };
//Enum’s ordinal values start at 0. They can be accessed with the built-in function @enumToInt.
test "enum ordinal value" {
    try expect(@intFromEnum(Value.zero) == 0);
    try expect(@intFromEnum(Value.one) == 1);
    try expect(@intFromEnum(Value.two) == 2);
}
//Values can be overridden, with the next values continuing from there.
const Value2 = enum(u32) {
    hundred = 100,
    thousand = 1000,
    million = 1000000,
    next,
};

test "set enum ordinal value" {
    try expect(@intFromEnum(Value2.hundred) == 100);
    try expect(@intFromEnum(Value2.thousand) == 1000);
    try expect(@intFromEnum(Value2.million) == 1000000);
    try expect(@intFromEnum(Value2.next) == 1000001);
}

//Methods can be given to enums. These act as namespaced functions that can be called with dot syntax.
const Suit = enum {
    clubs,
    spades,
    diamonds,
    hearts,
    pub fn isClubs(self: Suit) bool {
        return self == Suit.clubs;
    }
};

test "enum method" {
    try expect(Suit.spades.isClubs() == Suit.isClubs(.spades));
}

//Enums can also be given var and const declarations. These act as namespaced globals, and their values are unrelated and unattached to instances of the enum type.
const Mode = enum {
    var count: u32 = 0;
    on,
    off,
};

test "hmm" {
    Mode.count += 1;
    try expect(Mode.count == 1);
}

//STRUCTS
//Structs are Zig’s most common kind of composite data type, allowing you to define types that can store a fixed set of named fields. Zig gives no guarantees about the in-memory order of fields in a struct or its size. Like arrays, structs are also neatly constructed with T{} syntax. Here is an example of declaring and filling a struct.
const Vec3 = struct { x: f32, y: f32, z: f32 };
test "struct usage" {
    const my_vector = Vec3{
        .x = 0,
        .y = 100,
        .z = 50,
    };
    _ = my_vector;
}
//All fields must be given a value.

//Fields may be given defaults:
const Vec4 = struct { x: f32, y: f32, z: f32 = 0, w: f32 = undefined };
test "struct defaults" {
    const my_vector = Vec4{
        .x = 25,
        .y = -50,
    };
    _ = my_vector;
}

//Like enums, structs may also contain functions and declarations.
//Structs have the unique property that when given a pointer to a struct, one level of dereferencing is done automatically when accessing fields. Notice how, in this example, self.x and self.y are accessed in the swap function without needing to dereference the self pointer.
const Stuff = struct {
    x: i32,
    y: i32,
    fn swap(self: *Stuff) void {
        const tmp = self.x;
        self.x = self.y;
        self.y = tmp;
    }
};

test "automatic dereference" {
    var thing = Stuff{ .x = 10, .y = 20 };
    thing.swap();
    try expect(thing.x == 20);
    try expect(thing.y == 10);
}

// UNIONS
//Tagged unions are unions which use an enum to detect which field is active. Here we make use of payload capturing again, to switch on the tag type of a union while also capturing the value it contains. Here we use a pointer capture; captured values are immutable, but with the |*value| syntax, we can capture a pointer to the values instead of the values themselves. This allows us to use dereferencing to mutate the original value.
const Tag = enum { a, b, c };
const Tagged = union(Tag) { a: u8, b: f32, c: bool };
test "switch on tagged union" {
    var value = Tagged{ .b = 1.5 };
    switch (value) {
        .a => |*byte| byte.* += 1,
        .b => |*float| float.* *= 2,
        .c => |*b| b.* = !b.*,
    }
    try expect(value.b == 3);
}
//The tag type of a tagged union can also be inferred. This is equivalent to the Tagged type above.
const Tagged1 = union(enum) { a: u8, b: f32, c: bool };
//void member types can have their type omitted from the syntax. Here, none is of type void.
const Tagged2 = union(enum) { a: u8, b: f32, c: bool, none };
