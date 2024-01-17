const std = @import("std");
const Allocator = std.mem.Allocator;

// XXX TODO:
// We don't need a slice of slices, we can have arrays/slices of pointers instead
// this will save memory

fn allocateArray2D(allocator: Allocator, numNodes: [2]u32) ![][]f64 {
    var array: [][]f64 = undefined;
    array = try allocator.alloc([]f64, numNodes[0]);
    var j: u32 = 0;
    while (j < numNodes[0]) : (j += 1) {
        array[j] = try allocator.alloc(f64, numNodes[1]);
    }
    return array;
}

fn freeArray2D(allocator: Allocator, array: [][]f64) void {
    var j: u32 = 0;
    while (j < array.len) : (j += 1) {
        allocator.free(array[j]);
    }
    allocator.free(array);
}

fn initialCondition(array: [][]f64, domainSize: [2]u32) void {
    _ = domainSize;
    _ = array;
}

fn timeStep(a_1: [][]f64, a_2: [][]f64, D: f64, h: [2]f64, dt: f64) void {
    _ = dt;
    _ = h;
    _ = D;
    _ = a_2;
    _ = a_1;
}

pub fn main() !void {
    var generalAllocatorType = std.heap.GeneralPurposeAllocator(.{}){};
    const generalAllocator = generalAllocatorType.allocator();
    defer {
        _ = generalAllocatorType.deinit();
    }

    const domainLen = [_]f64{ 20, 20 };
    const numNodes = [_]u32{ 1000, 1000 };
    const h = [_]f64{ domainLen[0] / numNodes[0], domainLen[1] / numNodes[1] };
    const D: f64 = 2;

    const minh: f64 = @min(h[0], h[1]);
    const dt: f64 = minh * minh / (5 * D);
    _ = dt;
    const T: f64 = 4;
    _ = T;

    var a_1: [][]f64 = undefined;
    a_1 = try allocateArray2D(generalAllocator, numNodes);
    defer freeArray2D(generalAllocator, a_1);

    var a_2: [][]f64 = undefined;
    a_2 = try allocateArray2D(generalAllocator, numNodes);
    defer freeArray2D(generalAllocator, a_2);
}
