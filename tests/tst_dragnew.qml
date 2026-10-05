import QtQuick
import QtTest
import "../Logic.js" as Logic

// Drawing a new event by dragging down the day or week rail: the pointer read
// in quarter hours, the span it draws, and the event that span becomes.
TestCase {
  name: "dragnew"

  readonly property var wholeDay: Logic.dayWindow(0, 24)

  function test_minute_snaps_to_the_nearest_quarter() {
    // 40px an hour: 10px is a quarter.
    compare(Logic.dragMinute(0, 40, wholeDay), 0)
    compare(Logic.dragMinute(360, 40, wholeDay), 9 * 60)
    compare(Logic.dragMinute(364, 40, wholeDay), 9 * 60)
    compare(Logic.dragMinute(366, 40, wholeDay), 9 * 60 + 15)
  }

  function test_minute_stays_inside_the_rail() {
    var work = Logic.dayWindow(8, 18)
    compare(Logic.dragMinute(-50, 40, work), 8 * 60)
    compare(Logic.dragMinute(0, 40, work), 8 * 60)
    compare(Logic.dragMinute(40, 40, work), 9 * 60)
    compare(Logic.dragMinute(10000, 40, work), 18 * 60)
  }

  function test_span_runs_either_way_up() {
    var down = Logic.dragSpan(540, 630, wholeDay)
    compare(down.start, 540)
    compare(down.end, 630)
    var up = Logic.dragSpan(630, 540, wholeDay)
    compare(up.start, 540)
    compare(up.end, 630)
  }

  function test_span_is_at_least_a_quarter_hour() {
    var still = Logic.dragSpan(540, 540, wholeDay)
    compare(still.start, 540)
    compare(still.end, 555)
    // At the foot of the rail it grows upwards instead.
    var foot = Logic.dragSpan(24 * 60, 24 * 60, wholeDay)
    compare(foot.start, 24 * 60 - 15)
    compare(foot.end, 24 * 60)
  }

  function test_new_event_over_a_span() {
    var event = Logic.newEventAt("2026-10-01", 9 * 60 + 15, 10 * 60 + 45, "cal")
    compare(event.start, "2026-10-01T09:15:00")
    compare(event.end, "2026-10-01T10:45:00")
    compare(event.calendarUrl, "cal")
    compare(event.uid, "")
    compare(event.allDay, false)
  }

  function test_new_event_ending_at_midnight_ends_next_day() {
    var event = Logic.newEventAt("2026-10-01", 23 * 60, 24 * 60, "cal")
    compare(event.end, "2026-10-02T00:00:00")
    var draft = Logic.editDraft(event, "America/New_York")
    compare(draft.endDate, "2026-10-02")
    compare(draft.endTime, "00:00")
  }

  function test_draft_span_follows_the_draft() {
    var draft = Logic.editDraft(Logic.newEventAt("2026-10-01", 540, 600, "cal"), "")
    var span = Logic.draftSpanOn(draft, "2026-10-01")
    compare(span.start, 540)
    compare(span.end, 600)
    compare(Logic.draftSpanOn(draft, "2026-10-02"), null)

    // Moving the start keeps the length, as the form does.
    var moved = Logic.withField(draft, "startTime", "11:00")
    span = Logic.draftSpanOn(moved, "2026-10-01")
    compare(span.start, 660)
    compare(span.end, 720)

    var late = Logic.editDraft(Logic.newEventAt("2026-10-01", 23 * 60, 24 * 60, "cal"), "")
    compare(Logic.draftSpanOn(late, "2026-10-01").end, 24 * 60)

    compare(Logic.draftSpanOn(Logic.withField(draft, "allDay", true), "2026-10-01"), null)
  }

  function test_span_label() {
    compare(Logic.spanLabel(540, 630, "24h"), "09:00 – 10:30")
    compare(Logic.spanLabel(23 * 60, 24 * 60, "24h"), "23:00 – 00:00")
  }

  function test_click_span_is_an_hour_from_the_quarter_clicked() {
    // 40px an hour: 9:20 is 373px, in the 9:15 quarter.
    var span = Logic.clickSpan(373, 40, wholeDay)
    compare(span.start, 9 * 60 + 15)
    compare(span.end, 10 * 60 + 15)
  }

  function test_click_span_fits_before_the_rail_ends() {
    var late = Logic.clickSpan(23.5 * 40, 40, wholeDay)
    compare(late.start, 23 * 60)
    compare(late.end, 24 * 60)
    var work = Logic.dayWindow(8, 18)
    var top = Logic.clickSpan(-5, 40, work)
    compare(top.start, 8 * 60)
    compare(top.end, 9 * 60)
  }

  function test_drag_column_stays_inside_the_week() {
    compare(Logic.dragColumn(0, 100, 7), 0)
    compare(Logic.dragColumn(250, 100, 7), 2)
    compare(Logic.dragColumn(-30, 100, 7), 0)
    compare(Logic.dragColumn(5000, 100, 7), 6)
  }

  function test_day_span_runs_either_way_along() {
    var right = Logic.daySpan("2026-10-05", "2026-10-07")
    compare(right.from, "2026-10-05")
    compare(right.to, "2026-10-07")
    var left = Logic.daySpan("2026-10-07", "2026-10-05")
    compare(left.from, "2026-10-05")
    compare(left.to, "2026-10-07")
  }

  function test_new_all_day_event_over_days() {
    var one = Logic.newAllDayEventOn("2026-10-05", "2026-10-05", "cal")
    compare(one.allDay, true)
    compare(one.start, "2026-10-05")
    compare(one.end, "2026-10-06")
    compare(one.calendarUrl, "cal")
    compare(one.uid, "")

    // Drawn right to left, it still starts on the earlier day.
    var three = Logic.newAllDayEventOn("2026-10-07", "2026-10-05", "cal")
    compare(three.start, "2026-10-05")
    compare(three.end, "2026-10-08")
    var draft = Logic.editDraft(three, "America/New_York")
    compare(draft.allDay, true)
    compare(draft.startDate, "2026-10-05")
    compare(draft.endDate, "2026-10-07")
  }

  function test_draft_bar_follows_the_draft() {
    var week = Logic.weekDays("2026-10-05", 0)
    var draft = Logic.editDraft(Logic.newAllDayEventOn("2026-10-06", "2026-10-07", "cal"), "")
    var bar = Logic.draftBarIn(draft, week)
    compare(bar.startCol, week.indexOf("2026-10-06"))
    compare(bar.span, 2)
    compare(bar.continuesBefore, false)
    compare(bar.continuesAfter, false)

    // Past the week's end it is cut there, and says it goes on.
    var long = Logic.withField(draft, "endDate", Logic.addDays(week[6], 3))
    bar = Logic.draftBarIn(long, week)
    compare(bar.startCol + bar.span, 7)
    compare(bar.continuesAfter, true)

    compare(Logic.draftBarIn(draft, Logic.weekDays("2026-10-20", 0)), null)
    compare(Logic.draftBarIn(Logic.withField(draft, "allDay", false), week), null)
  }
}
