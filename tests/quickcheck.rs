//!
//! adapted from https://github.com/nakedible/datealgo-rs/blob/master/tests/quickcheck.rs
//!

use quickcheck::{quickcheck, TestResult};

#[repr(C)]
#[derive(PartialEq, Debug, Copy, Clone)]
pub struct Ymd {
    y: i32,
    m: u8,
    d: u8,
}

impl From<(i32, u8, u8)> for Ymd {
    fn from((y, m, d): (i32, u8, u8)) -> Self {
        Self { y, m, d }
    }
}

#[repr(C)]
#[derive(PartialEq)]
pub struct Instant(std::time::SystemTime);

// impl From<std::time::SystemTime> for Instant {
//     fn from(st: std::time::SystemTime) -> Self {
//         Self { 0: st.into() }
//     }
// }

#[repr(C)]
pub struct Opt<T> {
    value: T,
    has_value: bool,
}

#[repr(C)]
#[derive(PartialEq)]
pub struct DateTimeNs {
    y: i32,
    m: u8,
    d: u8,
    h: u8,
    min: u8,
    sec: u8,
    nsec: u32,
}

impl From<(i32, u8, u8, u8, u8, u8, u32)> for DateTimeNs {
    fn from((y, m, d, h, min, sec, nsec): (i32, u8, u8, u8, u8, u8, u32)) -> Self {
        Self {
            y,
            m,
            d,
            h,
            min,
            sec,
            nsec,
        }
    }
}

#[link(name = "date-zig")]
extern "C" {
    fn rd_to_date(rd: i32) -> Ymd;
    fn rd_to_weekday(rd: i32) -> u8;
    fn date_to_rd(d: i32, m: u8, d: u8) -> i32;
    fn date_to_weekday(d: i32, m: u8, d: u8) -> u8;
    fn is_leap_year(y: i32) -> bool;
    fn days_in_month(y: i32, m: u8) -> u8;
    fn next_date(y: i32, m: u8, d: u8) -> Ymd;
    fn prev_date(y: i32, m: u8, d: u8) -> Ymd;
    fn rd_to_isoweekdate(rd: i32) -> Ymd;
    fn isoweekdate_to_rd(y: i32, m: u8, d: u8) -> i32;
    fn isoweeks_in_year(y: i32) -> u8;
    // fn systemtime_to_datetime2(i: Instant) -> Opt<DateTimeNs>;
    // TODO fix warning that Opt<Instant> is not FFI-safe
    fn datetime_to_systemtime2(
        y: i32,
        m: u8,
        d: u8,
        hh: u8,
        mm: u8,
        ss: u8,
        nsec: u32,
    ) -> Opt<Instant>;
    static YEAR_MAX: i32;
    static YEAR_MIN: i32;
    static MONTH_MAX: u8;
    static MONTH_MIN: u8;
}

quickcheck! {
    fn quickcheck_rd_to_date(d: time::Date) -> TestResult {
        let rd = d.to_julian_day() - 2440588;
        let a = unsafe{ rd_to_date(rd) };
        let b: Ymd = (d.year() as i32, d.month() as u8, d.day() as u8).into();
        TestResult::from_bool(a == b)
    }

    fn quickcheck_date_to_rd(d: time::Date) -> TestResult {
        let rd = unsafe{ date_to_rd(d.year() as i32, d.month() as u8, d.day() as u8) };
        TestResult::from_bool(rd == (d.to_julian_day() - 2440588))
    }

    fn quickcheck_rd_to_weekday(d: time::Date) -> TestResult {
        let rd = d.to_julian_day() - 2440588;
        let wd_a = unsafe{ rd_to_weekday(rd) };
        let wd_b = d.weekday().number_from_monday();
        TestResult::from_bool(wd_a as u8 == wd_b)
    }

    fn quickcheck_date_to_weekday(d: time::Date) -> TestResult {
        let rd = d.to_julian_day() - 2440588;
        let ymd = unsafe { rd_to_date(rd) };
        let wd_a = unsafe { date_to_weekday(ymd.y, ymd.m, ymd.d) };
        let wd_b = d.weekday().number_from_monday();
        TestResult::from_bool(wd_a as u8 == wd_b)
    }

    fn quickcheck_is_leap_year(y: i32) -> TestResult {
        if unsafe { y < YEAR_MIN || y > YEAR_MAX } {
            return TestResult::discard();
        }
        let leap_a = unsafe { is_leap_year(y) };
        let leap_b = time::util::is_leap_year(y);
        TestResult::from_bool(leap_a == leap_b)
    }

    fn quickcheck_days_in_month(y: i32, m: u8) -> TestResult {
        if unsafe {y < YEAR_MIN || y > YEAR_MAX} {
            return TestResult::discard();
        }
        if unsafe {m < MONTH_MIN || m > MONTH_MAX} {
            return TestResult::discard();
        }
        let days_a = unsafe {days_in_month(y, m)};
        let days_b = time::util::days_in_year_month(y, m.try_into().unwrap());
        TestResult::from_bool(days_a == days_b)
    }

    fn quickcheck_next_date(d: time::Date) -> TestResult {
        if d == time::Date::MAX {
            return TestResult::discard();
        }
        let next_date = unsafe {next_date(d.year() as i32, d.month() as u8, d.day() as u8)};
        let nd = d + time::Duration::days(1);
        let expected_date: Ymd = (nd.year() as i32, nd.month() as u8, nd.day() as u8).into();
        TestResult::from_bool(next_date == expected_date)
    }

    fn quickcheck_prev_date(d: time::Date) -> TestResult {
        if d == time::Date::MIN {
            return TestResult::discard();
        }
        let prev_date = unsafe{prev_date(d.year() as i32, d.month() as u8, d.day() as u8)};
        let pd = d - time::Duration::days(1);
        let expected_date: Ymd = (pd.year() as i32, pd.month() as u8, pd.day() as u8).into();
        TestResult::from_bool(prev_date == expected_date)
    }

    fn quickcheck_rd_to_isoweekdate(d: time::Date) -> TestResult {
        let rd = d.to_julian_day() - 2440588;
        let a = unsafe{rd_to_isoweekdate(rd)};
        let (y, w, wd) = d.to_iso_week_date();
        TestResult::from_bool(a == (y, w as u8, wd.number_from_monday()).into())
    }

    fn quickcheck_isoweekdate_to_rd(d: time::Date) -> TestResult {
        let (y, w, wd) = d.to_iso_week_date();
        let rd = unsafe{isoweekdate_to_rd(y, w as u8, wd.number_from_monday())};
        TestResult::from_bool(rd == d.to_julian_day() - 2440588)
    }

    fn quickcheck_isoweeks_in_year(y: i32) -> TestResult {
        if unsafe{y < YEAR_MIN || y > YEAR_MAX} {
            return TestResult::discard();
        }
        let weeks_a = unsafe{isoweeks_in_year(y)};
        let weeks_b = time::util::weeks_in_year(y);
        TestResult::from_bool(weeks_a == weeks_b)
    }

    // TODO - figure out why this is panicing
    // fn quickcheck_systemtime_to_datetime(s: time::PrimitiveDateTime) -> TestResult {
    //     let s = s.assume_utc();
    //     let st: std::time::SystemTime = s.into();

    //     println!("{s:?}");

    //     let a = unsafe{systemtime_to_datetime2()}.value;
    //     let b: DateTimeNs = (
    //         s.year() as i32,
    //         s.month() as u8,
    //         s.day() as u8,
    //         s.hour() as u8,
    //         s.minute() as u8,
    //         s.second() as u8,
    //         s.nanosecond(),
    //     ).into();
    //     TestResult::from_bool(a == b)
    //     TestResult::from_bool(false)
    // }

    fn quickcheck_datetime_to_systemtime(s: time::PrimitiveDateTime) -> TestResult {
        let s = s.assume_utc();
        let a = unsafe{datetime_to_systemtime2(s.year() as i32,
            s.month() as u8,
            s.day() as u8,
            s.hour() as u8,
            s.minute() as u8,
            s.second() as u8,
            s.nanosecond(),)}.value;
        let b: std::time::SystemTime = s.into();
        TestResult::from_bool(a == Instant(b))
    }
}
