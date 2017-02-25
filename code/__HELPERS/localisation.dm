#define SANITIZE_BROWSER 1
#define SANITIZE_LOG 2
#define SANITIZE_TEMP 3


/*
	The most used output way is text chat. So fatal letters by default should be transformed into chat version.
	Also, it`s easier to fix all browser() calls than search all possible "[src|usr|mob|any other var] <<" calls.
	Logs need a special letter, because watch normal text with ascii code insertions is weird.
	And sometimes we need special unique temp letter for input windows whitch allows to edit text.
	Like in custom event message, admin memo and VV.
*/

/datum/letter
	var/letter = ""			//weird letter
	var/browser = ""		//letter in browser windows
	var/log = ""			//letter for logs
	var/temp = ""			//temporatory letter for filled input windows
							//!!!temp must be unique for every letter!!!

	cyrillic_ya
		letter = "ÿ"
		browser = "&#1103;"
		log = "ß"
		temp = "¶"

proc/sanitize_local(var/text, var/mode = SANITIZE_BROWSER)
	if(!istext(text))
		return text
	for(var/datum/letter/L in localisation)
		switch(mode)
			if(SANITIZE_BROWSER)	//browser takes everything
				text = replace_characters(text, list(L.letter=L.browser, L.temp=L.browser))

			if(SANITIZE_LOG)		//logs can get raw or prepared text
				text = replace_characters(text, list(L.letter=L.log))

			if(SANITIZE_TEMP)		//same for input windows
				text = replace_characters(text, list(L.letter=L.temp))
	return text

/proc/rhtml_encode(var/msg, var/html = 0)
	text = sanitize_local(text, SANITIZE_TEMP)
	text = html_encode(text)
	text = sanitize_local(text)
	return text

/proc/rhtml_decode(var/msg, var/html = 0)
	text = sanitize_local(text, SANITIZE_TEMP)
	text = html_decode(text)
	text = sanitize_local(text)
	return text