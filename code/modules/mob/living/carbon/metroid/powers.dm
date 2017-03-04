/mob/living/carbon/metroid/verb/Feed()
	set category = "Metroid"
	set desc = "This will let you feed on any valid creature in the surrounding area. This should also be used to halt the feeding process."
	if(Victim)
		Feedstop()
		return

	if(stat)
		to_chat(src, "<i>I must be conscious to do this...</i>")
		return

	var/list/choices = list()
	for(var/mob/living/C in view(1,src))
		if(C!=src && !istype(C,/mob/living/carbon/metroid))
			choices += C

	var/mob/living/carbon/M = input(src,"Who do you wish to feed on?") in null|choices
	if(!M)
		return
	if(M in view(1, src))

		if(!istype(src, /mob/living/carbon/brain))
			if(!istype(M, /mob/living/carbon/metroid))
				if(stat != 2)
					if(health > -70)

						for(var/mob/living/carbon/metroid/met in view())
							if(met.Victim == M && met != src)
								to_chat(src, "<i>The [met.name] is already feeding on this subject...</i>")
								return
						to_chat(src, "\blue <i>I have latched onto the subject and begun feeding...</i>")
						to_chat(M, "\red <b>The [src.name] has latched onto your head!</b>")
						Feedon(M)

					else
						to_chat(src, "<i>This subject does not have a strong enough life energy...</i>")
				else
					to_chat(src, "<i>This subject does not have an edible life energy...</i>")
			else
				to_chat(src, "<i>I must not feed on my brothers...</i>")
		else
			to_chat(src, "<i>This subject does not have an edible life energy...</i>")



/mob/living/carbon/metroid/proc/Feedon(var/mob/living/carbon/M)
	Victim = M
	src.forceMove(M.loc)
	canmove = 0
	anchored = 1
	var/lastnut = nutrition
	//if(M.client) M << "\red You legs become paralyzed!"
	if(istype(src, /mob/living/carbon/metroid/adult))
		icon_state = "adult metroid eat"
	else
		icon_state = "baby metroid eat"
	add_logs(src, Victim, "fed on", 0)
	while(Victim && M.health > -70 && stat != 2)
		// M.canmove = 0
		canmove = 0

		if(M in view(1, src))
			loc = M.loc

			if(prob(15) && M.client && istype(M, /mob/living/carbon))
				to_chat(M, "<span class='warning'>[pick("You can feel your body becoming weak!", \
				"You feel like you're about to die!", \
				"You feel every part of your body screaming in agony!", \
				"A low, rolling pain passes through your body!", \
				"Your body feels as if it's falling apart!", \
				"You feel extremely weak!", \
				"A sharp, deep pain bathes every inch of your body!")]")

			if(istype(M, /mob/living/carbon))
				Victim.adjustCloneLoss(rand(1,10))
				Victim.adjustToxLoss(rand(1,2))
				if(Victim.health <= 0)
					Victim.adjustToxLoss(rand(2,4))

				// Heal yourself
				adjustToxLoss(-10)
				adjustOxyLoss(-10)
				adjustBruteLoss(-10)
				adjustFireLoss(-10)
				adjustCloneLoss(-10)

				if(Victim)
					for(var/mob/living/carbon/metroid/Metroid in view(1,M))
						if(Metroid.Victim == M && Metroid != src)
							Metroid.Feedstop()

				nutrition += rand(10,25)
				if(nutrition >= lastnut + 50)
					if(prob(80))
						lastnut = nutrition
						powerlevel++
						if(powerlevel > 10)
							powerlevel = 10

				if(istype(src, /mob/living/carbon/metroid/adult))
					if(nutrition > 1200)
						nutrition = 1200
				else
					if(nutrition > 1000)
						nutrition = 1000

				Victim.updatehealth()
				updatehealth()

			else
				if(prob(25))
					to_chat(src, "<span class='warning'><i>[pick("This subject is incompatable", \
					"This subject does not have a life energy", "This subject is empty", \
					"I am not satisified", "I can not feed from this subject", \
					"I do not feel nourished", "This subject is not food")]...</i>")

			sleep(rand(15,45))

		else
			break

	if(stat == 2)
		if(!istype(src, /mob/living/carbon/metroid/adult))
			icon_state = "baby metroid dead"

	else
		if(istype(src, /mob/living/carbon/metroid/adult))
			icon_state = "adult metroid"
		else
			icon_state = "baby metroid"

	canmove = 1
	anchored = 0

	if(M.health <= -70)
		M.canmove = 0
		if(!client)
			if(Victim && !rabid && !attacked)
				if(Victim.LAssailant && Victim.LAssailant != Victim)
					if(prob(50))
						Friends |= Victim.LAssailant

		if(M.client && istype(src, /mob/living/carbon/human))
			if(prob(85))
				rabid = 1 // UUUNNBGHHHH GONNA EAT JUUUUUU

		if(client) src << "<i>This subject does not have a strong enough life energy anymore...</i>"
	else
		M.canmove = 1

		if(client) to_chat(src, "<i>I have stopped feeding...</i>")

	Victim = null

/mob/living/carbon/metroid/proc/Feedstop()
	if(Victim)
		if(Victim.client)
			to_chat(Victim, "[src] has let go of your head!")
		Victim = null

/mob/living/carbon/metroid/proc/UpdateFeed(var/mob/M)
	if(Victim)
		if(Victim == M)
			loc = M.loc // simple "attach to head" effect!


/mob/living/carbon/metroid/verb/Evolve()
	set category = "Metroid"
	set desc = "This will let you evolve from baby to adult metroid."

	if(stat)
		to_chat(src, "<i>I must be conscious to do this...</i>")
		return
	if(!istype(src, /mob/living/carbon/metroid/adult))
		if(amount_grown >= 10)
			var/mob/living/carbon/metroid/adult/new_metroid = new /mob/living/carbon/metroid/adult (loc)
			new_metroid.mind_initialize(src)
			if(src.mind)
				src.mind.transfer_to(new_metroid)
			else
				new_metroid.key = src.key
			new_metroid.nutrition = nutrition
			new_metroid.powerlevel = max(0, powerlevel-1)
			attack_log += text("\[[time_stamp()]\] <font color='black'>Evolved to an adult metroid at x=[x],y=[y],z=[z]!</font>")
			new_metroid.a_intent = I_HURT
			new_metroid.languages = languages.Copy()
			new_metroid.name = src.name
			new_metroid.real_name = src.real_name
			new_metroid.attack_log = attack_log
			transferImplantsTo(new_metroid)
			transferBorers(new_metroid)

			to_chat(new_metroid, "<B>You are now an adult Metroid.</B>")
			qdel(src)
		else
			to_chat(src, "<i>I am not ready to evolve yet...</i>")
	else
		to_chat(src, "<i>I have already evolved...</i>")

/mob/living/carbon/metroid/verb/Reproduce()
	set category = "Metroid"
	set desc = "This will make you split into a random number of Metroids (usually 2). NOTE: this will KILL you, but you will be transferred into one of the babies."

	if(stat)
		to_chat(src, "<i>I must be conscious to do this...</i>")
		return

	if(istype(src, /mob/living/carbon/metroid/adult))
		if(amount_grown >= 10)
			switch(input("Are you absolutely sure you want to reproduce? Your current body will cease to be, but your consciousness will be transferred into a produced metroid.") in list("Yes","No"))
				if("Yes")

					if(stat)
						to_chat(src, "<i>I must be conscious to do this...</i>")
						return

					var/number = pick(2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,4)
					var/list/babies = list()
					for(var/i=1,i<=number,i++) // reproduce (has a small chance of producing 3 or 4 offspring)
						var/mob/living/carbon/metroid/M = new/mob/living/carbon/metroid(loc)
						M.nutrition = round(nutrition/number)
						M.powerlevel = round(powerlevel / number)
						if(i != 1) step_away(M,src)
						babies += M


					var/mob/living/carbon/metroid/new_metroid = pick(babies)

					new_metroid.mind_initialize(src)

					new_metroid.languages = languages.Copy()
					new_metroid.name = src.name
					attack_log += text("\[[time_stamp()]\] <font color='black'>Reproduced to make more metroids at x=[x],y=[y],z=[z]!</font>")
					new_metroid.real_name = src.real_name
					new_metroid.attack_log = attack_log
					if(src.mind)
						src.mind.transfer_to(new_metroid)
					else
						new_metroid.key = src.key
					transferImplantsTo(new_metroid)
					transferBorers(new_metroid)
					to_chat(new_metroid, "<B>You are now a baby Metroid.</B>")
					qdel(src)
		else
			to_chat(src, "<i>I am not ready to reproduce yet...</i>")
	else
		to_chat(src, "<i>I am not old enough to reproduce yet...</i>")

/mob/living/carbon/metroid/verb/ventcrawl()
	set name = "Crawl through Vent"
	set desc = "Enter an air vent and crawl through the pipe system."
	set category = "Object"
	if(Victim)
		return

	if(istype(src, /mob/living/carbon/metroid/adult))
		to_chat(src, "<i>I am much too big to fit in this small vent...</i>")
		return

	var/pipe = start_ventcrawl()
	if(pipe && !Victim)
		handle_ventcrawl(pipe)


