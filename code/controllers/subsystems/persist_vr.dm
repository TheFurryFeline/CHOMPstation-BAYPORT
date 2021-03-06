////////////////////////////////
//// Paid Leave Subsystem
//// For tracking how much department PTO time players have accured
////////////////////////////////

SUBSYSTEM_DEF(persist)
	name = "Persist"
	priority = 20
	wait = 15 MINUTES
	flags = SS_BACKGROUND|SS_NO_INIT|SS_KEEP_TIMING
	runlevels = RUNLEVEL_GAME|RUNLEVEL_POSTGAME
	var/list/currentrun = list()

/datum/controller/subsystem/persist/fire(var/resumed = FALSE)
	update_department_hours(resumed)
/*
// Do PTO Accruals
/datum/controller/subsystem/persist/proc/update_department_hours(var/resumed = FALSE)
	if(!config.time_off)
		return

	establish_db_connection()
	if(!dbcon.IsConnected())
		src.currentrun.Cut()
		return
	if(!resumed)
		src.currentrun = GLOB.human_mob_list.Copy()

	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	while (currentrun.len)
		var/mob/M = currentrun[currentrun.len]
		currentrun.len--
		if (QDELETED(M) || !istype(M) || !M.mind || !M.client)
			continue

		// Try and detect job and department of mob
		var/datum/job/J = detect_job(M)
		if(!istype(J) || !J.department || !J.timeoff_factor)
			if (MC_TICK_CHECK)
				return
			continue

		// Update client whatever
		var/client/C = M.client
		var/wait_in_hours = (wait / (1 HOUR)) * J.timeoff_factor
		LAZYINITLIST(C.department_hours)
		var/dept_hours = C.department_hours
		if(isnum(C.department_hours[J.department]))
			dept_hours[J.department] += wait_in_hours
		else
			dept_hours[J.department] = wait_in_hours

		//Cap it
		dept_hours[J.department] = min(config.pto_cap, dept_hours[J.department])


		// Okay we figured it out, lets update database!
		var/sql_ckey = sql_sanitize_text(C.ckey)
		var/sql_dpt = sql_sanitize_text(J.department)
		var/sql_bal = text2num("[C.department_hours[J.department]]")
		var/DBQuery/query = dbcon.NewQuery("INSERT INTO vr_player_hours (ckey, department, hours) VALUES ('[sql_ckey]', '[sql_dpt]', [sql_bal]) ON DUPLICATE KEY UPDATE hours = VALUES(hours)")
		query.Execute()

		if (MC_TICK_CHECK)
			return*/

// This proc tries to find the job datum of an arbitrary mob.
/datum/controller/subsystem/persist/proc/detect_job(var/mob/M)
	// Records are usually the most reliable way to get what job someone is.
	var/datum/data/record/R = GLOB.find_general_record("name", M.real_name)
	if(R) // We found someone with a record.
		var/recorded_rank = R.fields["real_rank"]
		if(recorded_rank)
			. = job_master.GetJob(recorded_rank)
			if(.) return

	// They have a custom title, aren't crew, or someone deleted their record, so we need a fallback method.
	// Let's check the mind.
	if(M.mind && M.mind.assigned_role)
		. = job_master.GetJob(M.mind.assigned_role)
