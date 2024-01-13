const std = @import("std");
const Allocator = std.mem.Allocator;

fn initialCondition(array: []f64, domainLen: f64) void {
    const h: f64 = domainLen / @as(f64, @floatFromInt(array.len));
    @memset(array, 0);
    for (array, 0..) |*y, i| {
        var x: f64 = @as(f64, @floatFromInt(i)) * h;
        if (x > std.math.pi) break;
        y.* = @sin(x);
    }
}

fn timeStep(a_1: []f64, a_2: []f64, v: f64, h: f64, dt: f64) void {
    std.debug.assert(a_1.len == a_2.len);
    for (a_1[1..], 1..) |f_1, i| {
        var delta: f64 = -dt * v * (a_1[i] - a_1[i - 1]) / h;
        a_2[i] = f_1 + delta;
    }
}

pub fn main() !void {
    var generalAllocatorType = std.heap.GeneralPurposeAllocator(.{}){};
    const generalAllocator = generalAllocatorType.allocator();
    defer {
        _ = generalAllocatorType.deinit();
    }

    const domainLen: f64 = 20;
    const numNodes = 1000;
    const h: f64 = domainLen / numNodes;
    const v: f64 = 2;
    const dt: f64 = h / (5 * v);
    const T: f64 = 4;

    var buff_1: []f64 = undefined;
    var buff_2: []f64 = undefined;
    buff_1 = try generalAllocator.alloc(f64, numNodes);
    defer generalAllocator.free(buff_1);

    buff_2 = try generalAllocator.alloc(f64, numNodes);
    defer generalAllocator.free(buff_2);

    initialCondition(buff_1, domainLen);

    var t: f64 = 0;
    while (t < T) : (t += dt) {
        timeStep(buff_1, buff_2, v, h, dt);

        var auxPtr: []f64 = buff_1;
        buff_1 = buff_2;
        buff_2 = auxPtr;
    }

    // output
    var file = try std.fs.cwd().createFile("res.txt", .{});
    defer file.close();
    const fileWriter = file.writer();

    for (buff_1) |val| {
        try fileWriter.print("{}\n", .{val});
    }
}
