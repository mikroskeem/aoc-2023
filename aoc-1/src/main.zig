const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const FoundIdx = struct {
    idx: usize,
    chr: u8,
};

pub fn replaceNumberWords(allocator: Allocator, line: []const u8) ![]u8 {
    const Replacement = struct {
        needle: []const u8,
        replace: []const u8,
    };

    const replacements = [_]Replacement{
        .{
            .needle = "one",
            .replace = "on1e",
        },
        .{
            .needle = "two",
            .replace = "tw2o",
        },
        .{
            .needle = "three",
            .replace = "thre3e",
        },
        .{
            .needle = "four",
            .replace = "fo4ur",
        },
        .{
            .needle = "five",
            .replace = "fi5ve",
        },
        .{
            .needle = "six",
            .replace = "si6x",
        },
        .{
            .needle = "seven",
            .replace = "sev7en",
        },
        .{
            .needle = "eight",
            .replace = "eigh8t",
        },
        .{
            .needle = "nine",
            .replace = "nin9e",
        },
    };

    var current: ?[]u8 = null;
    for (replacements) |replacement| {
        var input: []const u8 = current orelse line;

        var old_current = current;
        current = try std.mem.replaceOwned(u8, allocator, input, replacement.needle, replacement.replace);
        if (old_current) |oc| {
            allocator.free(oc);
        }
    }

    return current.?;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.skip();
    const day_two = if (args.next()) |arg| std.mem.eql(u8, arg, "two") else false;

    var sum: u64 = 0;

    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [2048]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_| {
        var line: []u8 = if (day_two)
            try replaceNumberWords(allocator, line_)
        else
            line_;

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

        if (day_two) {
            allocator.free(line);
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
