// ASSIGNMENTS
const constant: i32 = 5; // signed 32-bit constant
var variable: u32 = 5000; // unsigned 32-bit variable

// @as performs an explicit type coercion
const inferred_constant = @as(i32, 5);
var inferred_variable = @as(u32, 5000);

const a: i32 = undefined;
var b: u32 = undefined;

// ARRAYS
const aArr = [5]u8{ 'h', 'e', 'l', 'l', 'o' };
// N may be replaced by _ to infer the size of the array
const bArr = [_]u8{ 'w', 'o', 'r', 'l', 'd' };

// Array length
const array = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
const length = array.len; // 5
