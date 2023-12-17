//!
//! this file was ported directly from
//! https://github.com/nakedible/datealgo-rs/blob/master/tests/api.rs
//!

const std = @import("std");

const date = @import("date-zig");
const UNIX_EPOCH = date.UNIX_EPOCH;
const ymd = date.Ymd.init;
pub fn expectEqual(a: anytype, b: anytype) !void {
    const T = @TypeOf(a, b);
    return std.testing.expectEqual(@as(T, b), @as(T, a));
}

test "constants" {
    try expectEqual(date.RD_MIN, -536895152);
    try expectEqual(date.RD_MAX, 536824295);
    try expectEqual(date.RD_SECONDS_MIN, -46387741132800);
    try expectEqual(date.RD_SECONDS_MAX, 46381619174399);
}

const date_to_rd = date.date_to_rd;
test date_to_rd {
    try expectEqual(date_to_rd(0, 3, 1), -719468);
    try expectEqual(date_to_rd(1970, 1, 1), 0);
    try expectEqual(date_to_rd(@as(i32, std.math.minInt(i16)), 1, 1), -12687794);
    try expectEqual(date_to_rd(@as(i32, std.math.maxInt(i16)), 12, 31), 11248737);
    try expectEqual(date_to_rd(@as(i32, std.math.minInt(i16)) - 1, 1, 1), -12688159);
    try expectEqual(date_to_rd(@as(i32, std.math.maxInt(i16)) + 1, 12, 31), 11249103);
}

const rd_to_date = date.rd_to_date;
test rd_to_date {
    try expectEqual(rd_to_date(-719468), ymd(0, 3, 1));
    try expectEqual(rd_to_date(0), ymd(1970, 1, 1));
    try expectEqual(rd_to_date(-12687794), ymd(@as(i32, std.math.minInt(i16)), 1, 1));
    try expectEqual(rd_to_date(11248737), ymd(@as(i32, std.math.maxInt(i16)), 12, 31));
    try expectEqual(rd_to_date(-12687795), ymd(@as(i32, std.math.minInt(i16)) - 1, 12, 31));
    try expectEqual(rd_to_date(11248738), ymd(@as(i32, std.math.maxInt(i16)) + 1, 1, 1));
}

const rd_to_weekday = date.rd_to_weekday;
test rd_to_weekday {
    try expectEqual(rd_to_weekday(date.RD_MIN), 1);
    try expectEqual(rd_to_weekday(date.RD_MAX), 4);
    try expectEqual(rd_to_weekday(-719468), 3);
    try expectEqual(rd_to_weekday(-4), 7);
    try expectEqual(rd_to_weekday(-3), 1);
    try expectEqual(rd_to_weekday(-2), 2);
    try expectEqual(rd_to_weekday(-1), 3);
    try expectEqual(rd_to_weekday(0), 4);
    try expectEqual(rd_to_weekday(1), 5);
    try expectEqual(rd_to_weekday(2), 6);
    try expectEqual(rd_to_weekday(3), 7);
    try expectEqual(rd_to_weekday(4), 1);
    try expectEqual(rd_to_weekday(5), 2);
    try expectEqual(rd_to_weekday(6), 3);
    try expectEqual(rd_to_weekday(19489), 5);
}

const date_to_weekday = date.date_to_weekday;
test date_to_weekday {
    try expectEqual(date_to_weekday(1970, 1, 1), 4);
    try expectEqual(date_to_weekday(2023, 1, 1), 7);
    try expectEqual(date_to_weekday(2023, 2, 1), 3);
    try expectEqual(date_to_weekday(2023, 3, 1), 3);
    try expectEqual(date_to_weekday(2023, 4, 1), 6);
    try expectEqual(date_to_weekday(2023, 5, 1), 1);
    try expectEqual(date_to_weekday(2023, 6, 1), 4);
    try expectEqual(date_to_weekday(2023, 7, 1), 6);
    try expectEqual(date_to_weekday(2023, 8, 1), 2);
    try expectEqual(date_to_weekday(2023, 9, 1), 5);
    try expectEqual(date_to_weekday(2023, 10, 1), 7);
    try expectEqual(date_to_weekday(2023, 11, 1), 3);
    try expectEqual(date_to_weekday(2023, 12, 1), 5);
    try expectEqual(date_to_weekday(2023, 2, 28), 2);
    try expectEqual(date_to_weekday(2020, 2, 29), 6);
    try expectEqual(date_to_weekday(0, 1, 1), 6);
    try expectEqual(date_to_weekday(-1, 1, 1), 5);
    try expectEqual(date_to_weekday(-4, 1, 1), 1);
    try expectEqual(date_to_weekday(-100, 1, 1), 1);
    try expectEqual(date_to_weekday(-400, 1, 1), 6);
}

const next_date = date.next_date;
test next_date {
    try expectEqual(next_date(2021, 1, 1), ymd(2021, 1, 2));
    try expectEqual(next_date(-2021, 1, 1), ymd(-2021, 1, 2));
    try expectEqual(next_date(2021, 2, 28), ymd(2021, 3, 1));
    try expectEqual(next_date(2021, 4, 30), ymd(2021, 5, 1));
    try expectEqual(next_date(2021, 5, 31), ymd(2021, 6, 1));
    try expectEqual(next_date(2021, 1, 31), ymd(2021, 2, 1));
    try expectEqual(next_date(2021, 12, 31), ymd(2022, 1, 1));
    try expectEqual(next_date(2020, 2, 28), ymd(2020, 2, 29));
    try expectEqual(next_date(2020, 2, 29), ymd(2020, 3, 1));
    try expectEqual(next_date(-2020, 2, 28), ymd(-2020, 2, 29));
    try expectEqual(next_date(-2020, 2, 29), ymd(-2020, 3, 1));
}

const prev_date = date.prev_date;
test prev_date {
    try expectEqual(prev_date(2021, 1, 1), ymd(2020, 12, 31));
    try expectEqual(prev_date(-2021, 1, 1), ymd(-2022, 12, 31));
    try expectEqual(prev_date(2021, 3, 1), ymd(2021, 2, 28));
    try expectEqual(prev_date(2021, 5, 1), ymd(2021, 4, 30));
    try expectEqual(prev_date(2021, 6, 1), ymd(2021, 5, 31));
    try expectEqual(prev_date(2021, 2, 1), ymd(2021, 1, 31));
    try expectEqual(prev_date(2022, 1, 1), ymd(2021, 12, 31));
    try expectEqual(prev_date(2020, 2, 29), ymd(2020, 2, 28));
    try expectEqual(prev_date(2020, 3, 1), ymd(2020, 2, 29));
    try expectEqual(prev_date(-2020, 2, 29), ymd(-2020, 2, 28));
    try expectEqual(prev_date(-2020, 3, 1), ymd(-2020, 2, 29));
}

const secs_to_dhms = date.secs_to_dhms;
test secs_to_dhms {
    try expectEqual(secs_to_dhms(date.RD_SECONDS_MIN), .{ date.RD_MIN, 0, 0, 0 });
    try expectEqual(secs_to_dhms(date.RD_SECONDS_MAX), .{ date.RD_MAX, 23, 59, 59 });
}

const dhms_to_secs = date.dhms_to_secs;
test dhms_to_secs {
    try expectEqual(dhms_to_secs(date.RD_MIN, 0, 0, 0), date.RD_SECONDS_MIN);
    try expectEqual(dhms_to_secs(date.RD_MAX, 23, 59, 59), date.RD_SECONDS_MAX);
}

const secs_to_datetime = date.secs_to_datetime;
test secs_to_datetime {
    try expectEqual(secs_to_datetime(date.RD_SECONDS_MIN), .{ date.YEAR_MIN, 1, 1, 0, 0, 0 });
    try expectEqual(secs_to_datetime(date.RD_SECONDS_MAX), .{ date.YEAR_MAX, 12, 31, 23, 59, 59 });
}

const datetime_to_secs = date.datetime_to_secs;
test datetime_to_secs {
    try expectEqual(datetime_to_secs(date.YEAR_MIN, 1, 1, 0, 0, 0), date.RD_SECONDS_MIN);
    try expectEqual(datetime_to_secs(date.YEAR_MAX, 12, 31, 23, 59, 59), date.RD_SECONDS_MAX);
}

const is_leap_year = date.is_leap_year;
test is_leap_year {
    try expectEqual(is_leap_year(0), true);
    try expectEqual(is_leap_year(1), false);
    try expectEqual(is_leap_year(4), true);
    try expectEqual(is_leap_year(100), false);
    try expectEqual(is_leap_year(400), true);
    try expectEqual(is_leap_year(-1), false);
    try expectEqual(is_leap_year(-4), true);
    try expectEqual(is_leap_year(-100), false);
    try expectEqual(is_leap_year(-400), true);
}

const days_in_month = date.days_in_month;
test days_in_month {
    try expectEqual(days_in_month(1, 1), 31);
    try expectEqual(days_in_month(1, 2), 28);
    try expectEqual(days_in_month(1, 3), 31);
    try expectEqual(days_in_month(1, 4), 30);
    try expectEqual(days_in_month(1, 5), 31);
    try expectEqual(days_in_month(1, 6), 30);
    try expectEqual(days_in_month(1, 7), 31);
    try expectEqual(days_in_month(1, 8), 31);
    try expectEqual(days_in_month(1, 9), 30);
    try expectEqual(days_in_month(1, 10), 31);
    try expectEqual(days_in_month(1, 11), 30);
    try expectEqual(days_in_month(1, 12), 31);
    try expectEqual(days_in_month(0, 1), 31);
    try expectEqual(days_in_month(0, 2), 29);
    try expectEqual(days_in_month(0, 3), 31);
    try expectEqual(days_in_month(0, 4), 30);
    try expectEqual(days_in_month(0, 5), 31);
    try expectEqual(days_in_month(0, 6), 30);
    try expectEqual(days_in_month(0, 7), 31);
    try expectEqual(days_in_month(0, 8), 31);
    try expectEqual(days_in_month(0, 9), 30);
    try expectEqual(days_in_month(0, 10), 31);
    try expectEqual(days_in_month(0, 11), 30);
    try expectEqual(days_in_month(0, 12), 31);
    try expectEqual(days_in_month(-1, 1), 31);
    try expectEqual(days_in_month(-1, 2), 28);
    try expectEqual(days_in_month(-1, 3), 31);
    try expectEqual(days_in_month(-1, 4), 30);
    try expectEqual(days_in_month(-1, 5), 31);
    try expectEqual(days_in_month(-1, 6), 30);
    try expectEqual(days_in_month(-1, 7), 31);
    try expectEqual(days_in_month(-1, 8), 31);
    try expectEqual(days_in_month(-1, 9), 30);
    try expectEqual(days_in_month(-1, 10), 31);
    try expectEqual(days_in_month(-1, 11), 30);
    try expectEqual(days_in_month(-1, 12), 31);
    try expectEqual(days_in_month(-4, 1), 31);
    try expectEqual(days_in_month(-4, 2), 29);
    try expectEqual(days_in_month(-4, 3), 31);
    try expectEqual(days_in_month(-4, 4), 30);
    try expectEqual(days_in_month(-4, 5), 31);
    try expectEqual(days_in_month(-4, 6), 30);
    try expectEqual(days_in_month(-4, 7), 31);
    try expectEqual(days_in_month(-4, 8), 31);
    try expectEqual(days_in_month(-4, 9), 30);
    try expectEqual(days_in_month(-4, 10), 31);
    try expectEqual(days_in_month(-4, 11), 30);
    try expectEqual(days_in_month(-4, 12), 31);
}

const rd_to_isoweekdate = date.rd_to_isoweekdate;
test rd_to_isoweekdate {
    try expectEqual(rd_to_isoweekdate(date_to_rd(-4, 12, 30)), ymd(-3, 1, 1));
    try expectEqual(rd_to_isoweekdate(date_to_rd(-4, 12, 31)), ymd(-3, 1, 2));
    try expectEqual(rd_to_isoweekdate(date_to_rd(-3, 1, 1)), ymd(-3, 1, 3));
    try expectEqual(rd_to_isoweekdate(date_to_rd(-1, 12, 31)), ymd(-1, 52, 5));
    try expectEqual(rd_to_isoweekdate(date_to_rd(0, 1, 1)), ymd(-1, 52, 6));
    try expectEqual(rd_to_isoweekdate(date_to_rd(0, 1, 2)), ymd(-1, 52, 7));
    try expectEqual(rd_to_isoweekdate(date_to_rd(0, 1, 3)), ymd(0, 1, 1));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1970, 1, 1)), ymd(1970, 1, 4));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1977, 1, 1)), ymd(1976, 53, 6));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1977, 1, 2)), ymd(1976, 53, 7));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1977, 12, 31)), ymd(1977, 52, 6));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1978, 1, 1)), ymd(1977, 52, 7));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1978, 1, 2)), ymd(1978, 1, 1));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1978, 12, 31)), ymd(1978, 52, 7));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1979, 1, 1)), ymd(1979, 1, 1));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1979, 12, 30)), ymd(1979, 52, 7));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1979, 12, 31)), ymd(1980, 1, 1));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1980, 1, 1)), ymd(1980, 1, 2));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1980, 12, 28)), ymd(1980, 52, 7));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1980, 12, 29)), ymd(1981, 1, 1));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1980, 12, 30)), ymd(1981, 1, 2));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1980, 12, 31)), ymd(1981, 1, 3));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1981, 1, 1)), ymd(1981, 1, 4));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1981, 12, 31)), ymd(1981, 53, 4));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1982, 1, 1)), ymd(1981, 53, 5));
    try expectEqual(rd_to_isoweekdate(date_to_rd(1982, 1, 2)), ymd(1981, 53, 6));
}

const isoweekdate_to_rd = date.isoweekdate_to_rd;
test isoweekdate_to_rd {
    try expectEqual(isoweekdate_to_rd(-3, 1, 1), date_to_rd(-4, 12, 30));
    try expectEqual(isoweekdate_to_rd(-3, 1, 2), date_to_rd(-4, 12, 31));
    try expectEqual(isoweekdate_to_rd(-3, 1, 3), date_to_rd(-3, 1, 1));
    try expectEqual(isoweekdate_to_rd(-1, 52, 5), date_to_rd(-1, 12, 31));
    try expectEqual(isoweekdate_to_rd(-1, 52, 6), date_to_rd(0, 1, 1));
    try expectEqual(isoweekdate_to_rd(-1, 52, 7), date_to_rd(0, 1, 2));
    try expectEqual(isoweekdate_to_rd(0, 1, 1), date_to_rd(0, 1, 3));
    try expectEqual(isoweekdate_to_rd(1970, 1, 4), date_to_rd(1970, 1, 1));
    try expectEqual(isoweekdate_to_rd(1976, 53, 6), date_to_rd(1977, 1, 1));
    try expectEqual(isoweekdate_to_rd(1976, 53, 7), date_to_rd(1977, 1, 2));
    try expectEqual(isoweekdate_to_rd(1977, 52, 6), date_to_rd(1977, 12, 31));
    try expectEqual(isoweekdate_to_rd(1977, 52, 7), date_to_rd(1978, 1, 1));
    try expectEqual(isoweekdate_to_rd(1978, 1, 1), date_to_rd(1978, 1, 2));
    try expectEqual(isoweekdate_to_rd(1978, 52, 7), date_to_rd(1978, 12, 31));
    try expectEqual(isoweekdate_to_rd(1979, 1, 1), date_to_rd(1979, 1, 1));
    try expectEqual(isoweekdate_to_rd(1979, 52, 7), date_to_rd(1979, 12, 30));
    try expectEqual(isoweekdate_to_rd(1980, 1, 1), date_to_rd(1979, 12, 31));
    try expectEqual(isoweekdate_to_rd(1980, 1, 2), date_to_rd(1980, 1, 1));
    try expectEqual(isoweekdate_to_rd(1980, 52, 7), date_to_rd(1980, 12, 28));
    try expectEqual(isoweekdate_to_rd(1981, 1, 1), date_to_rd(1980, 12, 29));
    try expectEqual(isoweekdate_to_rd(1981, 1, 2), date_to_rd(1980, 12, 30));
    try expectEqual(isoweekdate_to_rd(1981, 1, 3), date_to_rd(1980, 12, 31));
    try expectEqual(isoweekdate_to_rd(1981, 1, 4), date_to_rd(1981, 1, 1));
    try expectEqual(isoweekdate_to_rd(1981, 53, 4), date_to_rd(1981, 12, 31));
    try expectEqual(isoweekdate_to_rd(1981, 53, 5), date_to_rd(1982, 1, 1));
    try expectEqual(isoweekdate_to_rd(1981, 53, 6), date_to_rd(1982, 1, 2));
}

const date_to_isoweekdate = date.date_to_isoweekdate;
test date_to_isoweekdate {
    try expectEqual(date_to_isoweekdate(-4, 12, 30), ymd(-3, 1, 1));
    try expectEqual(date_to_isoweekdate(-4, 12, 31), ymd(-3, 1, 2));
    try expectEqual(date_to_isoweekdate(-3, 1, 1), ymd(-3, 1, 3));
    try expectEqual(date_to_isoweekdate(-1, 12, 31), ymd(-1, 52, 5));
    try expectEqual(date_to_isoweekdate(0, 1, 1), ymd(-1, 52, 6));
    try expectEqual(date_to_isoweekdate(0, 1, 2), ymd(-1, 52, 7));
    try expectEqual(date_to_isoweekdate(0, 1, 3), ymd(0, 1, 1));
    try expectEqual(date_to_isoweekdate(1970, 1, 1), ymd(1970, 1, 4));
    try expectEqual(date_to_isoweekdate(1977, 1, 1), ymd(1976, 53, 6));
    try expectEqual(date_to_isoweekdate(1977, 1, 2), ymd(1976, 53, 7));
    try expectEqual(date_to_isoweekdate(1977, 12, 31), ymd(1977, 52, 6));
    try expectEqual(date_to_isoweekdate(1978, 1, 1), ymd(1977, 52, 7));
    try expectEqual(date_to_isoweekdate(1978, 1, 2), ymd(1978, 1, 1));
    try expectEqual(date_to_isoweekdate(1978, 12, 31), ymd(1978, 52, 7));
    try expectEqual(date_to_isoweekdate(1979, 1, 1), ymd(1979, 1, 1));
    try expectEqual(date_to_isoweekdate(1979, 12, 30), ymd(1979, 52, 7));
    try expectEqual(date_to_isoweekdate(1979, 12, 31), ymd(1980, 1, 1));
    try expectEqual(date_to_isoweekdate(1980, 1, 1), ymd(1980, 1, 2));
    try expectEqual(date_to_isoweekdate(1980, 12, 28), ymd(1980, 52, 7));
    try expectEqual(date_to_isoweekdate(1980, 12, 29), ymd(1981, 1, 1));
    try expectEqual(date_to_isoweekdate(1980, 12, 30), ymd(1981, 1, 2));
    try expectEqual(date_to_isoweekdate(1980, 12, 31), ymd(1981, 1, 3));
    try expectEqual(date_to_isoweekdate(1981, 1, 1), ymd(1981, 1, 4));
    try expectEqual(date_to_isoweekdate(1981, 12, 31), ymd(1981, 53, 4));
    try expectEqual(date_to_isoweekdate(1982, 1, 1), ymd(1981, 53, 5));
    try expectEqual(date_to_isoweekdate(1982, 1, 2), ymd(1981, 53, 6));
}

const isoweekdate_to_date = date.isoweekdate_to_date;
test isoweekdate_to_date {
    try expectEqual(isoweekdate_to_date(-3, 1, 1), ymd(-4, 12, 30));
    try expectEqual(isoweekdate_to_date(-3, 1, 2), ymd(-4, 12, 31));
    try expectEqual(isoweekdate_to_date(-3, 1, 3), ymd(-3, 1, 1));
    try expectEqual(isoweekdate_to_date(-1, 52, 5), ymd(-1, 12, 31));
    try expectEqual(isoweekdate_to_date(-1, 52, 6), ymd(0, 1, 1));
    try expectEqual(isoweekdate_to_date(-1, 52, 7), ymd(0, 1, 2));
    try expectEqual(isoweekdate_to_date(0, 1, 1), ymd(0, 1, 3));
    try expectEqual(isoweekdate_to_date(1970, 1, 4), ymd(1970, 1, 1));
    try expectEqual(isoweekdate_to_date(1976, 53, 6), ymd(1977, 1, 1));
    try expectEqual(isoweekdate_to_date(1976, 53, 7), ymd(1977, 1, 2));
    try expectEqual(isoweekdate_to_date(1977, 52, 6), ymd(1977, 12, 31));
    try expectEqual(isoweekdate_to_date(1977, 52, 7), ymd(1978, 1, 1));
    try expectEqual(isoweekdate_to_date(1978, 1, 1), ymd(1978, 1, 2));
    try expectEqual(isoweekdate_to_date(1978, 52, 7), ymd(1978, 12, 31));
    try expectEqual(isoweekdate_to_date(1979, 1, 1), ymd(1979, 1, 1));
    try expectEqual(isoweekdate_to_date(1979, 52, 7), ymd(1979, 12, 30));
    try expectEqual(isoweekdate_to_date(1980, 1, 1), ymd(1979, 12, 31));
    try expectEqual(isoweekdate_to_date(1980, 1, 2), ymd(1980, 1, 1));
    try expectEqual(isoweekdate_to_date(1980, 52, 7), ymd(1980, 12, 28));
    try expectEqual(isoweekdate_to_date(1981, 1, 1), ymd(1980, 12, 29));
    try expectEqual(isoweekdate_to_date(1981, 1, 2), ymd(1980, 12, 30));
    try expectEqual(isoweekdate_to_date(1981, 1, 3), ymd(1980, 12, 31));
    try expectEqual(isoweekdate_to_date(1981, 1, 4), ymd(1981, 1, 1));
    try expectEqual(isoweekdate_to_date(1981, 53, 4), ymd(1981, 12, 31));
    try expectEqual(isoweekdate_to_date(1981, 53, 5), ymd(1982, 1, 1));
    try expectEqual(isoweekdate_to_date(1981, 53, 6), ymd(1982, 1, 2));
}

const isoweeks_in_year = date.isoweeks_in_year;
test isoweeks_in_year {
    try expectEqual(isoweeks_in_year(-3), 52); // wednesday
    try expectEqual(isoweeks_in_year(-2), 53); // thursday
    try expectEqual(isoweeks_in_year(-1), 52); // friday
    try expectEqual(isoweeks_in_year(0), 52); // saturday, leap year
    try expectEqual(isoweeks_in_year(1), 52); // monday
    try expectEqual(isoweeks_in_year(2), 52); // tuesday
    try expectEqual(isoweeks_in_year(3), 52); // wednesday
    try expectEqual(isoweeks_in_year(4), 53); // thursday, leap year
    try expectEqual(isoweeks_in_year(5), 52); // saturday
    try expectEqual(isoweeks_in_year(1969), 52); // wednesday
    try expectEqual(isoweeks_in_year(1970), 53); // thursday
    try expectEqual(isoweeks_in_year(1971), 52); // friday
    try expectEqual(isoweeks_in_year(2004), 53); // leap year, thursday
    try expectEqual(isoweeks_in_year(2015), 53); // thursday
    try expectEqual(isoweeks_in_year(2020), 53); // leap year, wednesday
}

const instant_to_secs = date.instant_to_secs;
test instant_to_secs {
    try expectEqual(instant_to_secs(UNIX_EPOCH), .{ 0, 0 });
    try expectEqual(
        instant_to_secs(date.Instant.from_secs(date.RD_SECONDS_MAX)),
        .{ date.RD_SECONDS_MAX, 0 },
    );
    try expectEqual(
        instant_to_secs(UNIX_EPOCH.sub(
            date.Instant.from_secs(-date.RD_SECONDS_MIN),
        )),
        .{ date.RD_SECONDS_MIN, 0 },
    );
    try expectEqual(
        instant_to_secs(date.Instant.from_secs(date.RD_SECONDS_MAX + 1)),
        null,
    );
    try expectEqual(
        instant_to_secs(UNIX_EPOCH.sub(
            date.Instant.from_secs(-date.RD_SECONDS_MIN + 1),
        )),
        null,
    );
}

const secs_to_systemtime = date.secs_to_systemtime;
test secs_to_systemtime {
    try expectEqual(secs_to_systemtime(0, 0), UNIX_EPOCH);
    try expectEqual(
        secs_to_systemtime(date.RD_SECONDS_MAX, 0),
        date.Instant.from_secs(date.RD_SECONDS_MAX),
    );
    try expectEqual(
        secs_to_systemtime(date.RD_SECONDS_MIN, 0),
        UNIX_EPOCH.sub(date.Instant.from_secs(-date.RD_SECONDS_MIN)),
    );
}

const systemtime_to_datetime = date.systemtime_to_datetime;
test systemtime_to_datetime {
    try expectEqual(systemtime_to_datetime(UNIX_EPOCH), date.DateTimeNs.init(1970, 1, 1, 0, 0, 0, 0));
    try expectEqual(
        systemtime_to_datetime(date.Instant.from_secs(date.RD_SECONDS_MAX)),
        date.DateTimeNs.init(date.YEAR_MAX, 12, 31, 23, 59, 59, 0),
    );
    try expectEqual(
        systemtime_to_datetime(UNIX_EPOCH.sub(
            date.Instant.from_secs(-date.RD_SECONDS_MIN),
        )),
        date.DateTimeNs.init(date.YEAR_MIN, 1, 1, 0, 0, 0, 0),
    );
    try expectEqual(
        systemtime_to_datetime(date.Instant.from_secs(date.RD_SECONDS_MAX + 1)),
        null,
    );
    try expectEqual(
        systemtime_to_datetime(UNIX_EPOCH.sub(
            date.Instant.from_secs(-date.RD_SECONDS_MIN + 1),
        )),
        null,
    );
}

const datetime_to_systemtime = date.datetime_to_systemtime;
test datetime_to_systemtime {
    try expectEqual(datetime_to_systemtime(1970, 1, 1, 0, 0, 0, 0), UNIX_EPOCH);
    try expectEqual(
        datetime_to_systemtime(date.YEAR_MAX, 12, 31, 23, 59, 59, 0),
        date.Instant.from_secs(date.RD_SECONDS_MAX),
    );
    try expectEqual(
        datetime_to_systemtime(date.YEAR_MIN, 1, 1, 0, 0, 0, 0),
        UNIX_EPOCH.sub(date.Instant.from_secs(-date.RD_SECONDS_MIN)),
    );
}

test {
    _ = @import("tests2.zig");
}
