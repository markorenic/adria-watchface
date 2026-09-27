using Toybox.Application;
using Toybox.Complications;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Position;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;
using Toybox.Weather;

class AdriaApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new AdriaFace()]; }
}

class AdriaFace extends WatchUi.WatchFace {
    var _zagreb;
    var _weekdays as Lang.Array<Lang.String> = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
    var _months as Lang.Array<Lang.String> = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];

    function initialize() {
        WatchFace.initialize();
        // A fixed location selects Croatia's timezone without activating GPS.
        _zagreb = new Position.Location({
            :latitude => 45.8150, :longitude => 15.9819, :format => :degrees
        });
    }

    function clockText(hour, minute) {
        return hour.format("%02d") + ":" + minute.format("%02d");
    }

    function centered(dc, y, font, text) {
        dc.drawText(dc.getWidth() / 2, y, font, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function metric(dc, x, labelY, valueY, label, value) {
        dc.drawText(x, labelY, Graphics.FONT_XTINY, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x, valueY, Graphics.FONT_SMALL, value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function batteryText(stats) {
        if (stats has :batteryInDays && stats.batteryInDays != null && stats.batteryInDays > 0) {
            if (stats.batteryInDays < 1) {
                var hours = (stats.batteryInDays * 24).toNumber();
                return hours < 1 ? "<1H" : hours.toString() + "H";
            }
            return stats.batteryInDays.format("%.1f") + "D";
        }
        // Some firmware versions do not supply a usable runtime estimate.
        return stats.battery.format("%.0f") + "%";
    }

    function temperature(value) {
        if (value == null) { return "--"; }
        if (System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE) {
            return ((value * 9.0 / 5.0) + 32).toNumber().toString();
        }
        return value.toNumber().toString();
    }

    function sunsetFromWatch() {
        var iterator = Complications.getComplications();
        var complication = iterator.next();
        while (complication != null) {
            if (complication.getType() == Complications.COMPLICATION_TYPE_SUNSET &&
                complication.value != null) {
                var seconds = complication.value as Lang.Number;
                var minutes = (seconds / 60).toNumber();
                return clockText((minutes / 60).toNumber(), minutes % 60);
            }
            complication = iterator.next();
        }
        return null;
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var width = dc.getWidth();
        var height = dc.getHeight();
        var now = Time.now();
        var local = Gregorian.info(now, Time.FORMAT_SHORT);
        var weekday = local.day_of_week as Lang.Number;
        var month = local.month as Lang.Number;
        var date = _weekdays[weekday - 1] + " " + local.day.toString() + " " + _months[month - 1];
        centered(dc, height * 0.105, Graphics.FONT_SMALL, date);

        var time = clockText(local.hour, local.min);
        var font = Graphics.FONT_NUMBER_HOT;
        if (dc.getTextWidthInPixels(time, font) > width * 0.86) {
            font = Graphics.FONT_NUMBER_MEDIUM;
        }
        centered(dc, height * 0.35, font, time);
        dc.drawLine(width * 0.18, height * 0.515, width * 0.82, height * 0.515);

        var croatia = "--:--";
        var croatiaMoment = Gregorian.localMoment(_zagreb, now);
        if (croatiaMoment != null) {
            var info = Gregorian.info(croatiaMoment, Time.FORMAT_SHORT);
            croatia = clockText(info.hour, info.min);
        }
        var conditions = Weather.getCurrentConditions();
        var sunsetText = sunsetFromWatch();
        var highsLows = "--/--";
        var location = null;
        if (sunsetText == null) {
            var positionInfo = Position.getInfo();
            if (positionInfo != null && positionInfo.position != null) {
                location = positionInfo.position;
            } else if (conditions != null && conditions.observationLocationPosition != null) {
                location = conditions.observationLocationPosition;
            }
            if (location != null) {
                var sunset = Weather.getSunset(location, now);
                if (sunset != null) {
                    var sunInfo = Gregorian.info(sunset, Time.FORMAT_SHORT);
                    sunsetText = clockText(sunInfo.hour, sunInfo.min);
                }
            }
        }
        if (sunsetText == null) { sunsetText = "--:--"; }
        if (conditions != null) {
            var unit = System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE ? "F" : "C";
            highsLows = temperature(conditions.highTemperature) + "/" + temperature(conditions.lowTemperature) + unit;
        }
        metric(dc, width * 0.32, height * 0.57, height * 0.66, "CRO", croatia);
        metric(dc, width * 0.68, height * 0.57, height * 0.66, "SUNSET", sunsetText);
        metric(dc, width * 0.32, height * 0.77, height * 0.86, "HI/LO", highsLows);
        metric(dc, width * 0.68, height * 0.77, height * 0.86, "BAT", batteryText(System.getSystemStats()));
        dc.drawLine(width * 0.18, height * 0.72, width * 0.82, height * 0.72);
        dc.drawLine(width * 0.5, height * 0.55, width * 0.5, height * 0.89);
    }
}
