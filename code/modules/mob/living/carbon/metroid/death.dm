/mob/living/carbon/metroid/death(gibbed)
	if(stat == DEAD)
		return
	stat = DEAD
	icon_state = "baby metroid dead"

	if(!gibbed)
		if(istype(src, /mob/living/carbon/metroid/adult))
			ghostize()
			explosion(get_turf(src), -1,-1,3,12)
			sleep(2)
			qdel(src)
		else
			for(var/mob/O in viewers(src, null))
				O.show_message("<b>The [name]</b> seizes up and falls limp...", 1) //ded -- Urist

	update_canmove()

	ticker.mode.check_win()

	return ..(gibbed)

/*
/mob/living/carbon/metroid/death(gibbed)
	if(stat == DEAD)	return
	stat = DEAD
	icon_state = "baby metroid dead"

	if(!gibbed)
		if(istype(src, /mob/living/carbon/metroid/adult))
			ghostize()
			explosion(get_turf(src), -1,-1,3,12)
			sleep(2)
			del(src)
		else
			for(var/mob/O in viewers(src, null))
				O.show_message("<b>The [src.name]</b> seizes up and falls limp...", 1) //ded -- Urist

	update_canmove()

	ticker.mode.check_win()

	return ..(gibbed)
*/
