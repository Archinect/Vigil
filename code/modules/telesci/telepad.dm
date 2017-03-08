///SCI TELEPAD///
/obj/machinery/telepad
	name = "telepad"
	desc = "A bluespace telepad used for teleporting objects to and from a location."
	icon = 'icons/obj/telescience.dmi'
	icon_state = "pad-idle"
	anchored = 1
	use_power = 1
	idle_power_usage = 200
	active_power_usage = 5000

	// Bluespace crystal!
	var/obj/item/bluespace_crystal/amplifier=null
	var/opened=0

/obj/machinery/telepad/attackby(obj/item/I, mob/user, params)

	if(panel_open)
		if(istype(I, /obj/item/device/multitool))
			var/obj/item/device/multitool/M = I
			M.buffer = src
			user << "<span class = 'caution'>You save the data in the [I.name]'s buffer.</span>"

	if(exchange_parts(user, I))
		return