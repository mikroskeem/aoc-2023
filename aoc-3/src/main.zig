const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const XY = struct {
    x: u64,
    y: u64,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    //defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.skip();
    const day_two = if (args.next()) |arg| std.mem.eql(u8, arg, "two") else false;
    _ = day_two;

    var sum: u64 = 0;

    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var part_numbers = std.AutoHashMap(XY, bool).init(allocator);
    defer part_numbers.deinit();

    // NOTE: my grid was 140x140, yous might be different
    // Too lazy to make it dynamic
    const rows = 140;
    const cols = 140;

    var grid: [rows][]u8 = .{};

    var y: i64 = 0;

    var buf: [2048]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        grid[@intCast(y)] = try allocator.dupe(u8, line);
        y += 1;
    }

    var in_digit: bool = false;
    _ = in_digit;

    y = 0;
    while (y < rows) : (y += 1) {
        var x: i64 = 0;
        while (x < cols) : (x += 1) {
            const c = grid[@intCast(y)][@intCast(x)];

            // Skip digits and "whitespace"
            if (std.ascii.isDigit(c) or c == '.') {
                continue;
            }

            // If we've hit a symbol, scan for adjacent part numbers
            var a_y: i16 = -1;
            var a_x: i16 = -1;
            while (a_y < 2) : (a_y += 1) {
                const s_y = y + a_y;

                // Iterate over column until we'll find a digit
                var found_number: ?XY = null;
                while (a_x < 2) : (a_x += 1) {
                    const s_x = x + a_x;
                    if (s_x == 0 and s_y == 0) {
                        continue;
                    }

                    if (grid.len <= s_y) {
                        continue;
                    }

                    const row = grid[@intCast(s_y)];
                    if (row.len <= s_x) {
                        continue;
                    }

                    const s_c = row[@intCast(s_x)];

                    if (!std.ascii.isDigit(s_c)) {
                        continue;
                    }

                    const xy = XY{
                        .x = @intCast(s_x),
                        .y = @intCast(s_y),
                    };

                    try stdout.print("scanning x={d} y={d} -> {c}\n", .{ s_x, s_y, s_c });
                    try part_numbers.putNoClobber(xy, true);
                    found_number = xy;
                }

                if (found_number) |xy| {
                    const row = grid[xy.y];
                    var n_buf = std.ArrayList(u8).init(allocator);
                    defer n_buf.deinit();

                    // Look behind
                    var n_x: u64 = xy.x;
                    while (std.ascii.isDigit(row[n_x]) and n_x > 0) : (n_x -= 1) {
                        //
                    }
                    n_x += 1;

                    if (n_x != xy.x) {
                        try stdout.print("n_x={d}\n", .{n_x});
                    }

                    // Now collect the characters
                    while (n_x < cols and std.ascii.isDigit(row[n_x])) : (n_x += 1) {
                        try n_buf.append(row[n_x]);
                    }

                    try stdout.print("found num={s}\n", .{n_buf.items});
                    const n = try std.fmt.parseInt(u64, n_buf.items, 10);

                    sum += n;
                }

                found_number = null;
                a_x = -1;
            }
        }
    }

    try stdout.print("{}\n", .{sum});

    for (grid) |row| {
        allocator.free(row);
    }
}
