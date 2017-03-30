/**
 * Multitool -- A multitool is used for hacking electronic devices.
 * TO-DO -- Using it as a power measurement tool for cables etc. Nannek.
 *
 */

/obj/item/device/debugger
	icon = 'icons/obj/hacktool.dmi'
	name = "debugger"
	desc = "Used to debug electronic equipment."
	icon_state = "hacktool"
	flags = FPRINT
	siemens_coefficient = 1
	force = 5.0
	w_class = W_CLASS_SMALL
	throwforce = 5.0
	throw_range = 15
	throw_speed = 3
	desc = "An item of dubious origins, with wires and antennas protruding out of it."
	starting_materials = list(MAT_IRON = 50, MAT_GLASS = 20)
	w_type = RECYK_ELECTRONIC
	melt_temperature = MELTPOINT_SILICON
	origin_tech = Tc_MAGNETS + "=1;" + Tc_ENGINEERING + "=1"
	var/obj/machinery/telecomms/buffer // simple machine buffer for device linkage

/obj/item/device/hacktool/engineer
	icon = 'icons/obj/hacktool.dmi'
	name = "debugger"
	desc = "An item of immense complexion, it appears to work by magic."
	icon_state = "hacktool-g"

/obj/item/device/debugger/is_used_on(obj/O, mob/user)
	if(istype(O, /obj/machinery/power/apc))
		var/obj/machinery/power/apc/A = O
		if(A.emagged || A.malfhack)
			to_chat(user, "<span class='warning'>There is a software error with the device.</span>")
		else
			to_chat(user, "<span class='notice'>The device's software appears to be fine.</span>")
		return 1
//	if(istype(O, /obj/machinery/door))
//		var/obj/machinery/door/D = O
//		if(D.operating == -1)
//			to_chat(user, "<span class='warning'>There is a software error with the device.</span>")
//		else
//			to_chat(user, "<span class='notice'>The device's software appears to be fine.</span>")
//		return 1
	else if(istype(O, /obj/machinery))
		var/obj/machinery/A = O
		if(A.emagged)
			to_chat(user, "<span class='warning'>There is a software error with the device.</span>")
		else
			to_chat(user, "<span class='notice'>The device's software appears to be fine.</span>")
		return 1

/obj/machinery/door/airlock/proc/canSynControl()
	return (src.synDoorHacked && (!src.isAllPowerCut()));

/obj/machinery/door/airlock/proc/canSynHack(obj/item/device/hacktool/H)
	return (in_range(src, usr) && get_dist(src, H) <= 1 && src.synDoorHacked==0 && !src.isAllPowerCut());

/obj/machinery/door/airlock/proc/synhack(mob/user as mob, obj/item/device/hacktool/I)
	if (src.synHacking==0)
		var/multiplier = 1.5
		if(istype(I, /obj/item/device/hacktool/engineer))
			if(!src.locked)
				to_chat(user, "The door bolts are already up!")
				return
			multiplier -= 0.5
		src.synHacking=1
		I.in_use = 1
		to_chat(user, "You begin hacking...")
		spawn(20*multiplier)
			to_chat(user, "Jacking in. Stay close to the airlock or you'll rip the cables out and we'll have to start over.")
			sleep(25*multiplier)
			if (src.canSynControl() && !istype(I, /obj/item/device/hacktool/engineer))
				to_chat(user, "Hack cancelled, control already possible.")
				src.synHacking=0
				I.in_use = 0
				return
			else
				if (!src.canSynHack(I))
					to_chat(user, "\red Connection lost. Stand still and stay near the airlock!")
					src.synHacking=0
					I.in_use = 0
					return
			to_chat(user, "Connection established.")
			sleep(10*multiplier)
			to_chat(user, "Attempting to hack into airlock. This may take some time.")
			sleep(50*multiplier)
			if (!src.canSynHack(I))
				to_chat(user, "\red Hack aborted: landline connection lost. Stay closer to the airlock.")
				src.synHacking=0
				I.in_use = 0
				return
			else
				if (src.canSynControl() && !istype(I, /obj/item/device/hacktool/engineer))
					to_chat(user, "Local override already in place, hack aborted.")
					src.synHacking=0
					I.in_use = 0
					return
			to_chat(user, "Upload access confirmed. Loading control program into airlock software.")
			sleep(35*multiplier)
			if (!src.canSynHack(I))
				to_chat(user, "\red Hack aborted: cable connection lost. Do not move away from the airlock.")
				src.synHacking=0
				I.in_use = 0
				return
			else
				if (src.canSynControl() && !istype(I, /obj/item/device/hacktool/engineer))
					to_chat(user, "Upload access aborted, local override already in place.")
					src.synHacking=0
					I.in_use = 0
					return
			to_chat(user, "Transfer complete. Forcing airlock to execute program.")
			sleep(25*multiplier)
			//disable blocked control
			if(istype(I, /obj/item/device/hacktool/engineer))
				to_chat(user, "Raising door bolts...")
				src.synHacking = 0
				src.locked = 0
				I.in_use = 0
				update_icon()
				return
			src.synDoorHacked = 1
			to_chat(user, "Bingo! We're in. Airlock control panel coming right up.")
			sleep(5)
			//bring up airlock dialog
			src.synHacking = 0
			I.in_use = 0
			src.attack_ai(user, I)

			// Alerting the AIs
//			var/list/cameras = list()
//			for (var/obj/machinery/camera/C in src.loc.loc.contents) // getting all cameras in the area
//				cameras += C
//			var/alertoption = (prob(alert_probability) || istype(I, /obj/item/device/hacktool/engineer)) // Chance of warning AI, based on doortype's probability
//			if(alertoption)
//				if(prob(15))       //15% chance of sending the AI all the details (camera, area, warning)
//					alertoption = 3
//				else if (prob(18)) //18% chance of sending the AI just the area
//					alertoption = 2
//				for (var/mob/living/silicon/ai/aiPlayer in world)
//					if (aiPlayer.stat != 2)
//						switch(alertoption)
//							if(3) aiPlayer.triggerUnmarkedAlarm("AirlockHacking", src.loc.loc, cameras)
//							if(2) aiPlayer.triggerUnmarkedAlarm("AirlockHacking", src.loc.loc)
//							if(1) aiPlayer.triggerUnmarkedAlarm("AirlockHacking")
//				for (var/mob/living/silicon/robot/robotPlayer in world)
//					if (robotPlayer.stat != 2)
//						switch(alertoption)
//							if(2,3) robotPlayer.triggerUnmarkedAlarm("AirlockHacking", src.loc.loc)
//							if(1)   robotPlayer.triggerUnmarkedAlarm("AirlockHacking")
				// ...And done