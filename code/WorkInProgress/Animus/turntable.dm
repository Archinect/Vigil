/obj/machinery/party/turntable/
	name = "space turntable"
	icon = 'icons/ss13_dark_alpha7_old.dmi'
	icon_state = "turntable"
	anchored = 1
	density = 1
	power_channel = EQUIP
	use_power = 1
	idle_power_usage = 10
	active_power_usage = 100

	var/playing = 0

	var/current_track = ""
	var/list/tracks = list(
		"Grain of Sand in Sandwich"			= list('sound/turntable/AGrainOfSandInSandwich.ogg'),
		"Beyond the Sea"	= list('sound/turntable/BeyondTheSea.ogg'),
		"Cantina"			= list('sound/turntable/Cantina.ogg'),
		"Children in the shadows"			= list('sound/turntable/Children_in_the_shadows.ogg'),
		"Piano Black&White"			= list('sound/turntable/Cowboy_Bebop_-_Piano_Black.ogg'),
		"Space Sickness"		= list('sound/turntable/down_with_the_sickness.ogg'),
		"Remember the Moon"			= list('sound/turntable/Fly_me_to_the_moon.ogg'),
		"Groovy"			= list('sound/turntable/GroovyTime.ogg'),
		"Had to be you"			= list('sound/turntable/ItHadToBeYou.ogg'),
		"Jazz under your skin"	= list('sound/turntable/IveGotYouUnderMySkin.ogg'),
		"Kyou Wa Yuuhi Yarou"		= list('sound/turntable/KyouWaYuuhiYarou.ogg'),
		"Mutebeat"			= list('sound/turntable/MuteBeat.ogg'),
		"Onizuka Blues"		= list('sound/turntable/OnizukasBlues.ogg'),
		"That's all"		= list('sound/turntable/ThatsAll.ogg'),
		"Space Oddity"		= list('sound/music/david_bowie-space_oddity_original.ogg'),
		"The skeleton in the closet"		= list('sound/turntable/The_sceleton_in_the_closet.ogg'),
		"Jesse James Eulogy"			= list('sound/turntable/TheAssassinationofJesseJames.ogg'),
		"The Entertainer"				= list('sound/turntable/TheEntertainer.ogg'),
		"The Way You Look Tonight"	= list('sound/turntable/TheWayYouLookTonight.ogg'),
		"They Were All Dead"		= list('sound/turntable/TheyWereAllDead.ogg'),
		"Wade in the Water"	= list('sound/turntable/WadeInTheWater.ogg')
	)

/obj/machinery/party/turntable/Destroy()
	StopPlaying()
	..()

/obj/machinery/party/turntable/power_change()
	if(!powered(power_channel) || !anchored)
		stat |= NOPOWER
	else
		stat &= ~NOPOWER

	if(stat & (NOPOWER|BROKEN) && playing)
		StopPlaying()

/obj/machinery/party/turntable/Topic(href, href_list)
	var/area/RA = get_area(src)
	if(..() || !(Adjacent(usr) || issilicon(usr)))
		return

	if(!anchored)
		usr << "<span class='warning'>You must secure \the [src] first.</span>"
		return

	if(stat & (NOPOWER|BROKEN))
		usr << "\The [src] doesn't appear to function."
		return

	if(href_list["change_track"])
		var/T = href_list["title"]
		if(T)
			current_track = T
			StartPlaying()
			for(RA)
				for(var/obj/machinery/party/lasermachine/L in RA)
					L.turnon()
	else if(href_list["stop"])
		StopPlaying()
		for(RA)
			for(var/obj/machinery/party/lasermachine/L in RA)
				L.turnoff()
	else if(href_list["play"])
		if(emagged)
			playsound(src.loc, 'sound/items/AirHorn.ogg', 100, 1)
			for(var/mob/living/carbon/M in ohearers(6, src))
				M.sleeping = 0
				M.stuttering += 20
				M.ear_deaf += 30
				if(prob(30))
					M.Stun(10)
					M.Paralyse(4)
			spawn(15)
				explode()
		else if(!current_track)
			usr << "No track selected."
		else
			StartPlaying()

	return 1

/obj/machinery/party/turntable/interact(mob/user)
	if(stat & (NOPOWER|BROKEN))
		usr << "\The [src] doesn't appear to function."
		return

	ui_interact(user)

/obj/machinery/party/turntable/ui_interact(mob/user, ui_key = "jukebox", var/datum/nanoui/ui = null, var/force_open = 1)
	var/title = "RetroBox - Space Style"
	var/data[0]

	if(!(stat & (NOPOWER|BROKEN)))
		data["current_track"] = current_track ? current_track : ""
		data["playing"] = playing

		var/list/nano_tracks = list()
		for(var/T in tracks)
			nano_tracks += T

		data["tracks"] = nano_tracks

	// update the ui if it exists, returns null if no ui is passed/found
	ui = nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		// the ui does not exist, so we'll create a new() one
        // for a list of parameters and their descriptions see the code docs in \code\modules\nano\nanoui.dm
		ui = new(user, src, ui_key, "jukebox.tmpl", title, 450, 600)
		// when the ui is first opened this is the data it will use
		ui.set_initial_data(data)
		// open the new ui window
		ui.open()

/obj/machinery/party/turntable/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/party/turntable/attack_hand(var/mob/user as mob)
	interact(user)

/obj/machinery/party/turntable/proc/explode()
	walk_to(src,0)
	src.visible_message("<span class='danger'>\the [src] blows apart!</span>", 1)

	explosion(src.loc, 0, 0, 1, rand(1,2), 1)

	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(3, 1, src)
	s.start()

	new /obj/effect/decal/cleanable/blood/oil(src.loc)
	qdel(src)

/obj/machinery/party/turntable/attackby(obj/item/W as obj, mob/user as mob)
	src.add_fingerprint(user)

	if(istype(W, /obj/item/weapon/wrench))
		if(playing)
			StopPlaying()
		user.visible_message("<span class='warning'>[user] has [anchored ? "un" : ""]secured \the [src].</span>", "<span class='notice'>You [anchored ? "un" : ""]secure \the [src].</span>")
		anchored = !anchored
		playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
		power_change()
		return
	return ..()

/obj/machinery/party/turntable/emag_act(var/remaining_charges, var/mob/user)
	if(!emagged)
		emagged = 1
		StopPlaying()
		visible_message("<span class='danger'>\The [src] makes a fizzling sound.</span>")
		return 1

/obj/machinery/party/turntable/proc/StopPlaying()
	var/area/main_area = get_area(src)
	// Always kill the current sound
	for(var/mob/living/M in mobs_in_area(main_area))
		M << sound(null, channel = 1)

		main_area.forced_ambience = null
	playing = 0


/obj/machinery/party/turntable/proc/StartPlaying()
	StopPlaying()
	if(!current_track)
		return

	var/area/main_area = get_area(src)
	main_area.forced_ambience = list(pick(tracks[current_track]))
	for(var/mob/living/M in mobs_in_area(main_area))
		if(M.mind)
			main_area.play_ambience(M)

	playing = 1
	update_icon()

/obj/machinery/party/mixer
	name = "mixer"
	desc = "A mixing board for mixing music"
	icon = 'icons/ss13_dark_alpha7_old.dmi'
	icon_state = "mixer"
	density = 0
	anchored = 1

/obj/machinery/party/lasermachine
	name = "laser machine"
	desc = "A laser machine that shoots lasers."
	icon = 'icons/ss13_dark_alpha7_old.dmi'
	icon_state = "lasermachine"
	anchored = 1
	var/mirrored = 0

/obj/effects/laser
	name = "laser"
	desc = "A laser..."
	icon = 'icons/ss13_dark_alpha7_old.dmi'
	icon_state = "laserred1"
	anchored = 1
	layer = 4

/obj/item/lasermachine/New()
	..()

/obj/machinery/party/lasermachine/proc/turnon()
	var/wall = 0
	var/cycle = 1
	var/area/A = get_area(src)
	var/X = 1
	var/Y = 0
	if(mirrored == 0)
		while(wall == 0)
			if(cycle == 1)
				var/obj/effects/laser/F = new/obj/effects/laser(src)
				F.x = src.x+X
				F.y = src.y+Y
				F.z = src.z
				F.icon_state = "laserred1"
				var/area/AA = get_area(F)
				var/turf/T = get_turf(F)
				if(T.density == 1 || AA.name != A.name)
					del(F)
					return
				cycle++
				if(cycle > 3)
					cycle = 1
				X++
			if(cycle == 2)
				var/obj/effects/laser/F = new/obj/effects/laser(src)
				F.x = src.x+X
				F.y = src.y+Y
				F.z = src.z
				F.icon_state = "laserred2"
				var/area/AA = get_area(F)
				var/turf/T = get_turf(F)
				if(T.density == 1 || AA.name != A.name)
					del(F)
					return
				cycle++
				if(cycle > 3)
					cycle = 1
				Y++
			if(cycle == 3)
				var/obj/effects/laser/F = new/obj/effects/laser(src)
				F.x = src.x+X
				F.y = src.y+Y
				F.z = src.z
				F.icon_state = "laserred3"
				var/area/AA = get_area(F)
				var/turf/T = get_turf(F)
				if(T.density == 1 || AA.name != A.name)
					del(F)
					return
				cycle++
				if(cycle > 3)
					cycle = 1
				X++
	if(mirrored == 1)
		while(wall == 0)
			if(cycle == 1)
				var/obj/effects/laser/F = new/obj/effects/laser(src)
				F.x = src.x+X
				F.y = src.y-Y
				F.z = src.z
				F.icon_state = "laserred1m"
				var/area/AA = get_area(F)
				var/turf/T = get_turf(F)
				if(T.density == 1 || AA.name != A.name)
					del(F)
					return
				cycle++
				if(cycle > 3)
					cycle = 1
				Y++
			if(cycle == 2)
				var/obj/effects/laser/F = new/obj/effects/laser(src)
				F.x = src.x+X
				F.y = src.y-Y
				F.z = src.z
				F.icon_state = "laserred2m"
				var/area/AA = get_area(F)
				var/turf/T = get_turf(F)
				if(T.density == 1 || AA.name != A.name)
					del(F)
					return
				cycle++
				if(cycle > 3)
					cycle = 1
				X++
			if(cycle == 3)
				var/obj/effects/laser/F = new/obj/effects/laser(src)
				F.x = src.x+X
				F.y = src.y-Y
				F.z = src.z
				F.icon_state = "laserred3m"
				var/area/AA = get_area(F)
				var/turf/T = get_turf(F)
				if(T.density == 1 || AA.name != A.name)
					del(F)
					return
				cycle++
				if(cycle > 3)
					cycle = 1
				X++


/obj/machinery/party/lasermachine/proc/turnoff()
	for(var/area/RA in src.loc.loc)
		for(var/obj/effects/laser/F in RA)
			del(F)


/obj/machinery/party/gramophone
	name = "Gramophone"
	desc = "Old-time styley."
	icon = 'icons/obj/musician.dmi'
	icon_state = "gramophone"
	anchored = 1
	density = 1

	var/playing = 0

	var/current_track = ""
	var/list/tracks = list(
		"Tainted Love"			= list('sound/turntable/taintedlove.ogg'),
		"Unionists March"				= list('sound/turntable/soviet.ogg')
	)

/obj/machinery/party/gramophone/Destroy()
	StopPlaying()
	..()

/obj/machinery/party/gramophone/Topic(href, href_list)
	var/area/RA = get_area(src)
	if(..() || !(Adjacent(usr) || issilicon(usr)))
		return

	if(!anchored)
		usr << "<span class='warning'>You must secure \the [src] first.</span>"
		return

	if(href_list["change_track"])
		var/T = href_list["title"]
		if(T)
			current_track = T
			StartPlaying()
			for(RA)
				for(var/obj/machinery/party/lasermachine/L in RA)
					L.turnon()
	else if(href_list["stop"])
		StopPlaying()
		for(RA)
			for(var/obj/machinery/party/lasermachine/L in RA)
				L.turnoff()
	else if(href_list["play"])
		if(emagged)
			playsound(src.loc, 'sound/items/AirHorn.ogg', 100, 1)
			for(var/mob/living/carbon/M in ohearers(6, src))
				M.sleeping = 0
				M.stuttering += 20
				M.ear_deaf += 30
				if(prob(30))
					M.Stun(10)
					M.Paralyse(4)
			spawn(15)
				explode()
		else if(!current_track)
			usr << "No track selected."
		else
			StartPlaying()

	return 1

/obj/machinery/party/gramophone/interact(mob/user)
	ui_interact(user)

/obj/machinery/party/gramophone/ui_interact(mob/user, ui_key = "jukebox", var/datum/nanoui/ui = null, var/force_open = 1)
	var/title = "RetroBox - Space Style"
	var/data[0]

	if(!(stat & (NOPOWER|BROKEN)))
		data["current_track"] = current_track ? current_track : ""
		data["playing"] = playing

		var/list/nano_tracks = list()
		for(var/T in tracks)
			nano_tracks += T

		data["tracks"] = nano_tracks

	// update the ui if it exists, returns null if no ui is passed/found
	ui = nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		// the ui does not exist, so we'll create a new() one
        // for a list of parameters and their descriptions see the code docs in \code\modules\nano\nanoui.dm
		ui = new(user, src, ui_key, "jukebox.tmpl", title, 450, 600)
		// when the ui is first opened this is the data it will use
		ui.set_initial_data(data)
		// open the new ui window
		ui.open()

/obj/machinery/party/gramophone/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/party/gramophone/attack_hand(var/mob/user as mob)
	interact(user)

/obj/machinery/party/gramophone/proc/explode()
	walk_to(src,0)
	src.visible_message("<span class='danger'>\the [src] blows apart!</span>", 1)

	explosion(src.loc, 0, 0, 1, rand(1,2), 1)

	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(3, 1, src)
	s.start()

	new /obj/effect/decal/cleanable/blood/oil(src.loc)
	qdel(src)

/obj/machinery/party/gramophone/attackby(obj/item/W as obj, mob/user as mob)
	src.add_fingerprint(user)

	if(istype(W, /obj/item/weapon/wrench))
		if(playing)
			StopPlaying()
		user.visible_message("<span class='warning'>[user] has [anchored ? "un" : ""]secured \the [src].</span>", "<span class='notice'>You [anchored ? "un" : ""]secure \the [src].</span>")
		anchored = !anchored
		playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
		power_change()
		return
	return ..()

/obj/machinery/party/gramophone/emag_act(var/remaining_charges, var/mob/user)
	if(!emagged)
		emagged = 1
		StopPlaying()
		visible_message("<span class='danger'>\The [src] makes a fizzling sound.</span>")
		return 1

/obj/machinery/party/gramophone/proc/StopPlaying()
	var/area/main_area = get_area(src)
	// Always kill the current sound
	for(var/mob/living/M in mobs_in_area(main_area))
		M << sound(null, channel = 1)

		main_area.forced_ambience = null
	playing = 0

/obj/machinery/party/gramophone/proc/StartPlaying()
	StopPlaying()
	if(!current_track)
		return

	var/area/main_area = get_area(src)
	main_area.forced_ambience = list(pick(tracks[current_track]))
	for(var/mob/living/M in mobs_in_area(main_area))
		if(M.mind)
			main_area.play_ambience(M)

	playing = 1
