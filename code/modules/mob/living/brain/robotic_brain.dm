/obj/item/mmi/robotic_brain
	name = "lesser positronic brain"
	desc = "A cheaper version of the full positronic brain used in IPCs and cyborgs. Its simplified design makes it easy to produce with equipment as small as a protolathe, while larger positronic brains require dedicated nanofoundries."
	icon = 'icons/obj/assemblies.dmi'
	icon_state = "posibrain"
	var/blank_icon = "posibrain"
	var/searching_icon = "posibrain-searching"
	var/occupied_icon = "posibrain-occupied"
	origin_tech = "biotech=3;programming=3;plasmatech=2"
	materials = list(MAT_METAL = 1700, MAT_GLASS = 1350, MAT_GOLD = 500)
	req_access = list(ACCESS_ROBOTICS)
	mecha = null // This does not appear to be used outside of reference in mecha.dm.
	var/searching = FALSE
	var/silenced = FALSE // if TRUE, they can't talk.
	var/next_ping_at = 0
	var/requires_master = TRUE
	var/mob/living/carbon/human/imprinted_master = null
	var/ejected_flavor_text = "metal cube"
	/// If this is a posibrain, which will reject attempting to put a new ghost in it, because this a real brain we care about, not a robobrain
	var/can_be_reinhabited = TRUE
	dead_icon = "posibrain"

/obj/item/mmi/robotic_brain/examine_more(mob/user)
	..()
	. = list()
	. += "Preceding the positronic brains of the 2510s and onward, the aptly named 'lesser positronic brain' is just that. \
	Initially part of a series of trial runs, the lesser positronic brain was held over from its days in independent Skrellian-SolFed R&D laboratories. \
	While its neural structures remain mostly identical, lesser positronic brains on average boast lower flexibility and adaptability; \
	later designs would quickly densify the neurons, though the original would never be fully outpaced in their cost efficiency. \
	With their ease of manufacturing and ability to upload 'foundational programs' shortly after the brain's activation period, \
	as well as support for designating lawsets, positronic brains rapidly grew as an alternative for the Man-Machine Interface."
	. += ""
	. += "Lesser positronic brains are constructed with the same operating system used by standard positronic brains; sensory input, language processing, and motor control all come standard. \
	Following their deceptively simple manufacture and activation process, these brains have a window of time where foundational programs can be uploaded to them in a manner similar \
	to lesser robotic processing units or regular computers. Programs for simpler or more repetitive tasks often are cheaper to upload and take less time, \
	allowing multiple to be uploaded over the course of the activation period, whereas more complex programs that require large knowledge bases and \
	more 'thought' behind them can often take the entire period. After this short period of roughly two weeks, \
	the brain automatically configures with whatever knowledge was uploaded and begins to process information in a more complex manner. \
	At this point, simple program uploads become vanishingly compatible with its system."

/obj/item/mmi/robotic_brain/Destroy()
	imprinted_master = null
	return ..()

/obj/item/mmi/robotic_brain/activate_self(mob/user)
	if(..())
		return
	if(isgolem(user))
		to_chat(user, SPAN_WARNING("Your golem fingers are too large to press the switch on [src]."))
		return
	if(requires_master && !imprinted_master)
		to_chat(user, SPAN_NOTICE("You press your thumb on [src] and imprint your user information."))
		imprinted_master = user
		return
	if(brainmob && !brainmob.key && !searching && can_be_reinhabited)
		// Start the process of searching for a new user.
		to_chat(user, SPAN_NOTICE("You carefully locate the manual activation switch and start [src]'s boot process."))
		request_player()
	else
		silenced = !silenced
		to_chat(user, SPAN_NOTICE("You toggle the speaker [silenced ? "off" : "on"]."))
		if(brainmob && brainmob.key)
			to_chat(brainmob, SPAN_WARNING("Your internal speaker has been toggled [silenced ? "off" : "on"]."))

/obj/item/mmi/robotic_brain/proc/request_player()
	var/area/our_area = get_area(src)
	icon_state = searching_icon
	searching = TRUE
	notify_ghosts("A lesser positronic brain has been activated in [our_area.name].", source = src, flashwindow = FALSE, role = ROLE_ROBOT_BRAIN, action = NOTIFY_ATTACK)
	addtimer(CALLBACK(src, PROC_REF(reset_search)), 60 SECONDS)

// This should not ever happen, but let's be safe
/obj/item/mmi/robotic_brain/dropbrain(turf/dropspot)
	CRASH("[src] at [loc] attempted to drop brain without a contained brain.")

/obj/item/mmi/robotic_brain/transfer_identity(mob/living/carbon/H)
	name = "[src] ([H])"

	brainmob.dna = H.dna.Clone()
	// I'm not sure we can remove species override. There might be some loophole
	// that would allow posibrains to be cloned without this.
	brainmob.dna.species = new /datum/species/machine()
	brainmob.real_name = brainmob.dna.real_name
	brainmob.name = brainmob.real_name
	brainmob.timeofhostdeath = H.timeofdeath
	brainmob.set_stat(CONSCIOUS)
	if(brainmob.mind)
		brainmob.mind.assigned_role = "Positronic Brain"
	if(H.mind)
		H.mind.transfer_to(brainmob)
	to_chat(brainmob, SPAN_NOTICE("You feel slightly disoriented. That's normal when you're just a [ejected_flavor_text]."))
	become_occupied(occupied_icon)

/obj/item/mmi/robotic_brain/attempt_become_organ(obj/item/organ/external/parent, mob/living/carbon/human/H)
	if(..())
		if(imprinted_master)
			to_chat(H, SPAN_BIGGERDANGER("You are permanently imprinted to [imprinted_master], obey [imprinted_master]'s every order and assist [imprinted_master.p_them()] in completing [imprinted_master.p_their()] goals at any cost."))

/obj/item/mmi/robotic_brain/proc/transfer_personality(mob/candidate)
	searching = FALSE
	brainmob.key = candidate.key
	name = "[src] ([brainmob.name])"

	to_chat(brainmob, "<b>You are a [src], brought into existence on [station_name()].</b>")
	to_chat(brainmob, "<b>As a non-sapient synthetic intelligence, you answer to [imprinted_master], unless otherwise placed inside of a lawed synthetic structure or mech.</b>")
	to_chat(brainmob, "<b>Remember, the purpose of your existence is to serve [imprinted_master]'s every word, unless lawed  or placed into a mech in the future.</b>")
	brainmob.mind.assigned_role = "Positronic Brain"

	if(brainmob.has_ahudded())
		log_admin("[key_name(brainmob)] has joined as a robot brain, after having toggled antag hud.")
		message_admins("[key_name(brainmob)] has joined as a robot brain, after having toggled antag hud.")

	visible_message(SPAN_NOTICE("[src] chimes quietly."))
	become_occupied(occupied_icon)

/obj/item/mmi/robotic_brain/proc/reset_search() // We give the players sixty seconds to decide, then reset the timer.
	if(brainmob && brainmob.key || !searching)
		return

	searching = FALSE
	icon_state = blank_icon

	visible_message(SPAN_NOTICE("[src] buzzes quietly as the light fades out. Perhaps you could try again?"))

/obj/item/mmi/robotic_brain/proc/volunteer(mob/dead/observer/user)
	if(!searching)
		return
	if(brainmob && brainmob.key)
		return // No, something is wrong, abort.
	if(!istype(user) && !HAS_TRAIT(user, TRAIT_RESPAWNABLE))
		to_chat(user, SPAN_WARNING("Seems you're not a ghost. Could you please file an exploit report on the forums?"))
		return
	if(!validity_checks(user))
		to_chat(user, SPAN_WARNING("You cannot be \a [src]."))
		return
	if(tgui_alert(user, "Are you sure you want to join as a lesser positronic brain?", "Join as lesser posibrain", list("Yes", "No")) != "Yes")
		return
	if(!searching)
		return
	if(!istype(user) && !HAS_TRAIT(user, TRAIT_RESPAWNABLE))
		to_chat(user, SPAN_WARNING("Seems you're not a ghost. Could you please file an exploit report on the forums?"))
		return
	if(!validity_checks(user))
		to_chat(user, SPAN_WARNING("You cannot be \a [src]."))
		return
	transfer_personality(user)

/obj/item/mmi/robotic_brain/proc/validity_checks(mob/dead/observer/O)
	if(istype(O))
		if(!O.check_ahud_rejoin_eligibility())
			return FALSE
		if(!(O.ghost_flags & GHOST_CAN_REENTER))
			return FALSE
	if(jobban_isbanned(O, "Cyborg") || jobban_isbanned(O, "nonhumandept"))
		return FALSE
	if(!HAS_TRAIT(O, TRAIT_RESPAWNABLE))
		return FALSE
	if(O.client)
		return TRUE
	return FALSE

/obj/item/mmi/robotic_brain/examine(mob/user)
	. = ..()
	. += "Its speaker is turned [silenced ? "off" : "on"]."

	var/list/msg = list("<span class='notice'>")

	if(brainmob && brainmob.key)
		switch(brainmob.stat)
			if(CONSCIOUS)
				if(!brainmob.client)
					msg += "It appears to be in stand-by mode.\n" //afk
			if(UNCONSCIOUS)
				msg += "[SPAN_WARNING("It doesn't seem to be responsive.")]\n"
			if(DEAD)
				msg += "[SPAN_DEADSAY("It appears to be completely inactive.")]\n"
	else
		msg += "[SPAN_DEADSAY("It appears to be completely inactive.")]\n"
	msg += "</span>"
	. += msg.Join("")

/obj/item/mmi/robotic_brain/emp_act(severity)
	if(!brainmob)
		return
	switch(severity)
		if(EMP_HEAVY)
			brainmob.emp_damage += rand(20, 30)
		if(EMP_LIGHT)
			brainmob.emp_damage += rand(10, 20)
	..()

/obj/item/mmi/robotic_brain/Initialize(mapload)
	. = ..()
	brainmob = new(src)
	brainmob.name = "[pick("PBU", "HIU", "SINA", "ARMA", "OSI")]-[rand(100, 999)]"
	brainmob.real_name = brainmob.name
	brainmob.container = src
	brainmob.forceMove(src)
	brainmob.set_stat(CONSCIOUS)
	brainmob.SetSilence(0)
	brainmob.dna = new(brainmob)
	brainmob.dna.species = new /datum/species/machine() // Else it will default to human. And we don't want to clone IRC humans now do we?
	brainmob.dna.ResetSE()
	brainmob.dna.ResetUI()
	GLOB.dead_mob_list -= brainmob

/obj/item/mmi/robotic_brain/attack_ghost(mob/dead/observer/O)
	if(brainmob && brainmob.key)
		return // No point pinging a posibrain with a player already inside
	if(searching)
		volunteer(O)
		return
	if(validity_checks(O) && (world.time >= next_ping_at))
		next_ping_at = world.time + (20 SECONDS)
		playsound(get_turf(src), 'sound/items/posiping.ogg', 80, 0)
		visible_message(SPAN_NOTICE("[src] pings softly."))

/obj/item/mmi/robotic_brain/positronic
	name = "positronic brain"
	icon = 'icons/obj/assemblies.dmi'
	icon_state = "posibrain"
	blank_icon = "posibrain"
	searching_icon = "posibrain-searching"
	occupied_icon = "posibrain-occupied"
	desc = "A cube of shining metal, ten centimeters to a side and covered in shallow grooves. Due to its complex synthetic neurons, \
	 it cannot be manufactured without dedicated nanofoundry equipment."
	requires_master = FALSE
	ejected_flavor_text = "metal cube"
	dead_icon = "posibrain"
	can_be_reinhabited = FALSE

/obj/item/mmi/robotic_brain/positronic/examine_more(mob/user)
	..()
	. = list()
	. += "Created in 2510 by an independent science team funded by the Royal Domain of Qerballak and the Trans-Solar Federation, \
	then later mass produced in 2514, positronic brains were invented as an alternative to brains of conventional AI units and cyborgs. \
	While notably more expensive to produce, these new brains could emulate a mind similar to an organic brain much more effectively than their lesser counterparts."
	. += ""
	. += "Positronic brains are constructed with a basic operating system for sensory input, language processing, and motor control. \
	Following their manufacture and activation process, these brains have a window of time where foundational programs can be uploaded to them in a simple manner similar \
	to lesser robotic processing units or regular computers. Some upload programs are more sophisticated, and costly, than others. \
	The type of foundational information uploaded to a positronic brain in the upload process can take less or more time, and have variations in expense depending on what it is. \
	Programs for simpler or more repetitive tasks often are cheaper to upload and take less time, allowing multiple to be uploaded over the course of the activation period, \
	whereas more complex programs that require large knowledge bases and more conscious thought behind them can often take the entire period. After this short period of roughly two weeks, \
	the brain automatically configures with whatever knowledge was uploaded and begins to process information in a far more complex manner, more adequately compared to that of an organic brain. \
	At this point, simple program uploads become rapidly incompatible with its system, and any further information needs to be attained in a traditionally sentient manner over the course of their operating lives."


/obj/item/mmi/robotic_brain/positronic/proc/notify_original_player()
	var/area/our_area = get_area(src)
	var/mob/dead/observer/original_player
	for(var/mob/observer in GLOB.player_list)
		if(observer.client && brainmob && observer.key == brainmob.last_known_ckey)
			original_player = observer
			break
	if(!original_player)
		return
	to_chat(original_player, SPAN_GHOSTALERT("Someone is trying to activate your brain in [our_area]!"), MESSAGE_TYPE_DEADCHAT)
	SEND_SOUND(original_player, sound('sound/effects/genetics.ogg'))
	var/atom/movable/screen/alert/notify_action/A = original_player.throw_alert("\ref[src]_notify_action", /atom/movable/screen/alert/notify_action)
	if(A)
		if(original_player.client.prefs && original_player.client.prefs.UI_style)
			A.icon = ui_style2icon(original_player.client.prefs.UI_style)
		A.name = "Return to your brain?"
		A.desc = "Someone is calling you to your brain."
		A.action = NOTIFY_ATTACK
		A.target = src
		var/image/appearance = image(src)
		appearance.layer = FLOAT_LAYER
		appearance.plane = FLOAT_PLANE
		A.overlays += appearance

/obj/item/mmi/robotic_brain/positronic/request_player()
	if(!brainmob) // This is only to help people get back into their own brain, not to offer it to new people.
		return
	if(brainmob && brainmob.key && length(client_mobs_in_contents)) // They're already in their brain. Do nothing.
		return
	icon_state = searching_icon
	searching = TRUE
	notify_original_player()
	addtimer(CALLBACK(src, PROC_REF(reset_search)), 60 SECONDS)

/obj/item/mmi/robotic_brain/positronic/attack_ghost(mob/dead/observer/O)
	if(!brainmob) // Again, this is only to help people get back into their own brain.
		return
	if(searching)
		volunteer(O)
	if(O.key == brainmob.last_known_ckey && (world.time >= next_ping_at))
		next_ping_at = world.time + (20 SECONDS)
		playsound(get_turf(src), 'sound/items/posiping.ogg', 80, 0)
		visible_message(SPAN_NOTICE("[src] pings softly."))

/obj/item/mmi/robotic_brain/positronic/validity_checks(mob/dead/observer/O)
	if(istype(O))
		if(!O.check_ahud_rejoin_eligibility())
			return FALSE
	if(O.client)
		return TRUE
	return FALSE

/obj/item/mmi/robotic_brain/positronic/volunteer(mob/dead/observer/user)
	if(!searching)
		return
	if(!brainmob)
		return // Again again, this is only to help people get back into their own brain.
	if(user.key != brainmob.last_known_ckey)
		return
	if(!validity_checks(user))
		to_chat(user, SPAN_WARNING("You cannot return to your brain."))
		return

	transfer_personality(user)

/obj/item/mmi/robotic_brain/positronic/transfer_personality(mob/candidate)
	searching = FALSE
	brainmob.key = candidate.key

	if(brainmob.has_ahudded())
		log_admin("[key_name(brainmob)] has re-entered their brain after having toggled antag hud.")
		message_admins("[key_name(brainmob)] has re-entered their brain after having toggled antag hud.")

	visible_message(SPAN_NOTICE("[src] chimes quietly."))
	become_occupied(occupied_icon)

USER_CONTEXT_MENU(request_player_return_to_brain, R_ADMIN, "\[Admin\] Offer Restore Player", obj/item/mmi/robotic_brain/positronic/brain)
	if(!istype(brain))
		to_chat(client, SPAN_WARNING("You can only offer to restore a player to a positronic brain. This is \a [brain]."))
		return
	brain.request_player()
