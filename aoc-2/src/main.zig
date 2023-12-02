const std = @import("std");
const Allocator = std.mem.Allocator;

const Game = struct {
    id: u64,
    possible: bool,
    set: std.StringHashMap(u32),

    fn init(allocator: Allocator, id: u64) Allocator.Error!Game {
        return Game{
            .id = id,
            .possible = true,
            .set = std.StringHashMap(u32).init(allocator),
        };
    }

    fn deinit(self: *Game) void {
        self.set.deinit();
    }

    fn power(self: *Game) u32 {
        var pow: u32 = 1;
        var iter = self.set.valueIterator();
        while (iter.next()) |v| {
            pow *= v.*;
        }

        return pow;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    var sum: u64 = 0;
    var pow_sum: u64 = 0;

    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [2048]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var line_seq = std.mem.splitSequence(u8, line, ": ");

        const game_id = g: {
            var seq = std.mem.splitSequence(u8, line_seq.next().?, " ");
            _ = seq.next().?;
            const id = seq.next().?;

            break :g try std.fmt.parseInt(u64, id, 10);
        };

        var game = try Game.init(allocator, game_id);
        defer game.deinit();

        // Iterate over cube sequences
        var cube_seqs = std.mem.splitSequence(u8, line_seq.next().?, "; ");
        while (cube_seqs.next()) |cube_seq_| {
            var cube_seq = std.mem.splitSequence(u8, cube_seq_, ", ");
            while (cube_seq.next()) |cube| {
                var seq = std.mem.splitSequence(u8, cube, " ");
                const n = try std.fmt.parseInt(u32, seq.next().?, 10);
                const color = seq.next().?;

                // configuration: 12 red, 13 green, 14 blue
                if (game.possible) {
                    // XXX: zig formatter pls...
                    game.possible =
                        (std.mem.eql(u8, color, "red") and n <= 12) // pls wrap
                    or (std.mem.eql(u8, color, "green") and n <= 13) // pls wrap
                    or (std.mem.eql(u8, color, "blue") and n <= 14);
                }

                if (game.set.get(color)) |min_n| {
                    if (min_n < n) {
                        try game.set.put(color, n);
                    }
                } else {
                    try game.set.put(color, n);
                }
            }
        }

        if (game.possible) {
            sum += game.id;
        }
        pow_sum += game.power();
    }

    try stdout.print("{}\n", .{sum});
    try stdout.print("{}\n", .{pow_sum});
}
