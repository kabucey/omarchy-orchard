import QtQuick
import QtTest
import "../Logic.js" as Logic

// Moving a timed event by holding it and dragging it along the rail: where
// the block goes as the pointer moves, and the draft that move saves.
TestCase {
  name: "dragmove"

  readonly property var wholeDay: Logic.dayWindow(0, 24)

  function test_rail_minute_is_not_snapped() {
    // 40px an hour.
    compare(Logic.railMinute(0, 40, wholeDay), 0)
    compare(Logic.railMinute(366, 40, wholeDay), 549)
    compare(Logic.railMinute(40, 40, Logic.dayWindow(8, 18)), 9 * 60)
  }

  function test_moves_by_whole_quarters() {
    // Picked up at 9:20 on a 9:00–10:00 block.
    compare(Logic.movedStart(540, 560, 560, 60, wholeDay), 540)
    compare(Logic.movedStart(540, 560, 566, 60, wholeDay), 540)
    compare(Logic.movedStart(540, 560, 568, 60, wholeDay), 555)
    compare(Logic.movedStart(540, 560, 680, 60, wholeDay), 660)
    compare(Logic.movedStart(540, 560, 500, 60, wholeDay), 480)
  }

  function test_keeps_an_off_quarter_start_off_the_quarter() {
    compare(Logic.movedStart(550, 560, 590, 30, wholeDay), 580)
  }

  function test_stays_on_the_rail_end_and_all() {
    compare(Logic.movedStart(540, 560, -400, 60, wholeDay), 0)
    compare(Logic.movedStart(540, 560, 5000, 60, wholeDay), 23 * 60)
    var work = Logic.dayWindow(8, 18)
    compare(Logic.movedStart(540, 560, 0, 90, work), 8 * 60)
    compare(Logic.movedStart(540, 560, 2000, 90, work), 18 * 60 - 90)
  }

  function draftAt(start, end) {
    return Logic.editDraft({ uid: "u", title: "Standup", calendarUrl: "cal", allDay: false,
                             start: start, end: end }, "America/New_York")
  }

  function test_shifted_draft_keeps_its_length() {
    var moved = Logic.shiftedDraft(draftAt("2026-10-06T09:00:00", "2026-10-06T10:30:00"), 75)
    compare(moved.startDate, "2026-10-06")
    compare(moved.startTime, "10:15")
    compare(moved.endDate, "2026-10-06")
    compare(moved.endTime, "11:45")
  }

  function test_shifted_draft_crosses_days() {
    var draft = draftAt("2026-10-06T23:00:00", "2026-10-07T00:30:00")
    var later = Logic.shiftedDraft(draft, 2 * 24 * 60 + 30)
    compare(later.startDate, "2026-10-08")
    compare(later.startTime, "23:30")
    compare(later.endDate, "2026-10-09")
    compare(later.endTime, "01:00")

    var earlier = Logic.shiftedDraft(draftAt("2026-10-06T00:15:00", "2026-10-06T01:00:00"), -30)
    compare(earlier.startDate, "2026-10-05")
    compare(earlier.startTime, "23:45")
    compare(earlier.endDate, "2026-10-06")
    compare(earlier.endTime, "00:30")
  }

  function test_shifted_draft_is_a_change_to_the_times_only() {
    var draft = draftAt("2026-10-06T09:00:00", "2026-10-06T10:00:00")
    var changes = Logic.draftChanges(Logic.shiftedDraft(draft, 60),
      { uid: "u", title: "Standup", calendarUrl: "cal", allDay: false,
        start: "2026-10-06T09:00:00", end: "2026-10-06T10:00:00" })
    verify(changes.length > 0)
    verify(changes.indexOf("title") < 0)
    compare(Logic.shiftedDraft(draft, 0), draft)
  }

  function test_moving_one_of_a_series_can_still_be_just_that_one() {
    var base = { uid: "u", title: "Sync", calendarUrl: "cal", allDay: false, recurring: true,
                 rid: "", start: "2026-10-07T10:00:00-04:00", end: "2026-10-07T11:00:00-04:00",
                 startWall: "2026-10-07T10:00:00", endWall: "2026-10-07T11:00:00",
                 startZone: "America/New_York", endZone: "America/New_York",
                 rrule: "FREQ=WEEKLY;INTERVAL=2;WKST=SU;BYDAY=WE" }
    var draft = Logic.editDraft(base, "America/New_York")
    // An hour later, and to the next day: neither touches the rule.
    var minutesList = [60, 24 * 60]
    for (var i = 0; i < minutesList.length; i++) {
      var changes = Logic.draftChanges(Logic.shiftedDraft(draft, minutesList[i]), base)
      compare(changes.indexOf("rrule"), -1)
      compare(Logic.scopeChoices(base, changes)[0].value, "this")
    }
    // A calendar that cannot create, Google's, is asked this one or all.
    var google = Logic.scopeChoicesForCalendar(base, ["start", "end"],
                                               { capabilities: { create: false } })
    compare(google.map(function (c) { return c.value }).join(","), "this,all")
  }
}
