const std = @import("std");
const assert = std.debug.assert;

const FoundIdx = struct {
    idx: usize,
    chr: u8,
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var sum: u64 = 0;

    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [2048]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var i: usize = 0;

        var first: ?FoundIdx = null;
        var last: ?FoundIdx = null;

        while (i < line.len) : (i += 1) {
            var c = line[i];
            if (!std.ascii.isDigit(c)) {
                continue;
            }

            var new_found = FoundIdx{
                .idx = i,
                .chr = c,
            };

            if (first == null or first.?.idx > i) {
                first = new_found;
            } else if (last == null or last.?.idx < i) {
                last = new_found;
            }
        }

        // Collect found digits into a slice & parse it
        // We can simplify the checks suce none of the numbers are 0
        var num_buf = [2]u8{ 0, 0 };
        if (last) |l| {
            num_buf[1] = l.chr;
        }

        if (first) |f| {
            num_buf[0] = f.chr;
            if (last == null) {
                num_buf[1] = f.chr;
            }
        }

        assert(num_buf[0] != 0);
        assert(num_buf[1] != 0);

        sum += try std.fmt.parseInt(u64, &num_buf, 10);
    }

    try stdout.print("{}\n", .{sum});
}
