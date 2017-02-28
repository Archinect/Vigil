/obj/item/device/telepadremote
	icon = 'icons/obj/hacktool.dmi'
	name = "telepad remote control"
	icon_state = "hacktool_alt"
	item_state = "electronic"
	w_class = W_CLASS_SMALL
	origin_tech = "magnets=2;engineering=3;bluespace=2"
	var/obj/machinery/computer/telescience/linked

/obj/item/device/telepadremote/attack_self(mob/user as mob)
	if(!istype(linked))
		user << "\red Connection to telepad failed."
	else
		user.set_machine(linked)
		linked.interact(user)
		return