const date = @import("date-zig");
const expectEqual = @import("tests.zig").expectEqual;
const std = @import("std");

test "misc panic checks" {
    try expectEqual(date.date_to_rd(0, 1, 1), -719528);

    _ = date.datetime_to_systemtime2(-436622, 10, 24, 1, 21, 50, 61197202);
    _ = date.datetime_to_systemtime2(0, 10, 23, 1, 21, 50, 61197202);
    _ = date.datetime_to_systemtime2(0, 5, 28, 1, 21, 50, 61197202);
    _ = date.datetime_to_systemtime2(0, 3, 15, 1, 21, 50, 61197202);
    _ = date.datetime_to_systemtime2(0, 2, 7, 1, 21, 50, 61197202);
    _ = date.datetime_to_systemtime2(0, 1, 19, 1, 21, 50, 61197202);
    _ = date.datetime_to_systemtime2(0, 1, 10, 1, 21, 50, 61197202);
    _ = date.datetime_to_systemtime2(0, 1, 5, 1, 21, 50, 61197202);
    _ = date.datetime_to_systemtime2(0, 1, 3, 1, 21, 50, 61197202);
    _ = date.datetime_to_systemtime2(0, 1, 2, 1, 21, 50, 61197202);
    _ = date.datetime_to_systemtime2(0, 1, 1, 1, 21, 50, 61197202);
    _ = date.datetime_to_systemtime2(0, 1, 1, 0, 21, 50, 61197202);
    _ = date.datetime_to_systemtime2(0, 1, 1, 0, 0, 50, 61197202);
    _ = date.datetime_to_systemtime2(0, 1, 1, 0, 0, 0, 61197202);
    _ = date.datetime_to_systemtime2(0, 1, 1, 0, 0, 0, 0);

    _ = date.systemtime_to_datetime2(date.Instant.from_secs_ns(-5945250583947, 56984183));
    _ = date.systemtime_to_datetime2(date.Instant.from_secs_ns(27695754759660, 364503439));
    _ = date.systemtime_to_datetime2(date.Instant.from_secs_ns(-62150533140, 364503439));
    _ = date.systemtime_to_datetime2(date.Instant.from_secs_ns(-62158913940, 364503439));
    _ = date.systemtime_to_datetime2(date.Instant.from_secs_ns(-62163061140, 364503439));
    _ = date.systemtime_to_datetime2(date.Instant.from_secs_ns(-62165134740, 364503439));
    _ = date.systemtime_to_datetime2(date.Instant.from_secs_ns(-62166171540, 364503439));
    _ = date.systemtime_to_datetime2(date.Instant.from_secs_ns(-62166689940, 364503439));
    _ = date.systemtime_to_datetime2(date.Instant.from_secs_ns(-62166949140, 364503439));
    _ = date.systemtime_to_datetime2(date.Instant.from_secs_ns(-62167121940, 364503439));
    _ = date.systemtime_to_datetime2(date.Instant.from_secs_ns(-62167208340, 364503439));
    _ = date.systemtime_to_datetime2(date.Instant.from_secs_ns(-62167219140, 364503439));
    _ = date.systemtime_to_datetime2(date.Instant.from_secs_ns(-62167219200, 364503439));
    _ = date.systemtime_to_datetime2(date.Instant.from_secs_ns(-62167219200, 0));
    _ = date.systemtime_to_datetime2(.{ .timestamp = .{ .tv_sec = 11707690157521, .tv_nsec = 39604290313 } });
    _ = date.systemtime_to_datetime2(.{ .timestamp = .{ .tv_sec = -62165778854, .tv_nsec = 140604344369153 } });
}
