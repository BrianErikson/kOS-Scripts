SET c_logs to LIST("Initializing...").
SET c_compass to 0.
SET c_pitch to 90.
SET c_seperator to "--------------------------".
SET c_headerOffset to 7.

FUNCTION renderScreen {
	CLEARSCREEN.
	PRINT c_seperator.
	PRINT "Ship Apoapsis: " + SHIP:Apoapsis.
	PRINT "Ship Periapsis: " + SHIP:Periapsis.
	PRINT "Autopilot Compass: " + c_compass.
	PRINT "Autopilot Pitch: " + c_pitch.
	PRINT c_seperator.
}

FUNCTION addLog {
	PARAMETER l. // string, color
	HUDTEXT(l, 10, 2, 40, white, false).
}

FUNCTION updateHeading {
	PARAMETER c, p.
	SET c_compass to c.
	SET c_pitch to p.
}