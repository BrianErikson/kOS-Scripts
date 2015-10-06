PARAMETER o_apoapsis o_compass

run console. // addLog(string), renderScreen, updateHeading(compass, pitch)
SET s_state to 0. // -1 = terminate 0 = ground, 1 = < 3km, 
					// 2 = < 15km, 3 = apoapsis > 80km, 4 = periapsis < 70km, 5 = end of timewarp

SET t_apoapsis to o_apoapsis.
SET t_periapsis to o_apoapsis - 1000. // adjusted by 1km for drift

FUNCTION changeHeading {
	PARAMETER c, p.
	LOCK STEERING TO HEADING(c, p).
	updateHeading(c, p).
}

FUNCTION setState {
	PARAMETER st.
	LOCAL prev is s_state.
	SET s_state to st.
	if (s_state = 1 and prev = 0) { // LAUNCH!
		addLog("Launch!").
		LOCK THROTTLE TO 1.0. // 1.0 max, 0.0 idle
		LOCK STEERING TO UP.
		STAGE.
	}
	else if (s_state = 2 and prev = 1) { // hit 3km
		addLog("3km hit. Adjusting heading.").
		changeHeading(o_compass, 70).
	}
	else if (s_state = 3 and prev = 2) { // hit 15km
		addLog("15km hit. Adjusting heading.").
		changeHeading(o_compass, 45).
	}
	else if (s_state = 4 and prev = 3) { // apoapsis reached desired km
		addLog("Target apoapsis reached. Waiting for apoapsis").
		changeHeading(o_compass, 0).
		LOCK THROTTLE TO 0.0.
		addLog("Stabilizing throttle...").
		renderScreen().
		WAIT 2.
		addLog("Throttle stabilized. Timewarping to apoapsis.").
		SET WARPMODE TO "PHYSICS".
		SET WARP TO 3.
	}
	else if (s_state = 5 and prev = 4) { // end of timewarp
		SET WARP TO 0.
		addLog("Apoapsis reached. Circularizing orbit").
		WAIT 1.
		LOCK THROTTLE TO 1.0.
	}
	else if (s_state = -1 and prev = 5) { // finished circularizing
		addLog("Orbit circularized. Releasing controls to player.").
		LOCK THROTTLE TO 0.0.
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.0.
		WAIT 1.
	}
}

FUNCTION getTWR
{
    set mth to SHIP:MAXTHRUST. // (depends on fixed kOS issue 940)
    set r to SHIP:ALTITUDE+SHIP:BODY:RADIUS.
    set w to SHIP:MASS * SHIP:BODY:MU / r / r.
    return mth/w.
}

FUNCTION calcThrottle {
	if (Ship:apoapsis < 70000) {
		local t is (2.0 / getTWR()).
		if (t < 0) {
			SET t to 0.
		}
		if (t > 1) {
			SET t to 1.
		}
		LOCK THROTTLE TO t.
	}
}

FUNCTION init {
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.0.
	// Normal FOR-LOOP
	FROM {local i is 3.} UNTIL i = 0 STEP {SET i to i - 1.} DO {
	  addLog("...T-" + i).
	  renderScreen().
	  WAIT 1. // Waits 1 second
	}
}

// ========================
//         RUNTIME
// ========================
WHEN STAGE:NUMBER >= 1 THEN {
  SET staged to 0.
  LIST ENGINES IN engines. FOR eng IN engines {
	IF eng:FLAMEOUT {
	  SET staged to 1.
	}
  }
  IF staged > 0 {
	addLog("Flameout detected. Staging.").
	STAGE.
  }

  IF STAGE:NUMBER > 1 {
	PRESERVE.
  }
}

UNTIL (s_state = -1) {
	renderScreen().

	if (s_state <= 3 and s_state > 0) {
		calcThrottle().
	}

	if (s_state = 0) {
		init().
		setState(1). // LAUNCH!
	}
	else if (s_state = 1) {
		if (Ship:apoapsis > 3000) {
			setState(2).
		}
	}
	else if (s_state = 2) {
		if (Ship:apoapsis > 15000) {
			setState(3).
		}
	}
	else if (s_state = 3) {
		if (Ship:apoapsis >= t_apoapsis) {
			setState(4).
		}
	}
	else if (s_state = 4) {
		if (ETA:apoapsis <= 45) {
			setState(5).
		}
	}
	else if (s_state = 5) {
		if (Ship:periapsis >= t_periapsis) {
			setState(-1). // end program
		}
	}
}
renderScreen().
