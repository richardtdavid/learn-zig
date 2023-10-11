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

//LABELLED BLOCKS
//Blocks in Zig are expressions and can be given labels, which are used to yield values. Here, we are using a label called blk. Blocks yield values, meaning they can be used in place of a value. The value of an empty block {} is a value of the type void.
test "labelled blocks" {
    const count = blk: {
        var sum: u32 = 0;
        var i: u32 = 0;
        while (i < 10) : (i += 1) sum += i;
        break :blk sum;
    };
    try expect(count == 45);
    try expect(@TypeOf(count) == u32);
}

//LABELLED LOOPS
//Loops can be given labels, allowing you to break and continue to outer loops.
test "nested continue" {
    var count: usize = 0;
    outer: for ([_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 }) |_| {
        for ([_]i32{ 1, 2, 3, 4, 5 }) |_| {
            count += 1;
            continue :outer;
        }
    }
    try expect(count == 8);
}

//LOOPS AS EXPRESSIONS
//Like return, break accepts a value. This can be used to yield a value from a loop. Loops in Zig also have an else branch, which is evaluated when the loop is not exited with a break.
fn rangeHasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number) {
            break true;
        }
    } else false;
}

test "while loop expression" {
    try expect(rangeHasNumber(0, 10, 3));
}

//OPTIONALS
//Optionals use the syntax ?T and are used to store the data null, or a value of type T.
test "optional" {
    var found_index: ?usize = null;
    const data = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8, 12 };
    for (data, 0..) |v, i| {
        if (v == 10) found_index = i;
    }
    try expect(found_index == null);
}

//.? is a shorthand for orelse unreachable. This is used for when you know it is impossible for an optional value to be null, and using this to unwrap a null value is detectable illegal behaviour.
test "orelse unreachable" {
    const a: ?f32 = 5;
    const b = a orelse unreachable;
    const c = a.?;
    try expect(b == c);
    try expect(@TypeOf(c) == f32);
}

//COMPTIME
//Blocks of code may be forcibly executed at compile time using the comptime keyword. In this example, the variables x and y are equivalent.
test "comptime blocks" {
    var x = comptime fibonacci(10);
    _ = x;

    var y = comptime blk: {
        break :blk fibonacci(10);
    };
    _ = y;
}

//Integer literals are of the type comptime_int. These are special in that they have no size (they cannot be used at runtime!), and they have arbitrary precision. comptime_int values coerce to any integer type that can hold them. They also coerce to floats. Character literals are of this type.
test "comptime_int" {
    const a = 12;
    const b = a + 10;

    const c: u4 = a;
    _ = c;
    const d: f32 = b;
    _ = d;
}

//Types in Zig are values of the type type. These are available at compile time. We have previously encountered them by checking @TypeOf and comparing with other types, but we can do more.
test "branching on types" {
    const a = 5;
    const b: if (a < 10) f32 else i32 = 5;
    _ = b;
}

//Function parameters in Zig can be tagged as being comptime. This means that the value passed to that function parameter must be known at compile time. Let’s make a function that returns a type. Notice how this function is PascalCase, as it returns a type.
fn Matrix(
    comptime T: type,
    comptime width: comptime_int,
    comptime height: comptime_int,
) type {
    return [height][width]T;
}

test "returning a type" {
    try expect(Matrix(f32, 4, 4) == [4][4]f32);
}

//We can reflect upon types using the built-in @typeInfo, which takes in a type and returns a tagged union. This tagged union type can be found in std.builtin.TypeInfo (info on how to make use of imports and std later).
fn addSmallInts(comptime T: type, a: T, b: T) T {
    return switch (@typeInfo(T)) {
        .ComptimeInt => a + b,
        .Int => |info| if (info.bits <= 16)
            a + b
        else
            @compileError("ints too large"),
        else => @compileError("only ints accepted"),
    };
}

test "typeinfo switch" {
    const x = addSmallInts(u16, 20, 30);
    try expect(@TypeOf(x) == u16);
    try expect(x == 50);
}

//We can use the @Type function to create a type from a @typeInfo. @Type is implemented for most types but is notably unimplemented for enums, unions, functions, and structs.
//Here anonymous struct syntax is used with .{}, because the T in T{} can be inferred. Anonymous structs will be covered in detail later. In this example we will get a compile error if the Int tag isn’t set.
fn GetBiggerInt(comptime T: type) type {
    return @Type(.{
        .Int = .{
            .bits = @typeInfo(T).Int.bits + 1,
            .signedness = @typeInfo(T).Int.signedness,
        },
    });
}

test "@Type" {
    try expect(GetBiggerInt(u8) == u9);
    try expect(GetBiggerInt(i31) == i32);
}

//Returning a struct type is how you make generic data structures in Zig. The usage of @This is required here, which gets the type of the innermost struct, union, or enum. Here std.mem.eql is also used which compares two slices.
fn Vec(
    comptime count: comptime_int,
    comptime T: type,
) type {
    return struct {
        data: [count]T,
        const Self = @This();

        fn abs(self: Self) Self {
            var tmp = Self{ .data = undefined };
            for (self.data, 0..) |elem, i| {
                tmp.data[i] = if (elem < 0)
                    -elem
                else
                    elem;
            }
            return tmp;
        }

        fn init(data: [count]T) Self {
            return Self{ .data = data };
        }
    };
}

const eql = @import("std").mem.eql;
test "generic vector" {
    const x = Vec(3, f32).init([_]f32{ 10, -10, 5 });
    const y = x.abs();
    try expect(eql(f32, &y.data, &[_]f32{ 10, 10, 5 }));
}

//The types of function parameters can also be inferred by using anytype in place of a type. @TypeOf can then be used on the parameter.
fn plusOne(x: anytype) @TypeOf(x) {
    return x + 1;
}

test "inferred function parameter" {
    try expect(plusOne(@as(u32, 1)) == 2);
}

//Comptime also introduces the operators ++ and ** for concatenating and repeating arrays and slices. These operators do not work at runtime.
test "++" {
    const x: [4]u8 = undefined;
    const y = x[0..];

    const a: [6]u8 = undefined;
    const b = a[0..];

    const new = y ++ b;
    try expect(new.len == 10);
}

test "**" {
    const pattern = [_]u8{ 0xCC, 0xAA };
    const memory = pattern ** 3;
    try expect(eql(u8, &memory, &[_]u8{ 0xCC, 0xAA, 0xCC, 0xAA, 0xCC, 0xAA }));
}

//PAYLOAD CAPTURES
//Payload captures use the syntax |value| and appear in many places, some of which we’ve seen already. Wherever they appear, they are used to “capture” the value from something.
//With if statements and optionals.
test "optional-if" {
    var maybe_num: ?usize = 10;
    if (maybe_num) |n| {
        try expect(@TypeOf(n) == usize);
        try expect(n == 10);
    } else {
        unreachable;
    }
}

//With if statements and error unions. The else with the error capture is required here.
test "error union if" {
    var ent_num: error{UnknownEntity}!u32 = 5;
    if (ent_num) |entity| {
        try expect(@TypeOf(entity) == u32);
        try expect(entity == 5);
    } else |err| {
        _ = err catch {};
        unreachable;
    }
}

//With while loops and optionals. This may have an else block.
test "while optional" {
    var i: ?u32 = 10;
    while (i) |num| : (i.? -= 1) {
        try expect(@TypeOf(num) == u32);
        if (num == 1) {
            i = null;
            break;
        }
    }
    try expect(i == null);
}

//INLINE LOOPS
//inline loops are unrolled, and allow some things to happen that only work at compile time. Here we use a for, but a while works similarly.
test "inline for" {
    const types = [_]type{ i32, f32, u8, bool };
    var sum: usize = 0;
    inline for (types) |T| sum += @sizeOf(T);
    try expect(sum == 10);
}

//OPAQUE
//opaque types in Zig have an unknown (albeit non-zero) size and alignment. Because of this these data types cannot be stored directly. These are used to maintain type safety with pointers to types that we don’t have information about.
//Opaque types may have declarations in their definitions (the same as structs, enums and unions).
// extern fn show_window(*Window) callconv(.C) void;
// const Window = opaque {
//     fn show(self: *Window) void {
//         show_window(self);
//     }
// };

// test "opaque with declarations" {
//     var main_window: *Window = undefined;
//     main_window.show();
// }

//ANONYMOUS STRUCTS
//The struct type may be omitted from a struct literal. These literals may coerce to other struct types.
test "anonymous struct literal" {
    const Point = struct { x: i32, y: i32 };

    var pt: Point = .{
        .x = 13,
        .y = 67,
    };
    try expect(pt.x == 13);
    try expect(pt.y == 67);
}

//Anonymous structs may be completely anonymous i.e. without being coerced to another struct type.
test "fully anonymous struct" {
    try dump(.{
        .int = @as(u32, 1234),
        .float = @as(f64, 12.34),
        .b = true,
        .s = "hi",
    });
}

fn dump(args: anytype) !void {
    try expect(args.int == 1234);
    try expect(args.float == 12.34);
    try expect(args.b);
    try expect(args.s[0] == 'h');
    try expect(args.s[1] == 'i');
}

//Anonymous structs without field names may be created and are referred to as tuples. These have many of the properties that arrays do; tuples can be iterated over, indexed, can be used with the ++ and ** operators, and have a len field. Internally, these have numbered field names starting at "0", which may be accessed with the special syntax @"0" which acts as an escape for the syntax - things inside @"" are always recognised as identifiers.
//An inline loop must be used to iterate over the tuple here, as the type of each tuple field may differ.
test "tuple" {
    const values = .{
        @as(u32, 1234),
        @as(f64, 12.34),
        true,
        "hi",
    } ++ .{false} ** 2;
    try expect(values[0] == 1234);
    try expect(values[4] == false);
    inline for (values, 0..) |v, i| {
        if (i != 2) continue;
        try expect(v);
    }
    try expect(values.len == 6);
    try expect(values.@"3"[0] == 'h');
}
