//Refer to life.dm for caller

/mob/living/carbon/human/proc/handle_disabilities()
	if(disabilities & EPILEPSY)
		if((prob(1)) && (paralysis < 1))
			visible_message("<span class='danger'>\The [src] starts having a seizure!</span>", \
							"<span class='warning'>You have a seizure!</span>")
			Paralyse(10)
			Jitter(1000) //Godness

	//If we have the gene for being crazy, have random events.
	if(dna.GetSEState(HALLUCINATIONBLOCK))
		if(prob(1) && hallucination < 1)
			hallucination += 20

	if(disabilities & COUGHING)
		if((prob(5) && paralysis <= 1))
			drop_item()
			audible_cough(src)
	if(disabilities & TOURETTES)
		if((prob(10) && paralysis <= 1))
			//Stun(10)
			switch(rand(1, 3))
				if(1)
					emote("twitch")
				if(2 to 3)
					say("[prob(50) ? ";" : ""][pick("SHIT", "PISS", "FUCK", "CUNT", "COCKSUCKER", "MOTHERFUCKER", "TITS")]")

			var/x_offset_change = rand(-2,2) * PIXEL_MULTIPLIER
			var/y_offset_change = rand(-1,1) * PIXEL_MULTIPLIER

			animate(src, pixel_x = (pixel_x + x_offset_change), pixel_y = (pixel_y + y_offset_change), time = 1)
			animate(pixel_x = (pixel_x - x_offset_change), pixel_y = (pixel_y - y_offset_change), time = 1)

	if(getBrainLoss() >= 60 && stat != DEAD)
		if(prob(3))
			switch(pick(1,2,3)) //All of those REALLY ought to be variable lists, but that would be too smart I guess
				if(1)
					say(sanitize(pick("Òâàþ ìàìó èáàë!", \
					"ß íå ñìàëãåé!", \
					"ÕÎÑ ÕÓÅÑÎÑ!", "[pick("", "åáó÷èé òðåéòîð")] [pick("ìîðãàí", "ìîðãóí", "ìîðãåí", "ìðîãóí")] [pick("äæåìåñ", "äæàìåñ", "äæàåìåñ")] ãðåôîíåò ìèíÿ øïàñèò;å!!!", \
					"òè ìîæûø äàòü ìíå [pick("òèëèïàòèþ","õàëêó","ýïèëëåïñèþ")]?", \
					"ÕÀ÷ó ñòàòü áîðãîì!", "ÏÎÇÎâèòå äåòåêòèâà!",  \
					"Õî÷ó ñòàòü ìàðòûøêîé!", "ÕÂÀÒÅÒ ÃÐÈÔÎÍÅÒÜ ÌÈÍß!!!!", \
					"ØÒÀÏ!")))
				if(2)
					say(sanitize(pick("Êàê ìèíÿòü ðóêè?", \
						"åáó÷èå ôóððè!", \
						"Ïîäåáèë", \
						"Ïðîêëÿòûå òðàïû!", \
						"Ýòà æè ãðèí!", \
						"âæææææææææóõ!!!", \
						"äæåô ñêâààààä!", \
						"ÁÐÀÍÄÅÍÁÓÐÃ!", \
						"ÁÓÄÀÏÅØÒ!", \
						"ÏÀÓÓÓÓÓÊ!!!!", \
						"ÏÓÊÀÍ ÁÎÌÁÀÍÓË!", \
						"êëÿòûå øåïàðäèñòû", \
						"ÏÓØÊÀ", \
						"ÐÅÂÀ ÏÎÖÎÍÛ", \
						"Ïàòè íà õîïà!", \
						"Êó, ÿ îò ñòðèììåðà, ãî â ñêóï!!!", \
						"Ñâàáîäíûé àñèñòåíò", \
						"Ïàçàâèòè èæèíèðîâ, ÿ âåñòü ãîðþ!!!", \
						"ÄÀ ÒÛ ÆÅ ÓÏÎÐÒÛÉ, ÑÓÊÀ!!", \
						"ÕÎÑ ÕÓÅÑÎÑ!", \
						"×èêè-áðèêè è â äàìêè!", \
						"ÂÈÇÛÂÀÞ ÙÈÒØÒÎÐÌ ÍÀ ÑÅÁß!", \
						"ÍÀÐÅÊÀÞ ÒÅÁß ÊÀËÎÂÐÀÒÎÌ!!!", \
						"ÈÄÈ ÏÈØÈ Â ÔÎÐÍÓÐÈÇÎÍ, ÃÐÈÔÅÐÎÊ ÊÎÌÍÀÒÍÛÉ!", \
						"ÄÀ ÒÛ ÍÀÐÛÂÀÅØÜÑß, ÑÓÊÀ!!", \
						"ß ÒÅÁß Â ÆÎÏÅ ÙÀ ÇÀÊÀÏÀÞ", \
						"ÄÀ ÁËß, ß ÂÈÇÀÐÄ!!! ÂÑÅ ÂÛ ÌÎÈ ÐÀÁÛ!!!", \
						"×î òàêîå ïèíïàèíòåð???", \
						"ÒÛ ×Î, ÍÀÂÀËÜÍÛÉ ÄÎÕÓß???")))
				if(3)
					emote("drool")

	if(species.name == "Tajaran")
		if(prob(1)) //Was 3
			vomit(1) //Hairball

	if(stat != DEAD)
		var/rn = rand(0, 200) //This is fucking retarded, but I'm only doing sanitization, I don't have three months to spare to fix everything
		if(getBrainLoss() >= 5)
			if(0 <= rn && rn <= 3)
				custom_pain("Your head feels numb and painful.")
		if(getBrainLoss() >= 15)
			if(4 <= rn && rn <= 6)
				if(eye_blurry <= 0)
					to_chat(src, "<span class='warning'>It becomes hard to see for some reason.</span>")
					eye_blurry = 10
		if(getBrainLoss() >= 35)
			if(7 <= rn && rn <= 9)
				if(get_active_hand())
					to_chat(src, "<span class='warning'>Your hand won't respond properly, you drop what you're holding.</span>")
					drop_item()
		if(getBrainLoss() >= 50)
			if(10 <= rn && rn <= 12)
				if(canmove)
					to_chat(src, "<span class='warning'>Your legs won't respond properly, you fall down.</span>")
					Knockdown(3)
