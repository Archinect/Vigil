/proc/_determine_encoding(var/mob_or_client)
	. = "1251"
	if (isclient(mob_or_client))
		var/client/C = mob_or_client
		. = C.encoding

	else if (ismob(mob_or_client))
		var/mob/M = mob_or_client
		if (M.client)
			. = M.client.encoding

// Converts a byte string to a UTF-8 string, sanitizes it and caps the length.
/proc/utf8_sanitize(var/message)
	return sanitize(message)

/proc/utf8_uppercase(var/text)
	text = uppertext(text)
	var/t = ""
	for(var/i = 1, i <= length(text), i++)
		var/a = text2ascii(text, i)
		if (a > 223)
			t += ascii2text(a - 32)
		else if (a == 184)
			t += ascii2text(168)
		else t += ascii2text(a)
	t = replacetext(t,"&#255;","ß")
	return t

/proc/utf8_lowercase(var/text)
	text = lowertext(text)
	var/t = ""
	for(var/i = 1, i <= length(text), i++)
		var/a = text2ascii(text, i)
		if (a > 191 && a < 224)
			t += ascii2text(a + 32)
		else if (a == 168)
			t += ascii2text(184)
		else t += ascii2text(a)
	return t

// Stricts non-ASCII characters.
// Useful for things which BYOND touches itself like object names.

/proc/utf8_capitalize(var/t as text)
	var/s = 2
	if (copytext(t,1,2) == ";")
		s += 1
	else if (copytext(t,1,2) == ":")
		s += 2
	return uppertext_alt(copytext(t, 1, s)) + copytext(t, s)

