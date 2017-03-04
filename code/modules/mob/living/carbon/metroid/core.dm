// Basically this Metroid Core catalyzes reactions that normally wouldn't happen anywhere
// Standart, useless type 6 core
/obj/item/metroid_core
	name = "metroid core"
	desc = "A very slimy and tender part of a Metroid. They also legend to have \"magical powers\"."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "metroid core"
	flags = FPRINT
	force = 1.0
	w_class = W_CLASS_TINY
	throwforce = 1.0
	throw_speed = 3
	throw_range = 6
	origin_tech = Tc_BIOTECH + "=4"
	var/uses = 99999 // uses before it goes inert, infinite

/obj/item/metroid_core/New()
	..()
	var/datum/reagents/R = new/datum/reagents(50)
	reagents = R
	R.my_atom = src

////////*Types*///////

/obj/item/metroid_core/t1
/obj/item/metroid_core/t2
/obj/item/metroid_core/t3
/obj/item/metroid_core/t4
/obj/item/metroid_core/t5
// see Chemistry-Recipes.dm