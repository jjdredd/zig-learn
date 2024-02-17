const std = @import("std");
const Allocator = std.mem.Allocator;
const Pi = std.math.pi;

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

fn indexToCoord(i: u32, h: f64) f64 {
    return @as(f32, @floatFromInt(i)) * h;
}

fn initialCondition(array: [][]f64, domainSize: [2]f64, h: [2]f64) void {
    var i: u32 = 0;
    while (i < array.len) : (i += 1) {
        const x = indexToCoord(i, h[0]);
        var j: u32 = 0;
        while (j < array[i].len) : (j += 1) {
            const y = indexToCoord(j, h[1]);
            array[i][j] = @sin(x / domainSize[0] * Pi) * @sin(y / domainSize[1] * Pi);
        }
    }
}

fn signBc(coord: u32, domainStart: u32, domainEnd: u32) f32 {
    if (coord == domainStart) return -1;
    else if (coord == domainEnd) return 1;
    else return 0;
}

// Neumann boundary condition
// XXX TODO: implement a check to see if we're actually on a boundary
fn neumannBoundaryCondition(x: f64, y: f64) f64 {
    _ = x;
    _ = y;
    return 0;
}

fn discreetNeumannBc(a: [][]f64, i: u32, j: u32, domainSize: [2]f64, h: [2]f64,
                     component: u8) f64 {
    // the x-component
    if (component == "x") {
        return signBc(i, 0, domainSize[0])
            * 2 * (neumannBoundaryCondition(x, y) / h[0] + (a_1[i][j] - a_1[i + 1][j])/(h[0]*h[0]));
        // the y-component
    } else if (component == "y") {
        return signBc(j, 0, domainSize[1])
            * 2 * (neumannBoundaryCondition(x, y) / h[1] + (a_1[i][j] - a_1[i][j + 1])/(h[1]*h[1]));
    } else unreachable;
}

// make another function that calculates the laplacian at the boundary
// this way we can change between dirichlet and laplacian bc
fn laplacianFdNeumannBc(a_1: [][]f64, a_2: [][]f64, domainSize: [2]f64, h: [2]f64, D: f64) f64 {
    var i: u32 = 0;
    var j: u32 = 0;
    var x: f64 = 0;
    var y: f64 = 0;
    var xBc: f64 = 0;
    var xBc: f64 = 0;

    // y-boundaries, x = 0, x = N
    i = 0;
    j = 0;
    xBc = discreetNeumannBc(a_1, i, j, domainSize, h, 'x');
    yBc = discreetNeumannBc(a_1, i, j, domainSize, h, 'y');
    a_2[i][j] = D * (xBc + yBc);
    j = 1;
    while (j < a_1[i].len - 2) : (j += 1) {
        xBc = discreetNeumannBc(a_1, i, j, domainSize, h, 'x');
        var laplacianY = (a_1[i + 1][j] + a_1[i - 1][j] - 2 * a_1[i][j])
            / (h[1] * h[1]);
        a_2[i][j] = D * (xBc + laplacianY);
    }
    j = a_1[i].len - 1;
    xBc = discreetNeumannBc(a_1, i, j, domainSize, h, 'x');
    yBc = discreetNeumannBc(a_1, i, j, domainSize, h, 'y');
    a_2[i][j] = D * (xBc + yBc);

    i = a_1.len - 1;
    j = 0
    xBc = discreetNeumannBc(a_1, i, j, domainSize, h, 'x');
    yBc = discreetNeumannBc(a_1, i, j, domainSize, h, 'y');
    a_2[i][j] = D * (xBc + yBc);
    while (j < a_1[i].len - 1) : (j += 1) {
        xBc = discreetNeumannBc(a_1, i, j, domainSize, h, 'x');
        var laplacianY = (a_1[i + 1][j] + a_1[i - 1][j] - 2 * a_1[i][j]) / (h[1] * h[1]);
        a_2[i][j] = D * (xBc + laplacianY);
    }
    j = a_1[i].len - 1;
    xBc = discreetNeumannBc(a_1, i, j, domainSize, h, 'x');
    yBc = discreetNeumannBc(a_1, i, j, domainSize, h, 'y');
    a_2[i][j] = D * (xBc + yBc);

    // x - boundaries

    while (i < a_1.len - 1) : (i += 1) {
        var j: u32 = 0;
        while (j < a_1[i].len - 1) : (j += 1) {
            var laplacianX = (a_1[i + 1][j] + a_1[i - 1][j] - 2 * a_1[i][j]) 
                / (h[0] * h[0]);
            var laplacianY = (a_1[i + 1][j] + a_1[i - 1][j] - 2 * a_1[i][j])
                / (h[1] * h[1]);
            a_2[i][j] = D * (laplacianX + laplacianY);
        }
    }
}

fn laplacianFd(a_1: [][]f64, a_2: [][]f64, h: [2]f64, D: f64) f64 {
    var i: u32 = 1;
    while (i < a_1.len - 1) : (i += 1) {
        var j: u32 = 1;
        while (j < a_1[i].len - 1) : (j += 1) {
            var laplacianX = (a_1[i + 1][j] + a_1[i - 1][j] - 2 * a_1[i][j])
                / (h[0] * h[0]);
            var laplacianY = (a_1[i + 1][j] + a_1[i - 1][j] - 2 * a_1[i][j]) 
                / (h[1] * h[1]);
            a_2[i][j] = D * (laplacianX + laplacianY);
        }
    }
}

fn timeStep(a_1: [][]f64, a_2: [][]f64, D: f64, h: [2]f64, dt: f64) void {
    _ = dt;
    _ = h;
    _ = D;
    _ = a_2;
    _ = a_1;
}

fn outputArray2D(fileName: []const u8, a: [][]f64, h: [2]f64) !void {
    var file = try std.fs.cwd().createFile(fileName, .{});
    defer file.close();

    const fileWriter = file.writer();

    var i: u32 = 0;
    while (i < a.len) : (i += 1) {
        const x = indexToCoord(i, h[0]);
        var j: u32 = 0;
        while (j < a[i].len) : (j += 1) {
            const y = indexToCoord(j, h[1]);
            try fileWriter.print("{}\t{}\t{}\n", .{ x, y, a[i][j] });
        }
    }
}

pub fn main() !void {
    var generalAllocatorType = std.heap.GeneralPurposeAllocator(.{}){};
    const generalAllocator = generalAllocatorType.allocator();
    defer {
        _ = generalAllocatorType.deinit();
    }

    const domainLen = [_]f64{ 20, 20 };
    const numNodes = [_]u32{ 200, 200 };
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

    initialCondition(a_1, domainLen, h);
    try outputArray2D("ic.txt", a_1, h);
}
