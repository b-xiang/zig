const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;

test "dereference pointer" {
    comptime testDerefPtr();
    testDerefPtr();
}

fn testDerefPtr() void {
    var x: i32 = 1234;
    var y = &x;
    y.* += 1;
    expect(x == 1235);
}

test "pointer arithmetic" {
    var ptr = c"abcd";

    expect(ptr[0] == 'a');
    ptr += 1;
    expect(ptr[0] == 'b');
    ptr += 1;
    expect(ptr[0] == 'c');
    ptr += 1;
    expect(ptr[0] == 'd');
    ptr += 1;
    expect(ptr[0] == 0);
    ptr -= 1;
    expect(ptr[0] == 'd');
    ptr -= 1;
    expect(ptr[0] == 'c');
    ptr -= 1;
    expect(ptr[0] == 'b');
    ptr -= 1;
    expect(ptr[0] == 'a');
}

test "double pointer parsing" {
    comptime expect(PtrOf(PtrOf(i32)) == **i32);
}

fn PtrOf(comptime T: type) type {
    return *T;
}

test "assigning integer to C pointer" {
    var x: i32 = 0;
    var ptr: [*c]u8 = 0;
    var ptr2: [*c]u8 = x;
}

test "implicit cast single item pointer to C pointer and back" {
    var y: u8 = 11;
    var x: [*c]u8 = &y;
    var z: *u8 = x;
    z.* += 1;
    expect(y == 12);
}

test "C pointer comparison and arithmetic" {
    const S = struct {
        fn doTheTest() void {
            var one: usize = 1;
            var ptr1: [*c]u32 = 0;
            var ptr2 = ptr1 + 10;
            expect(ptr1 == 0);
            expect(ptr1 >= 0);
            expect(ptr1 <= 0);
            expect(ptr1 < 1);
            expect(ptr1 < one);
            expect(1 > ptr1);
            expect(one > ptr1);
            expect(ptr1 < ptr2);
            expect(ptr2 > ptr1);
            expect(ptr2 >= 40);
            expect(ptr2 == 40);
            expect(ptr2 <= 40);
            ptr2 -= 10;
            expect(ptr1 == ptr2);
        }
    };
    S.doTheTest();
    comptime S.doTheTest();
}

test "peer type resolution with C pointers" {
    var ptr_one: *u8 = undefined;
    var ptr_many: [*]u8 = undefined;
    var ptr_c: [*c]u8 = undefined;
    var t = true;
    var x1 = if (t) ptr_one else ptr_c;
    var x2 = if (t) ptr_many else ptr_c;
    var x3 = if (t) ptr_c else ptr_one;
    var x4 = if (t) ptr_c else ptr_many;
    expect(@typeOf(x1) == [*c]u8);
    expect(@typeOf(x2) == [*c]u8);
    expect(@typeOf(x3) == [*c]u8);
    expect(@typeOf(x4) == [*c]u8);
}

test "implicit casting between C pointer and optional non-C pointer" {
    var slice: []const u8 = "aoeu";
    const opt_many_ptr: ?[*]const u8 = slice.ptr;
    var ptr_opt_many_ptr = &opt_many_ptr;
    var c_ptr: [*c]const [*c]const u8 = ptr_opt_many_ptr;
    expect(c_ptr.*.* == 'a');
    ptr_opt_many_ptr = c_ptr;
    expect(ptr_opt_many_ptr.*.?[1] == 'o');
}

test "implicit cast error unions with non-optional to optional pointer" {
    const S = struct {
        fn doTheTest() void {
            expectError(error.Fail, foo());
        }
        fn foo() anyerror!?*u8 {
            return bar() orelse error.Fail;
        }
        fn bar() ?*u8 {
            return null;
        }
    };
    S.doTheTest();
    comptime S.doTheTest();
}

test "initialize const optional C pointer to null" {
    const a: ?[*c]i32 = null;
    expect(a == null);
    comptime expect(a == null);
}

test "compare equality of optional and non-optional pointer" {
    const a = @intToPtr(*const usize, 0x123456789);
    const b = @intToPtr(?*usize, 0x123456789);
    expect(a == b);
    expect(b == a);
}

test "allowzero pointer and slice" {
    var ptr = @intToPtr([*]allowzero i32, 0);
    var opt_ptr: ?[*]allowzero i32 = ptr;
    expect(opt_ptr != null);
    expect(@ptrToInt(ptr) == 0);
    var slice = ptr[0..10];
    expect(@typeOf(slice) == []allowzero i32);
    expect(@ptrToInt(&slice[5]) == 20);

    expect(@typeInfo(@typeOf(ptr)).Pointer.is_allowzero);
    expect(@typeInfo(@typeOf(slice)).Pointer.is_allowzero);
}
