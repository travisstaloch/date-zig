//! This is a port of https://github.com/nakedible/datealgo-rs/ to zig
//!
//! Only a small amount of original code has been written here.  Most of the
//! code has been directly ported from the above.
//!
//!
//! Low-level date algorithms for libraries
//!
//! This library aims to provide the **highest performance algorithms** for date
//! manipulation in an unopinionated way. It is meant to be used by the various
//! date and time libraries which can then provide ergonomic and opinionated
//! interfaces for their users.
//!
//! # Usage
//!
//! The primary contribution of this crate for date libraries are the
//! conversions between a day number from Unix epoch (January 1st, 1970) and a
//! Gregorian date:
//!
//! ```
//! const date = @import("date-zig");
//!
//! try expectEqual(date.date_to_rd(1970, 1, 1), 0);
//! try expectEqual(date.date_to_rd(2023, 5, 12), 19489);
//! try expectEqual(date.rd_to_date(19489), (2023, 5, 12));
//! ```
//!
//! For convenience, there is also converters to and from Unix timestamps:
//!
//! ```
//! const date = @import("date-zig");
//!
//! try expectEqual(date.datetime_to_secs(1970, 1, 1, 0, 0, 0), 0);
//! try expectEqual(date.datetime_to_secs(2023, 5, 20, 9, 24, 38), 1684574678);
//! try expectEqual(date.secs_to_datetime(1684574678), .{2023, 5, 20, 9, 24, 38});
//! ```
//!
//! If the `std` feature is enabled, there are also converters to and from
//! `Instant`:
//!
//! ```
//! try expectEqual(systemtime_to_datetime(UNIX_EPOCH), .{1970, 1, 1, 0, 0, 0, 0});
//! try expectEqual(systemtime_to_datetime(instant_from_secs(1684574678)), .{2023, 5, 20, 9, 24, 38, 0});
//! try expectEqual(datetime_to_systemtime(2023, 5, 20, 9, 24, 38, 0), instant_from_secs(1684574678));
//! ```
//!
//! # Background
//!
//! Many date libraries contain their own copies of date algorithms, most
//! prominently the conversion from days since an epoch to a Gregorian calendar
//! date (year, month, day). These algorithms have been sourced from various
//! places with various licenses, often translated either by machine or by hand
//! from C algorithms found in different libc variants. The algorithms are
//! usually somewhat optimized for performance, but fall short of fastest
//! algorithms available.
//!
//! # Notes
//!
//! The library does not expose any kind of `Date` or `DateTime` structures, but
//! simply tuples for the necessary values. Bounds checking is done via
//! `std.debug.assert` only, which means the methods are guaranteed to not panic in
//! release builds. Callers are required to do their own bounds checking.
//! Datatypes are selected as the smallest that will fit the value.
//!
//! Currently the library implements algorithms for the [Proleptic Gregorian
//! Calendar](https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar) which
//! is our current calendar extended backwards indefinitely. The Gregorian
//! calendar defines the average year to be 365.2425 days long by defining every
//! fourth year to be a leap year, unless the year is divisible by 100 and not
//! by 400.
//!
//! The algorithms do not account for leap seconds, as is customary for [Unix
//! time](https://en.wikipedia.org/wiki/Unix_time). Every day is exactly 86400
//! seconds in length, and the calculated times do not adjust for leap seconds
//! between timestamps.
//!
//! We define [Rata Die](https://en.wikipedia.org/wiki/Rata_Die) to be integral
//! day numbers counted from 1st of January, 1970, which is the Unix epoch. We
//! use the abbreviation `rd` to concisely refer to such values. This differs
//! from the epoch originally chosen by Howard Jacobson, but is more convenient
//! for usage.
//!
//! The Rata Die values are represented as `i32` for performance reasons. The
//! needed calculations reduce that to roughly an effective `i30` integer range,
//! which means a usable range of roughly -1,460,000 to 1,460,000 years.
//!
//! # Acknowledgements
//!
//! I do not claim original research on anything that is in this library.  This
//! is purely a port of https://github.com/nakedible/datealgo-rs/ to zig.
//!
//! - [Nuutti Kotivuori](https://github.com/nakedible/datealgo-rs/)
//! - [Cassio Neri and Lorenz
//!   Schneider](https://onlinelibrary.wiley.com/doi/full/10.1002/spe.3172):
//!   While searching for best method for date conversion, I stumbled upon a
//!   research paper which explains a novel way to optimize the performance.
//!   These algorithms have been implemented here based on the published
//!   article. This wouldn't be the best performing date conversion library
//!   without their work.
//! - [Howard Hinnant](https://howardhinnant.github.io/date_algorithms.html):
//!   While searching for "perpetual calendar" algorithms, and having already
//!   started my library, I stumbled upon a very similar idea by Howard Hinnant.
//!   It remains one of the cleanest and simplest algorithms while still
//!   retaining excellent performance.
//! - [Rich
//!   Felker](https://git.musl-libc.org/cgit/musl/tree/src/time/__secs_to_tm.c):
//!   The original musl `__time_to_tm` function has spread far and wide and been
//!   translated to many languages, and is still the basis of many of the
//!   standalone implementations littered among the libraries.
//! - [Many authors of newlib
//!   `gmtime_r.c`](https://sourceware.org/git/?p=newlib-cygwin.git;a=blob;f=newlib/libc/time/gmtime_r.c;hb=HEAD):
//!   The newlib implementation has evolved significantly over time and has now
//!   been updated based on the work by Howard Hinnant.

const builtin = @import("builtin");
const is_posix = switch (builtin.os.tag) {
    .wasi => builtin.link_libc,
    .windows => false,
    else => true,
};
const Instant = std.time.Instant;

pub const UNIX_EPOCH = instant_from_secs(0);

pub fn instant_from_secs(secs: i64) Instant {
    return .{
        .timestamp = if (is_posix)
            .{ .tv_sec = secs, .tv_nsec = 0 }
        else
            // TODO decide how to handle overflow
            // @intCast(secs * std.time.ns_per_s) };
            unreachable,
    };
}

pub fn instant_from_secs_ns(secs: i64, nsecs: u32) Instant {
    return .{
        .timestamp = if (is_posix)
            .{ .tv_sec = secs, .tv_nsec = nsecs }
        else
            // TODO decide how to handle overflow
            // @intCast(secs * std.time.ns_per_s + nsecs) };
            unreachable,
    };
}

/// comptute self - other
pub fn sub_instants(self: Instant, other: Instant) Instant {
    if (is_posix) {
        const secs, const nsec = if (self.timestamp.tv_nsec >= other.timestamp.tv_nsec)
            .{
                self.timestamp.tv_sec - other.timestamp.tv_sec,
                self.timestamp.tv_nsec - other.timestamp.tv_nsec,
            }
        else
            .{
                (self.timestamp.tv_sec - other.timestamp.tv_sec - 1),
                self.timestamp.tv_nsec + std.time.ns_per_s - other.timestamp.tv_nsec,
            };
        return .{ .timestamp = .{ .tv_sec = secs, .tv_nsec = nsec } };
    } else return .{ .timestamp = self.timestamp - other.timestamp };
}

/// Adjustment from Unix epoch to make calculations use positive integers
///
/// Unit is eras, which is defined to be 400 years, as that is the period of the
/// proleptic Gregorian calendar. Selected to place unix epoch roughly in the
/// center of the value space, can be arbitrary within type limits.
const ERA_OFFSET: i32 = 3670;
/// Every era has 146097 days
const DAYS_IN_ERA: i32 = 146097;
/// Every era has 400 years
const YEARS_IN_ERA: i32 = 400;
/// Number of days from 0000-03-01 to Unix epoch 1970-01-01
const DAYS_TO_UNIX_EPOCH: i32 = 719468;
/// Offset to be added to given day values
const DAY_OFFSET: i32 = ERA_OFFSET * DAYS_IN_ERA + DAYS_TO_UNIX_EPOCH;
/// Offset to be added to given year values
const YEAR_OFFSET: i32 = ERA_OFFSET * YEARS_IN_ERA;
/// Seconds in a single 24 hour calendar day
const SECS_IN_DAY: i64 = 86400;
/// Offset to be added to given second values
const SECS_OFFSET: i64 = DAY_OFFSET * SECS_IN_DAY;

/// Minimum supported year for conversion
///
/// Years earlier than this are not supported and will likely produce incorrect
/// results.
pub const YEAR_MIN: i32 = -1467999;

/// Maximum supported year for conversion
///
/// Years later than this are not supported and will likely produce incorrect
/// results.
pub const YEAR_MAX: i32 = 1471744;

/// Minimum Rata Die for conversion
///
/// Rata die days earlier than this are not supported and will likely produce incorrect
/// results.
pub const RD_MIN: i32 = date_to_rd(YEAR_MIN, 1, 1);

/// Maximum Rata Die for conversion
///
/// Rata die days later than this are not supported and will likely produce incorrect
/// results.
pub const RD_MAX: i32 = date_to_rd(YEAR_MAX, 12, 31);

/// Minimum Rata Die in seconds for conversion
///
/// Rata die seconds earlier than this are not supported and will likely produce incorrect
/// results.
pub const RD_SECONDS_MIN: i64 = RD_MIN * SECS_IN_DAY;

/// Maximum Rata die in seconds for conversion
///
/// Rata die seconds later than this are not supported and will likely produce incorrect
/// results.
pub const RD_SECONDS_MAX: i64 = RD_MAX * SECS_IN_DAY + SECS_IN_DAY - 1;

/// Convenience constants, mostly for input validation
///
/// The use of these constants is strictly optional, as this is a low level
/// library and the values are wholly unremarkable.
pub const consts = struct {
    /// Minimum value for week
    pub const WEEK_MIN: u8 = 1;
    /// Maximum value for week
    pub const WEEK_MAX: u8 = 53;
    /// Minimum value for month
    pub const MONTH_MIN: u8 = 1;
    /// Maximum value for month
    pub const MONTH_MAX: u8 = 12;
    /// Minimum value for day of month
    pub const DAY_MIN: u8 = 1;
    /// Maximum value for day of month
    pub const DAY_MAX: u8 = 31;
    /// Minimum value for day of week
    pub const WEEKDAY_MIN: u8 = 1;
    /// Maximum value for day of week
    pub const WEEKDAY_MAX: u8 = 7;
    /// Minimum value for hours
    pub const HOUR_MIN: u8 = 0;
    /// Maximum value for hours
    pub const HOUR_MAX: u8 = 23;
    /// Minimum value for minutes
    pub const MINUTE_MIN: u8 = 0;
    /// Maximum value for minutes
    pub const MINUTE_MAX: u8 = 59;
    /// Minimum value for seconds
    pub const SECOND_MIN: u8 = 0;
    /// Maximum value for seconds
    pub const SECOND_MAX: u8 = 59;
    /// Minimum value for nanoseconds
    pub const NANOSECOND_MIN: u32 = 0;
    /// Maximum value for nanoseconds
    pub const NANOSECOND_MAX: u32 = 999_999_999;

    /// January month value
    pub const JANUARY: u8 = 1;
    /// February month value
    pub const FEBRUARY: u8 = 2;
    /// March month value
    pub const MARCH: u8 = 3;
    /// April month value
    pub const APRIL: u8 = 4;
    /// May month value
    pub const MAY: u8 = 5;
    /// June month value
    pub const JUNE: u8 = 6;
    /// July month value
    pub const JULY: u8 = 7;
    /// August month value
    pub const AUGUST: u8 = 8;
    /// September month value
    pub const SEPTEMBER: u8 = 9;
    /// October month value
    pub const OCTOBER: u8 = 10;
    /// November month value
    pub const NOVEMBER: u8 = 11;
    /// December month value
    pub const DECEMBER: u8 = 12;

    /// Monday day of week value
    pub const MONDAY: u8 = 1;
    /// Tuesday day of week value
    pub const TUESDAY: u8 = 2;
    /// Wednesday day of week value
    pub const WEDNESDAY: u8 = 3;
    /// Thursday day of week value
    pub const THURSDAY: u8 = 4;
    /// Friday day of week value
    pub const FRIDAY: u8 = 5;
    /// Saturday day of week value
    pub const SATURDAY: u8 = 6;
    /// Sunday day of week value
    pub const SUNDAY: u8 = 7;
};

// OPTIMIZATION NOTES:
// - addition and substraction is the same speed regardless of signed or unsigned
// - addition and substraction is the same speed for u32 and u64
// - multiplication and especially division is slower for u64 than u32
// - division is slower for signed than unsigned
// - if the addition of two i32 is positive and fits in u32, wrapping (default)
//   semantics give us the correct results even if the sum is larger than i32::MAX

/// Convert Rata Die to Gregorian date
///
/// Given a day counting from Unix epoch (January 1st, 1970) returns a `(year,
/// month, day)` tuple.
///
/// # Panics
///
/// Argument must be between [RD_MIN] and [RD_MAX] inclusive. Bounds are checked
/// using `std.debug.assert` only, so that the checks are not present in release
/// builds, similar to integer overflow checks.
///
/// # Examples
///
/// ```
/// try expectEqual(rd_to_date(-719528), (0, 1, 1);
/// try expectEqual(rd_to_date(0), (1970, 1, 1);
/// try expectEqual(rd_to_date(19489), (2023, 5, 12);
/// try expectEqual(rd_to_date(2932896), (9999, 12, 31);
/// try expectEqual(rd_to_date(46761996), (129999, 12, 31);
/// try expectEqual(rd_to_date(-48200687), (-129999, 1, 1);
/// ```
///
/// # Algorithm
///
/// Algorithm currently used is the Neri-Schneider algorithm using Euclidean
/// Affine Functions:
///
/// > Neri C, Schneider L. "*Euclidean affine functions and their application to
/// > calendar algorithms*". Softw Pract Exper. 2022;1-34. doi:
/// > [10.1002/spe.3172](https://onlinelibrary.wiley.com/doi/full/10.1002/spe.3172).
pub fn rd_to_date(rd: i32) struct { i32, u8, u8 } {
    std.debug.assert(rd >= RD_MIN and rd <= RD_MAX); //given rata die is out of range");
    const n0: u32 = @intCast(rd +% DAY_OFFSET);
    // century
    const n1 = 4 * n0 + 3;
    const c = n1 / 146097;
    const r = n1 % 146097;
    // year
    const n2 = r | 3;
    const p: u64 = 2939745 * @as(u64, n2);
    const z: u32 = @truncate(p / (1 << 32));
    const n3: u32 = @truncate((p % (1 << 32)) / 2939745 / 4);
    const j = @intFromBool(n3 >= 306);
    const y1: u32 = 100 * c + z + j;
    // month and day
    const n4 = 2141 * n3 + 197913;
    const m1 = n4 / (1 << 16);
    const d1 = n4 % (1 << 16) / 2141;
    // map
    const y = (@as(i32, @intCast(y1))) -% (YEAR_OFFSET);
    const m = if (j != 0) m1 - 12 else m1;
    const d = d1 + 1;
    return .{ y, @intCast(m), @intCast(d) };
}

/// Convert Gregorian date to Rata Die
///
/// Given a `year, month, day` returns the days since Unix epoch
/// (January 1st, 1970). Dates before the epoch produce negative values.
///
/// # Panics
///
/// Year must be between [YEAR_MIN] and [YEAR_MAX]. Month must be between `1`
/// and `12`. Day must be between `1` and the number of days in the month in
/// question. Bounds are checked using `std.debug.assert` only, so that the checks
/// are not present in release builds, similar to integer overflow checks.
///
/// # Examples
///
/// ```
/// try expectEqual(date_to_rd(2023, 5, 12)), 19489);
/// try expectEqual(date_to_rd(1970, 1, 1)), 0);
/// try expectEqual(date_to_rd(0, 1, 1)), -719528);
/// try expectEqual(date_to_rd(9999, 12, 31)), 2932896);
/// try expectEqual(date_to_rd(129999, 12, 31)), 46761996);
/// try expectEqual(date_to_rd(-129999, 1, 1)), -48200687);
/// ```
///
/// # Algorithm
///
/// Algorithm currently used is the Neri-Schneider algorithm using Euclidean
/// Affine Functions:
///
/// > Neri C, Schneider L. "*Euclidean affine functions and their application to
/// > calendar algorithms*". Softw Pract Exper. 2022;1-34. doi:
/// > [10.1002/spe.3172](https://onlinelibrary.wiley.com/doi/full/10.1002/spe.3172).
pub fn date_to_rd(y0: i32, m0: u8, d0: u8) i32 {
    std.debug.assert(y0 >= YEAR_MIN and y0 <= YEAR_MAX); //given year is out of range");
    std.debug.assert(m0 >= consts.MONTH_MIN and m0 <= consts.MONTH_MAX); //given month is out of range");
    std.debug.assert(d0 >= consts.DAY_MIN and d0 <= days_in_month(y0, m0)); //given day is out of range");
    const y1: u32 = @intCast(y0 +% YEAR_OFFSET);
    // map
    const jf: u32 = @intFromBool(m0 < 3);
    const y2 = y1 - jf;
    const m1 = @as(u32, m0) + 12 * jf;
    const d1 = @as(u32, d0) - 1;
    // century
    const c = y2 / 100;
    // year
    const y3 = 1461 * y2 / 4 - c + c / 4;
    // month
    const m = (979 * m1 - 2919) / 32;
    // result
    const n = y3 + m + d1;
    return @as(i32, @intCast(n)) -% DAY_OFFSET;
}

/// Convert Rata Die to day of week
///
/// Given a day counting from Unix epoch (January 1st, 1970) returns the day of
/// week. Day of week is given as `u32` number between 1 and 7, with `1` meaning
/// Monday and `7` meaning Sunday.
///
/// # Panics
///
/// Argument must be between [RD_MIN] and [RD_MAX] inclusive. Bounds are checked
/// using `std.debug.assert` only, so that the checks are not present in release
/// builds, similar to integer overflow checks.
///
/// # Examples
///
/// ```
/// try expectEqual(rd_to_weekday(date_to_rd(2023, 5, 12))), 5);
/// try expectEqual(rd_to_weekday(date_to_rd(1970, 1, 1))), 4);
/// try expectEqual(rd_to_weekday(date_to_rd(2023, 1, 1))), 7);
/// ```
///
/// If you wish to instead have a value from `0` to `6` with `0` signifying a
/// Sunday, it is easiest to just add `% 7`:
///
/// ```
/// try expectEqual(rd_to_weekday(date_to_rd(2023, 1, 1))) % 7, 0);
/// try expectEqual(rd_to_weekday(date_to_rd(2023, 5, 12))) % 7, 5);
/// ```
///
/// # Algorithm
///
/// In essence, the algorithm calculates `(n + offset) % 7 + 1` where `offset`
/// is such that `m := n + offset >= 0` and for `n = 0` it yields `4` (since
/// January 1st, 1970 was a Thursday). However, it uses a faster way to evaluate
/// `m % 7 + 1` based on the binary representation of the reciprocal of `7`,
/// namely, `C := (0.001_001_001...)_2`. The following table presents the binary
/// values of `m % 7 + 1` and `p := m * C` for `m = 0`, `2`, `...`:
///
/// | `m` | `m % 7 + 1` | `(m + 1) * C`          |
/// | --- | ----------- | ---------------------- |
/// | `0` | `(001)_2`   | `(0.001_001_001...)_2` |
/// | `1` | `(010)_2`   | `(0.010_010_010...)_2` |
/// | `2` | `(011)_2`   | `(0.011_011_011...)_2` |
/// | `3` | `(100)_2`   | `(0.100_100_100...)_2` |
/// | `4` | `(101)_2`   | `(0.101_101_101...)_2` |
/// | `5` | `(110)_2`   | `(0.110_110_110...)_2` |
/// | `6` | `(111)_2`   | `(0.111_111_111...)_2` |
/// | `7` | `(001)_2`   | `(1.001_001_001...)_2` |
/// | ... | ...         | ...                    |
///
/// Notice that the bits of `m * C` after the dot repeat indefinitely in groups
/// of `3`.  Furthermore, the repeating group matches `m % 7 + 1`.
///
/// Based on the above, the algorithm multiplies `m` by `2^64 / 7` and extracts
/// the `3`` highest bits of the product by shifiting `61` bits to the right.
/// However, since `2^64 / 7` must be truncated, the result is an approximation
/// that works provided that m is not too large but, still, large enough for our
/// purposes.
pub fn rd_to_weekday(n: i32) u8 {
    std.debug.assert(n >= RD_MIN and n <= RD_MAX); //given rata die is out of range");
    const P64_OVER_SEVEN: u64 = (1 << 64) / 7;
    return @truncate(((@as(u64, @intCast(n -% RD_MIN)) + 1) *% P64_OVER_SEVEN) >> 61);
}

/// Convert Gregorian date to day of week
///
/// Given a `year, month, day` returns the day of week. Day of week is
/// given as `u32` number between 1 and 7, with `1` meaning Monday and `7`
/// meaning Sunday.
///
/// # Panics
///
/// Year must be between [YEAR_MIN] and [YEAR_MAX]. Month must be between `1`
/// and `12`. Day must be between `1` and the number of days in the month in
/// question. Bounds are checked using `std.debug.assert` only, so that the checks
/// are not present in release builds, similar to integer overflow checks.
///
/// # Examples
///
/// ```
/// try expectEqual(date_to_weekday(2023, 5, 12)), 5);
/// try expectEqual(date_to_weekday(1970, 1, 1)), 4);
/// try expectEqual(date_to_weekday(2023, 1, 1)), 7);
/// ```
///
/// If you wish to instead have a value from `0` to `6` with `0` signifying a
/// Sunday, it is easiest to just add `% 7`:
///
/// ```
/// try expectEqual(date_to_weekday(2023, 1, 1)) % 7, 0);
/// try expectEqual(date_to_weekday(2023, 5, 12)) % 7, 5);
/// ```
///
/// # Algorithm
///
/// Simply converts date to rata die and then rata die to weekday.
///
pub fn date_to_weekday(y: i32, m: u8, d: u8) u8 {
    const rd = date_to_rd(y, m, d);
    return rd_to_weekday(rd);
}

/// Calculate next Gregorian date given a Gregorian date
///
/// Given a `year, month, day`  returns the `(year, month, day)` tuple
/// for the following Gregorian date.
///
/// # Panics
///
/// Year must be between [YEAR_MIN] and [YEAR_MAX]. Month must be between `1`
/// and `12`. Day must be between `1` and the number of days in the month in
/// question and the next date must not be after [YEAR_MAX]. Bounds are checked
/// using `std.debug.assert` only, so that the checks are not present in release
/// builds, similar to integer overflow checks.
///
/// # Examples
///
/// ```
/// try expectEqual(next_date(2023, 5, 12)), .{2023, 5, 13});
/// try expectEqual(next_date(1970, 1, 1)), .{1970, 1, 2});
/// try expectEqual(next_date(2023, 1, 31)), .{2023, 2, 1});
/// try expectEqual(next_date(2023, 12, 31)), .{2024, 1, 1});
/// ```
///
/// # Algorithm
///
/// Simple incrementation with manual overflow checking and carry. Relatively
/// speedy, but not fully optimized.
pub fn next_date(y: i32, m: u8, d: u8) struct { i32, u8, u8 } {
    std.debug.assert(y >= YEAR_MIN and y <= YEAR_MAX); //given year is out of range");
    std.debug.assert(m >= consts.MONTH_MIN and m <= consts.MONTH_MAX); //given month is out of range");
    std.debug.assert(d >= consts.DAY_MIN and d <= days_in_month(y, m)); //given day is out of range");
    std.debug.assert(y != YEAR_MAX or m != consts.MONTH_MAX or d != consts.DAY_MAX); // "next date is out of range"
    return if (d < 28 or d < days_in_month(y, m))
        .{ y, m, d + 1 }
    else if (m < 12)
        .{ y, m + 1, 1 }
    else
        .{ y + 1, 1, 1 };
}

/// Calculate previous Gregorian date given a Gregorian date
///
/// Given a `year, month, day`  returns the `(year, month, day)` tuple
/// for the preceding Gregorian date.
///
/// # Panics
///
/// Year must be between [YEAR_MIN] and [YEAR_MAX]. Month must be between `1`
/// and `12`. Day must be between `1`, the number of days in the month in
/// question and the previous date must not be before [YEAR_MIN]. Bounds are
/// checked using `std.debug.assert` only, so that the checks are not present in
/// release builds, similar to integer overflow checks.
///
/// # Examples
///
/// ```
/// try expectEqual(prev_date(2023, 5, 12)), .{2023, 5, 11});
/// try expectEqual(prev_date(1970, 1, 1)), .{1969, 12, 31});
/// try expectEqual(prev_date(2023, 2, 1)), .{2023, 1, 31});
/// try expectEqual(prev_date(2024, 1, 1)), .{2023, 12, 31});
/// ```
///
/// # Algorithm
///
/// Simple decrementation with manual underflow checking and carry. Relatively
/// speedy, but not fully optimized.
pub fn prev_date(y: i32, m: u8, d: u8) struct { i32, u8, u8 } {
    std.debug.assert(y >= YEAR_MIN and y <= YEAR_MAX); //given year is out of range");
    std.debug.assert(m >= consts.MONTH_MIN and m <= consts.MONTH_MAX); //given month is out of range");
    std.debug.assert(d >= consts.DAY_MIN and d <= days_in_month(y, m)); //given day is out of range");
    std.debug.assert(y != YEAR_MIN or m != consts.MONTH_MIN or d != consts.DAY_MIN); // "previous date is out of range"
    return if (d > 1)
        .{ y, m, d - 1 }
    else if (m > 1)
        .{ y, m - 1, days_in_month(y, m - 1) }
    else
        .{ y - 1, 12, 31 };
}

/// Split total seconds to days, hours, minutes and seconds
///
/// Given seconds counting from Unix epoch (January 1st, 1970) returns a `(days,
/// hours, minutes, seconds)` tuple.
///
/// # Panics
///
/// Argument must be between [RD_SECONDS_MIN] and [RD_SECONDS_MAX] inclusive.
/// Bounds are checked using `std.debug.assert` only, so that the checks are not
/// present in release builds, similar to integer overflow checks.
///
/// # Examples
///
/// ```
/// try expectEqual(secs_to_dhms(0), .{0, 0, 0, 0});
/// try expectEqual(secs_to_dhms(86400), .{1, 0, 0, 0});
/// try expectEqual(secs_to_dhms(86399), .{0, 23, 59, 59});
/// try expectEqual(secs_to_dhms(-1), .{-1, 23, 59, 59});
/// try expectEqual(secs_to_dhms(1684574678), .{date_to_rd(2023, 5, 20)), 9, 24, 38});
/// ```
///
/// # Algorithm
///
/// See examples 14 and 15 of:
///
/// > Neri C, Schneider L. "*Euclidean affine functions and their application to
/// > calendar algorithms*". Softw Pract Exper. 2022;1-34. doi:
/// > [10.1002/spe.3172](https://onlinelibrary.wiley.com/doi/full/10.1002/spe.3172).
pub fn secs_to_dhms(secs0: i64) struct { i32, u8, u8, u8 } {
    std.debug.assert(secs0 >= RD_SECONDS_MIN and secs0 <= RD_SECONDS_MAX); // "given seconds value is out of range"
    // Algorithm is based on the following identities valid for all n in [0, 97612919[.
    //
    // n / 60 = 71582789 * n / 2^32,
    // n % 60 = 71582789 * n % 2^32 / 71582789.
    //
    // `SECS_IN_DAY` obviously fits within these bounds
    const secs1 = if (secs0 > RD_SECONDS_MAX) 0 else secs0; // allows compiler to optimize more
    const secs2: u64 = @intCast(secs1 +% SECS_OFFSET);
    const days1: i32 = @intCast(@divTrunc(secs2, SECS_IN_DAY));
    const secs3 = secs2 % SECS_IN_DAY; // secs in [0, SECS_IN_DAY[ => secs in [0, 97612919[

    const prd1 = 71582789 * secs3;
    const mins = prd1 >> 32; // secs / 60
    const ss = @as(u32, @truncate(prd1)) / 71582789; // secs % 60

    const prd2 = 71582789 * mins;
    const hh = prd2 >> 32; // mins / 60
    const mm = @as(u32, @truncate(prd2)) / 71582789; // mins % 60

    const days = days1 -% DAY_OFFSET;
    return .{ days, @truncate(hh), @truncate(mm), @truncate(ss) };
}

/// Combine days, hours, minutes and seconds to total seconds
///
/// Given a `(days, hours, minutes, seconds)` tuple from Unix epoch (January
/// 1st, 1970) returns the total seconds.
///
/// # Panics
///
/// Days must be between [RD_MIN] and [RD_MAX] inclusive. Hours must be between
/// `0` and `23`. Minutes must be between `0` and `59`. Seconds must be between
/// `0` and `59`. Bounds are checked using `std.debug.assert` only, so that the
/// checks are not present in release builds, similar to integer overflow
/// checks.
///
/// # Examples
///
/// ```
/// try expectEqual(dhms_to_secs(0, 0, 0, 0), 0);
/// try expectEqual(dhms_to_secs(1, 0, 0, 0), 86400);
/// try expectEqual(dhms_to_secs(0, 23, 59, 59), 86399);
/// try expectEqual(dhms_to_secs(-1, 0, 0, 0), -86400);
/// try expectEqual(dhms_to_secs(-1, 0, 0, 1), -86399);
/// try expectEqual(dhms_to_secs(date_to_rd(2023, 5, 20)), 9, 24, 38)), 1684574678)
/// ```
///
/// # Algorithm
///
/// Algorithm is simple multiplication, method provided only as convenience.
pub fn dhms_to_secs(d: i32, h: u8, m: u8, s: u8) i64 {
    std.debug.assert(d >= RD_MIN and d <= RD_MAX); //given rata die is out of range");
    std.debug.assert(h >= consts.HOUR_MIN and h <= consts.HOUR_MAX); //given hour is out of range");
    std.debug.assert(m >= consts.MINUTE_MIN and m <= consts.MINUTE_MAX); //given minute is out of range");
    std.debug.assert(s >= consts.SECOND_MIN and s <= consts.SECOND_MAX); //given second is out of range");
    return if (d >= RD_MIN and d <= RD_MAX)
        d * SECS_IN_DAY + @as(i32, h) * 3600 + @as(i32, m) * 60 + s
    else
        0;
}

/// Convert total seconds to year, month, day, hours, minutes and seconds
///
/// Given seconds counting from Unix epoch (January 1st, 1970) returns a `(year,
/// month, day, hours, minutes, seconds)` tuple.
///
/// # Panics
///
/// Argument must be between [RD_SECONDS_MIN] and [RD_SECONDS_MAX] inclusive.
/// Bounds are checked using `std.debug.assert` only, so that the checks are not
/// present in release builds, similar to integer overflow checks.
///
/// # Examples
///
/// ```
/// try expectEqual(secs_to_datetime(0), .{1970, 1, 1, 0, 0, 0});
/// try expectEqual(secs_to_datetime(86400), .{1970, 1, 2, 0, 0, 0});
/// try expectEqual(secs_to_datetime(86399), .{1970, 1, 1, 23, 59, 59});
/// try expectEqual(secs_to_datetime(-1), .{1969, 12, 31, 23, 59, 59});
/// try expectEqual(secs_to_datetime(1684574678), .{2023, 5, 20, 9, 24, 38});
/// ```
///
/// # Algorithm
///
/// Combination of existing functions for convenience only.
pub fn secs_to_datetime(secs: i64) struct { i32, u8, u8, u8, u8, u8 } {
    const days, const hh, const mm, const ss = secs_to_dhms(secs);
    const y, const m, const d = rd_to_date(days);
    return .{ y, m, d, hh, mm, ss };
}

/// Convert year, month, day, hours, minutes and seconds to total seconds
///
/// Given a `(year, month, day, hours, minutes, seconds)` tuple from Unix epoch
/// (January 1st, 1970) returns the total seconds.
///
/// # Panics
///
/// Year must be between [YEAR_MIN] and [YEAR_MAX]. Month must be between `1`
/// and `12`. Day must be between `1` and the number of days in the month in
/// question. Hours must be between `0` and `23`. Minutes must be between `0`
/// and `59`. Seconds must be between `0` and `59`. Bounds are checked using
/// `std.debug.assert` only, so that the checks are not present in release builds,
/// similar to integer overflow checks.
///
/// # Examples
///
/// ```
/// try expectEqual(datetime_to_secs(1970, 1, 1, 0, 0, 0), 0);
/// try expectEqual(datetime_to_secs(1970, 1, 2, 0, 0, 0), 86400);
/// try expectEqual(datetime_to_secs(1970, 1, 1, 23, 59, 59), 86399);
/// try expectEqual(datetime_to_secs(1969, 12, 31, 0, 0, 0), -86400);
/// try expectEqual(datetime_to_secs(1969, 12, 31, 0, 0, 1), -86399);
/// try expectEqual(datetime_to_secs(2023, 5, 20, 9, 24, 38), 1684574678)
/// ```
///
/// # Algorithm
///
/// Algorithm is simple multiplication, method provided only as convenience.
pub fn datetime_to_secs(y: i32, m: u8, d: u8, hh: u8, mm: u8, ss: u8) i64 {
    const days = date_to_rd(y, m, d);
    return dhms_to_secs(days, hh, mm, ss);
}

/// Determine if the given year is a leap year
///
/// # Panics
///
/// Year must be between [YEAR_MIN] and [YEAR_MAX] inclusive. Bounds are checked
/// using `std.debug.assert` only, so that the checks are not present in release
/// builds, similar to integer overflow checks.
///
/// # Examples
///
/// ```
/// try expectEqual(is_leap_year(2023), false);
/// try expectEqual(is_leap_year(2024), true);
/// try expectEqual(is_leap_year(2100), false);
/// try expectEqual(is_leap_year(2400), true);
/// ```
///
/// # Algorithm
///
/// Algorithm is Neri-Schneider from C++now 2023 conference:
/// > https://github.com/boostcon/cppnow_presentations_2023/blob/main/cppnow_slides/Speeding_Date_Implementing_Fast_Calendar_Algorithms.pdf
pub fn is_leap_year(y: i32) bool {
    std.debug.assert(y >= YEAR_MIN and y <= YEAR_MAX); //given year is out of range");
    // Using `%` instead of `&` causes compiler to emit branches instead. This
    // is faster in a tight loop due to good branch prediction, but probably
    // slower in a real program so we use `&`. Also `% 25` is functionally
    // equivalent to `% 100` here, but a little cheaper to compute. If branches
    // were to be emitted, using `% 100` would be most likely faster due to
    // better branch prediction.
    return if (@mod(y, 25) != 0)
        y & 3 == 0
    else
        y & 15 == 0;
}

/// Determine the number of days in the given month in the given year
///
/// # Panics
///
/// Year must be between [YEAR_MIN] and [YEAR_MAX]. Month must be between `1`
/// and `12`. Bounds are checked using `std.debug.assert` only, so that the checks
/// are not present in release builds, similar to integer overflow checks.
///
/// # Example
///
/// ```
/// try expectEqual(days_in_month(2023, 1), 31);
/// try expectEqual(days_in_month(2023, 2), 28);
/// try expectEqual(days_in_month(2023, 4), 30);
/// try expectEqual(days_in_month(2024, 1), 31);
/// try expectEqual(days_in_month(2024, 2), 29);
/// try expectEqual(days_in_month(2024, 4), 30);
/// ```
///
/// # Algorithm
///
/// Algorithm is Neri-Schneider from C++now 2023 conference:
/// > https://github.com/boostcon/cppnow_presentations_2023/blob/main/cppnow_slides/Speeding_Date_Implementing_Fast_Calendar_Algorithms.pdf
pub fn days_in_month(y: i32, m: u8) u8 {
    std.debug.assert(m >= consts.MONTH_MIN and m <= consts.MONTH_MAX); //given month is out of range");
    return if (m != 2)
        30 | (m ^ (m >> 3))
    else if (is_leap_year(y))
        29
    else
        28;
}

/// Convert Rata Die to [ISO week date](https://en.wikipedia.org/wiki/ISO_week_date)
///
/// Given a day counting from Unix epoch (January 1st, 1970) returns a `(year,
/// week, day of week)` tuple. Week is the ISO week number, with the first week
/// of the year being the week containing the first Thursday of the year. Day of
/// week is between 1 and 7, with `1` meaning Monday and `7` meaning Sunday.
///
/// Compared to Gregorian date, the first one to three days of the year might
/// belong to a week in the previous year, and the last one to three days of the
/// year might belong to a week in the next year. Also some years have 53 weeks
/// instead of 52.
///
/// # Panics
///
/// Argument must be between [RD_MIN] and [RD_MAX] inclusive. Bounds are checked
/// using `std.debug.assert` only, so that the checks are not present in release
/// builds, similar to integer overflow checks.
///
/// # Examples
///
/// ```
/// try expectEqual(rd_to_isoweekdate(date_to_rd(2023, 5, 12)), .{2023, 19, 5});
/// try expectEqual(rd_to_isoweekdate(date_to_rd(1970, 1, 1)), .{1970, 1, 4});
/// try expectEqual(rd_to_isoweekdate(date_to_rd(2023, 1, 1)), .{2022, 52, 7});
/// try expectEqual(rd_to_isoweekdate(date_to_rd(1979, 12, 31)), .{1980, 1, 1});
/// try expectEqual(rd_to_isoweekdate(date_to_rd(1981, 12, 31)), .{1981, 53, 4});
/// try expectEqual(rd_to_isoweekdate(date_to_rd(1982, 1, 1)), .{1981, 53, 5});
/// ```
///
/// # Algorithm
///
/// Algorithm is hand crafted and not significantly optimized.
pub fn rd_to_isoweekdate(rd: i32) struct { i32, u8, u8 } {
    std.debug.assert(rd >= RD_MIN and rd <= RD_MAX); //given rata die is out of range");
    const wd = rd_to_weekday(rd);
    const rdt = rd + @rem(4 - @as(i32, wd), 7);
    const y, _, _ = rd_to_date(rdt);
    const ys = date_to_rd(y, 1, 1);
    const w: u8 = @truncate(@as(u32, @bitCast(@divTrunc(rdt - ys, 7) + 1)));
    return .{ y, w, wd };
}

/// Convert [ISO week date](https://en.wikipedia.org/wiki/ISO_week_date) to Rata Die
///
/// Given a `(year, week, day of week)` tuple returns the days since Unix epoch
/// (January 1st, 1970). Week is the ISO week number, with the first week of the
/// year being the week containing the first Thursday of the year. Day of week
/// is between 1 and 7, with `1` meaning Monday and `7` meaning Sunday. Dates
/// before the epoch produce negative values.
///
/// Compared to Gregorian date, the first one to three days of the year might
/// belong to a week in the previous year, and the last one to three days of the
/// year might belong to a week in the next year. Also some years have 53 weeks
/// instead of 52.
///
/// # Panics
///
/// Year must be between [YEAR_MIN] and [YEAR_MAX]. Week must be between `1` and
/// the number of ISO weeks in the given year (52 or 53). Day must be between
/// `1` and `7`. Bounds are checked using `std.debug.assert` only, so that the
/// checks are not present in release builds, similar to integer overflow
/// checks.
///
/// # Examples
///
/// ```
/// try expectEqual(isoweekdate_to_rd(2023, 19, 5), date_to_rd(2023, 5, 12));
/// try expectEqual(isoweekdate_to_rd(1970, 1, 4), date_to_rd(1970, 1, 1));
/// try expectEqual(isoweekdate_to_rd(2022, 52, 7), date_to_rd(2023, 1, 1));
/// try expectEqual(isoweekdate_to_rd(1980, 1, 1), date_to_rd(1979, 12, 31));
/// try expectEqual(isoweekdate_to_rd(1981, 53, 4), date_to_rd(1981, 12, 31));
/// try expectEqual(isoweekdate_to_rd(1981, 53, 5), date_to_rd(1982, 1, 1));
/// ```
///
/// # Algorithm
///
/// Algorithm is hand crafted and not significantly optimized.
pub fn isoweekdate_to_rd(y: i32, w: u8, d: u8) i32 {
    std.debug.assert(y >= YEAR_MIN and y <= YEAR_MAX); //given year is out of range");
    std.debug.assert(w >= consts.WEEK_MIN and w <= isoweeks_in_year(y)); //given week is out of range");
    std.debug.assert(d >= consts.WEEKDAY_MIN and d <= consts.WEEKDAY_MAX); // "given weekday is out of range"
    const rd4 = date_to_rd(y, 1, 4);
    const wd4 = rd_to_weekday(rd4);
    const ys = rd4 - @as(i32, wd4 - 1);
    return ys + (@as(i32, w) - 1) * 7 + (@as(i32, d) - 1);
}

/// Convert Gregorian date to [ISO week date](https://en.wikipedia.org/wiki/ISO_week_date)
///
/// Given a `year, month, day`  returns a `(year, week, day of week)`
/// tuple. Week is the ISO week number, with the first week of the year being
/// the week containing the first Thursday of the year. Day of week is between
/// 1 and 7, with `1` meaning Monday and `7` meaning Sunday.
///
/// Compared to Gregorian date, the first one to three days of the year might
/// belong to a week in the previous year, and the last one to three days of the
/// year might belong to a week in the next year. Also some years have 53 weeks
/// instead of 52.
///
/// # Panics
///
/// Year must be between [YEAR_MIN] and [YEAR_MAX]. Month must be between `1`
/// and `12`. Day must be between `1` and the number of days in the month in
/// question. Bounds are checked using `std.debug.assert` only, so that the checks
/// are not present in release builds, similar to integer overflow checks.
///
/// # Examples
///
/// ```
/// try expectEqual(date_to_isoweekdate(2023, 5, 12), .{2023, 19, 5});
/// try expectEqual(date_to_isoweekdate(1970, 1, 1), .{1970, 1, 4});
/// try expectEqual(date_to_isoweekdate(2023, 1, 1), .{2022, 52, 7});
/// try expectEqual(date_to_isoweekdate(1979, 12, 31), .{1980, 1, 1});
/// try expectEqual(date_to_isoweekdate(1981, 12, 31), .{1981, 53, 4});
/// try expectEqual(date_to_isoweekdate(1982, 1, 1), .{1981, 53, 5});
/// ```
///
/// # Algorithm
///
/// Simply converts date to rata die and then rata die to ISO week date.
pub fn date_to_isoweekdate(y: i32, m: u8, d: u8) struct { i32, u8, u8 } {
    const rd = date_to_rd(y, m, d);
    return rd_to_isoweekdate(rd);
}

/// Convert [ISO week date](https://en.wikipedia.org/wiki/ISO_week_date) to Gregorian date
///
/// Given a `(year, week, day of week)` tuple returns a `(year, month, day)`
/// tuple. Week is the ISO week number, with the first week of the year being
/// the week containing the first Thursday of the year. Day of week is between
/// 1 and 7, with `1` meaning Monday and `7` meaning Sunday.
///
/// Compared to Gregorian date, the first one to three days of the year might
/// belong to a week in the previous year, and the last one to three days of the
/// year might belong to a week in the next year. Also some years have 53 weeks
/// instead of 52.
///
/// # Panics
///
/// Year must be between [YEAR_MIN] and [YEAR_MAX]. Week must be between `1` and
/// the number of ISO weeks in the given year (52 or 53). Day must be between
/// `1` and `7`. Bounds are checked using `std.debug.assert` only, so that the
/// checks are not present in release builds, similar to integer overflow
/// checks.
///
/// # Examples
///
/// ```
/// try expectEqual(isoweekdate_to_date(2023, 19, 5), .{2023, 5, 12});
/// try expectEqual(isoweekdate_to_date(1970, 1, 4), .{1970, 1, 1});
/// try expectEqual(isoweekdate_to_date(2022, 52, 7), .{2023, 1, 1});
/// try expectEqual(isoweekdate_to_date(1980, 1, 1), .{1979, 12, 31});
/// try expectEqual(isoweekdate_to_date(1981, 53, 4), .{1981, 12, 31});
/// try expectEqual(isoweekdate_to_date(1981, 53, 5), .{1982, 1, 1});
/// ```
///
/// # Algorithm
///
/// Simply converts ISO week date to rata die and then rata die to date.
pub fn isoweekdate_to_date(y: i32, w: u8, d: u8) struct { i32, u8, u8 } {
    const rd = isoweekdate_to_rd(y, w, d);
    return rd_to_date(rd);
}

/// Determine the number of [ISO weeks](https://en.wikipedia.org/wiki/ISO_week_date) in the given year
///
/// According to the ISO standard a year has 52 weeks, unless the first week of
/// the year starts on a Thursday or the year is a leap year and the first week
/// of the year starts on a Wednesday, in which case the year has 53 weeks.
///
/// # Panics
///
/// Year must be between [YEAR_MIN] and [YEAR_MAX]. Bounds are checked using
/// `std.debug.assert` only, so that the checks are not present in release builds,
/// similar to integer overflow checks.
///
/// # Examples
///
/// ```
/// try expectEqual(isoweeks_in_year(2023), 52);
/// try expectEqual(isoweeks_in_year(2024), 52);
/// try expectEqual(isoweeks_in_year(2025), 52);
/// try expectEqual(isoweeks_in_year(2026), 53);
/// try expectEqual(isoweeks_in_year(2027), 52);
/// ```
///
/// # Algorithm
///
/// Algorithm is hand crafted and not significantly optimized.
pub fn isoweeks_in_year(y: i32) u8 {
    std.debug.assert(y >= YEAR_MIN and y <= YEAR_MAX); //given year is out of range");
    const wd = date_to_weekday(y, 1, 1);
    const l = is_leap_year(y);
    return switch (wd) {
        consts.THURSDAY => 53,
        consts.WEDNESDAY => if (l) 53 else 52,
        else => 52,
    };
}

/// Convert [`std.time.Instant`] to seconds and nanoseconds
///
/// Given [`std.time.Instant`] returns an `Option` of `(seconds,
/// nanoseconds)` tuple from Unix epoch (January 1st, 1970).
///
/// # Errors
///
/// Returns `None` if the time is before [RD_SECONDS_MIN] or after
/// [RD_SECONDS_MAX].
///
/// # Examples
///
/// ```
/// try expectEqual(systemtime_to_secs(UNIX_EPOCH), .{0, 0};
/// try expectEqual(systemtime_to_secs(instant_from_secs_ns(1, 0)), .{1, 0};
/// try expectEqual(systemtime_to_secs(instant_from_secs_ns(0, 1)), .{0, 1};
/// try expectEqual(systemtime_to_secs(sub_instants(UNIX_EPOCH, instant_from_secs_ns(1, 0))), .{-1, 0};
/// try expectEqual(systemtime_to_secs(sub_instants(UNIX_EPOCH, instant_from_secs_ns(0, 1))), .{-1, 999_999_999};
/// ```
///
/// # Algorithm
///
/// Uses `.duration_since(UNIX_EPOCH)` and handles both positive and negative
/// result.
pub fn instant_to_secs(instant: Instant) ?struct { i64, u32 } {
    switch (instant.order(UNIX_EPOCH)) {
        .gt, .eq => {
            const dur = sub_instants(instant, UNIX_EPOCH);
            if (is_posix) {
                const secs: i64 = dur.timestamp.tv_sec;
                const nsecs: u32 = @intCast(dur.timestamp.tv_nsec);
                if (secs > RD_SECONDS_MAX) return null;
                return .{ secs, nsecs };
            } else {
                // TODO non posix
                if (true) unreachable;
                if (dur.timestamp > std.time.ns_per_s) {
                    return .{ @intCast(dur.timestamp / std.time.ns_per_s), @intCast(dur.timestamp % std.time.ns_per_s) };
                } else return .{ 0, @intCast(dur.timestamp) };
            }
        },
        else => {
            const dur = sub_instants(UNIX_EPOCH, instant);
            if (is_posix) {
                var secs: i64 = dur.timestamp.tv_sec;
                var nsecs: u32 = @intCast(dur.timestamp.tv_nsec);
                if (nsecs > 0) {
                    secs += 1;
                    nsecs = 1_000_000_000 - nsecs;
                }
                if (secs > -RD_SECONDS_MIN) return null;
                return .{ -secs, nsecs };
            } else {
                // TODO non posix
                unreachable;
            }
        },
    }
}

/// Convert seconds and nanoseconds to [`std.time.Instant`]
///
/// Given a tuple of seconds and nanoseconds counting from Unix epoch (January
/// 1st, 1970) returns Option of [`std.time.Instant`].
///
/// # Errors
///
/// Returns `None` if given datetime cannot be represented as `Instant`.
///
/// # Panics
///
/// Seconds must be between [RD_SECONDS_MIN] and [RD_SECONDS_MAX] inclusive.
/// Nanoseconds must between `0` and `999_999_999`. Bounds are checked using
/// `std.debug.assert` only, so that the checks are not present in release builds,
/// similar to integer overflow checks.
///
/// # Examples
///
/// ```
/// try expectEqual(secs_to_systemtime(0, 0), UNIX_EPOCH);
/// try expectEqual(secs_to_systemtime(0, 1), instant_from_secs_ns(0, 1));
/// try expectEqual(secs_to_systemtime(1, 0), instant_from_secs_ns(1, 0));
/// try expectEqual(secs_to_systemtime(-1, 999_999_999), sub_instants(UNIX_EPOCH(instant_from_secs_ns(0, 1))));
/// try expectEqual(secs_to_systemtime(-1, 0), sub_instants(UNIX_EPOCH(instant_from_secs_ns(1, 0))));
/// try expectEqual(secs_to_systemtime(-2, 999_999_999), sub_instants(UNIX_EPOCH(instant_from_secs_ns(1, 1))));
/// ```
///
/// # Algorithm
///
/// Combination of existing functions for convenience only.
pub fn secs_to_systemtime(secs: i64, nsecs: u32) ?Instant {
    std.debug.assert(secs >= RD_SECONDS_MIN and secs <= RD_SECONDS_MAX); //given seconds is out of range");
    std.debug.assert(nsecs >= consts.NANOSECOND_MIN and nsecs <= consts.NANOSECOND_MAX); // "given nanoseconds is out of range"
    return if (secs >= 0)
        instant_from_secs_ns(secs, nsecs)
    else if (nsecs > 0)
        sub_instants(UNIX_EPOCH, instant_from_secs_ns(-secs - 1, 1_000_000_000 - nsecs))
    else
        sub_instants(UNIX_EPOCH, instant_from_secs(-secs));
}

/// Convert [`std.time.Instant`] to year, month, day, hours, minutes,
/// seconds and nanoseconds
///
/// Given [`std.time.Instant`] returns an Option of `(year, month, day,
/// hours, minutes, seconds, nanoseconds)` tuple.
///
/// # Errors
///
/// Returns `None` if the time is before [RD_SECONDS_MIN] or after
/// [RD_SECONDS_MAX].
///
/// # Examples
///
/// ```
/// try expectEqual(systemtime_to_datetime(UNIX_EPOCH), .{1970, 1, 1, 0, 0, 0, 0});
/// try expectEqual(systemtime_to_datetime(instant_from_secs(1684574678)), .{2023, 5, 20, 9, 24, 38, 0});
/// try expectEqual(systemtime_to_datetime(sub_instants(UNIX_EPOCH, instant_from_secs(1))), .{1969, 12, 31, 23, 59, 59, 0});
/// try expectEqual(systemtime_to_datetime(sub_instants(UNIX_EPOCH, instant_from_secs_ns(0, 1))), .{1969, 12, 31, 23, 59, 59, 999_999_999});
/// ```
///
/// # Algorithm
///
/// Combination of existing functions for convenience only.
pub fn systemtime_to_datetime(st: Instant) ?struct { i32, u8, u8, u8, u8, u8, u32 } {
    const secs, const nsecs = instant_to_secs(st) orelse return null;
    const days, const hh, const mm, const ss = secs_to_dhms(secs);
    const year, const month, const day = rd_to_date(days);
    return .{ year, month, day, hh, mm, ss, nsecs };
}

/// Convert year, month, day, hours, minutes, seconds and nanoseconds to
/// [`std.time.Instant`]
///
/// Given a `year, month, day, hours, minutes, seconds, nanoseconds`
/// from Unix epoch (January 1st, 1970) returns Option of
/// [`std.time.Instant`].
///
/// # Errors
///
/// Returns `None` if given datetime cannot be represented as `Instant`.
///
/// # Panics
///
/// Year must be between [YEAR_MIN] and [YEAR_MAX]. Month must be between `1`
/// and `12`. Day must be between `1` and the number of days in the month in
/// question. Hours must be between `0` and `23`. Minutes must be between `0`
/// and `59`. Seconds must be between `0` and `59`. Nanoseconds must be between
/// `0` and `999_999_999`. Bounds are checked using `std.debug.assert` only, so that
/// the checks are not present in release builds, similar to integer overflow
/// checks.
///
/// # Algorithm
///
/// Combination of existing functions for convenience only.
pub fn datetime_to_systemtime(y: i32, m: u8, d: u8, hh: u8, mm: u8, ss: u8, nsec: u32) ?Instant {
    const days = date_to_rd(y, m, d);
    const secs = dhms_to_secs(days, hh, mm, ss);
    return secs_to_systemtime(secs, nsec);
}

const std = @import("std");
