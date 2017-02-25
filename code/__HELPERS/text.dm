/*
 * Holds procs designed to help with filtering text
 * Contains groups:
 *			SQL sanitization/formating
 *			Text sanitization
 *			Text searches
 *			Text modification
 *			Misc
 */


/*
 * SQL sanitization
 */
#define HTMLTAB "&nbsp;&nbsp;&nbsp;&nbsp;"
// Run all strings to be used in an SQL query through this proc first to properly escape out injection attempts.
/proc/sanitizeSQL(t as text)
	var/sqltext = dbcon.Quote(t);
	return copytext(sqltext, 2, lentext(sqltext));//Quote() adds quotes around input, we already do that

/*
 * Text sanitization
 */

//Simply removes < and > and limits the length of the message
/proc/strip_html_simple(t,limit=MAX_MESSAGE_LEN)
	var/list/strip_chars = list("<",">")
	t = copytext(t,1,limit)
	for(var/char in strip_chars)
		var/index = findtext(t, char)
		while(index)
			t = copytext(t, 1, index) + copytext(t, index+1)
			index = findtext(t, char)
	return t

//Removes a few problematic characters
/proc/sanitize_simple(var/t,var/list/repl_chars = list("\n"="#", "\t"="#", "ÿ"="&#1103;"))
	for(var/char in repl_chars)
		var/index = findtext(t, char)
		while(index)
			t = copytext(t, 1, index) + repl_chars[char] + copytext(t, index+1)
			index = findtext(t, char, index+1)
	return t

proc/sanitize_russian(var/msg, var/html = 0)
    var/rep
    if(html)
        rep = "&#1103;"
    else
        rep = "&#255;"
    var/index = findtext(msg, "ÿ")
    while(index)
        msg = copytext(msg, 1, index) + rep + copytext(msg, index + 1)
        index = findtext(msg, "ÿ")
    return msg

proc/russian_html2text(msg)
    return replacetext(msg, "&#1103;", "&#255;")

proc/russian_text2html(msg)
	return replacetext(msg, "&#255;", "&#1103;")

//Runs byond's sanitization proc along-side sanitize_simple
/proc/sanitize(var/t,var/list/repl_chars = null)
	t = replacetext(t, "\proper", "")
	t = replacetext(t, "\improper", "")
	return rhtml_encode(sanitize_simple(t,repl_chars))

//Runs sanitize and strip_html_simple
//I believe strip_html_simple() is required to run first to prevent '<' from displaying as '&lt;' after sanitize() calls byond's rhtml_encode()
/proc/strip_html(var/t,var/limit=MAX_MESSAGE_LEN)
	return copytext((sanitize(strip_html_simple(t))),1,limit)

//Runs byond's sanitization proc along-side strip_html_simple
//I believe strip_html_simple() is required to run first to prevent '<' from displaying as '&lt;' that rhtml_encode() would cause
/proc/adminscrub(var/t,var/limit=MAX_MESSAGE_LEN)
	return copytext((sanitize(strip_html_simple(t))),1,limit)


//Returns null if there is any bad text in the string
/proc/reject_bad_text(var/text, var/max_length=512)
	if(length(text) > max_length)	return			//message too long
	var/non_whitespace = 0
	for(var/i=1, i<=length(text), i++)
		switch(text2ascii(text,i))
			if(62,60,92,47)	return			//rejects the text if it contains these bad characters: <, >, \ or /
	//		if(127 to 255)	return			//rejects weird letters like i??
			if(0 to 31)		return			//more weird stuff
			if(32)			continue		//whitespace
			else			non_whitespace = 1
	if(non_whitespace)		return sanitize_russian(text)		//only accepts the text if it has some non-spaces

// Used to get a sanitized input.
/proc/stripped_input(var/mob/user, var/message = "", var/title = "", var/default = "", var/max_length=MAX_MESSAGE_LEN)
	var/name = sanitize(input(user, message, title, default))
	return strip_html_simple(name, max_length)


// Used to get a properly sanitized multiline input, of max_length
/proc/stripped_multiline_input(mob/user, message = "", title = "", default = "", max_length=MAX_MESSAGE_LEN)
	var/name = input(user, message, title, default) as message|null
	name = trim(name, max_length)
	return rhtml_encode(name, 1)

/proc/format_num(var/number, var/sep=",")
	var/c="" // Current char
	var/list/parts = splittext("[number]",".")
	var/origtext = "[parts[1]]"
	var/len      = length(origtext)
	var/offset   = len % 3
	for(var/i=1;i<=len;i++)
		c = copytext(origtext,i,i+1)
		. += c
		if((i%3)==offset && i!=len)
			. += sep
	if(parts.len==2)
		. += ".[parts[2]]"

//Filters out undesirable characters from names
/proc/reject_bad_name(t_in, allow_numbers=0, max_length=MAX_NAME_LEN)
	if(!t_in || length(t_in) > max_length)
		return //Rejects the input if it is null or if it is longer then the max length allowed

	var/number_of_alphanumeric	= 0
	var/last_char_group			= 0
	var/t_out = ""

	for(var/i=1, i<=length(t_in), i++)
		var/ascii_char = text2ascii(t_in,i)
		switch(ascii_char)
			// A  .. Z
			if(65 to 90)			//Uppercase Letters
				t_out += ascii2text(ascii_char)
				number_of_alphanumeric++
				last_char_group = 4

			// a  .. z
			if(97 to 122)			//Lowercase Letters
				if(last_char_group<2)
					t_out += ascii2text(ascii_char-32)	//Force uppercase first character
				else
					t_out += ascii2text(ascii_char)
				number_of_alphanumeric++
				last_char_group = 4

			// 0  .. 9
			if(48 to 57)			//Numbers
				if(!last_char_group)
					continue	//suppress at start of string
				if(!allow_numbers)
					continue
				t_out += ascii2text(ascii_char)
				number_of_alphanumeric++
				last_char_group = 3

			// '  -  .
			if(39,45,46)			//Common name punctuation
				if(!last_char_group)
					continue
				t_out += ascii2text(ascii_char)
				last_char_group = 2

			// ~   |   @  :  #  $  %  &  *  +
			if(126,124,64,58,35,36,37,38,42,43)			//Other symbols that we'll allow (mainly for AI)
				if(!last_char_group)
					continue	//suppress at start of string
				if(!allow_numbers)
					continue
				t_out += ascii2text(ascii_char)
				last_char_group = 2

			//Space
			if(32)
				if(last_char_group <= 1)
					continue	//suppress double-spaces and spaces at start of string
				t_out += ascii2text(ascii_char)
				last_char_group = 1
			else
				return

	if(number_of_alphanumeric < 2)
		return		//protects against tiny names like "A" and also names like "' ' ' ' ' ' ' '"

	if(last_char_group == 1)
		t_out = copytext(t_out,1,length(t_out))	//removes the last character (in this case a space)

	for(var/bad_name in list("space","floor","wall","r-wall","monkey","unknown","inactive ai"))	//prevents these common metagamey names
		if(cmptext(t_out,bad_name))
			return	//(not case sensitive)

	return t_out

//rhtml_encode helper proc that returns the smallest non null of two numbers
//or 0 if they're both null (needed because of findtext returning 0 when a value is not present)
/proc/non_zero_min(a, b)
	if(!a)
		return b
	if(!b)
		return a
	return (a < b ? a : b)

//this proc strips html properly, but it's not lazy like the other procs.
//this means that it doesn't just remove < and > and call it a day. seriously, who the fuck thought that would be useful.
//also limit the size of the input, if specified to
/proc/strip_html_properly(var/input,var/max_length=MAX_MESSAGE_LEN)
	if(!input)
		return
	var/opentag = 1
	var/closetag = 1
	while(1)
		opentag = findtext(input, "<", opentag) //These store the position of < and > respectively.
		if(opentag)
			closetag = findtext(input, ">", opentag)
			if(closetag)
				input = copytext(input, 1, opentag) + copytext(input, closetag + 1)
			else
				break
		else
			break
	if(max_length)
		input = copytext(input,1,max_length)
	return input
/*
/mob/verb/test_strip_html_properly()
	ASSERT(strip_html_properly("I love <html>html. It's so amazing!") == "I love html. It's so amazing!")
	ASSERT(strip_html_properly(">here is cool text< yo") == ">here is cool text< yo")
	ASSERT(strip_html_properly("A<F>W<U>E<C>S<K>O<O>M<F>E<F>") == "AWESOME")
	ASSERT(strip_html_properly("A>B>C>D>E>F>G") =="A>B>C>D>E>F>G")
	ASSERT(strip_html_properly("G<F<E<D<C<B<A") == "G<F<E<D<C<B<A")
	world.log << "test finished"
*/
/*
 * Text searches
 */

//Checks the beginning of a string for a specified sub-string
//Returns the position of the substring or 0 if it was not found
/proc/dd_hasprefix(text, prefix)
	var/start = 1
	var/end = length(prefix) + 1
	return findtext(text, prefix, start, end)

//Checks the beginning of a string for a specified sub-string. This proc is case sensitive
//Returns the position of the substring or 0 if it was not found
/proc/dd_hasprefix_case(text, prefix)
	var/start = 1
	var/end = length(prefix) + 1
	return findtextEx(text, prefix, start, end)

//Checks the end of a string for a specified substring.
//Returns the position of the substring or 0 if it was not found
/proc/dd_hassuffix(text, suffix)
	var/start = length(text) - length(suffix)
	if(start)
		return findtext(text, suffix, start, null)
	return

//Checks the end of a string for a specified substring. This proc is case sensitive
//Returns the position of the substring or 0 if it was not found
/proc/dd_hassuffix_case(text, suffix)
	var/start = length(text) - length(suffix)
	if(start)
		return findtextEx(text, suffix, start, null)

//Checks if any of a given list of needles is in the haystack
/proc/text_in_list(haystack, list/needle_list, start=1, end=0)
	for(var/needle in needle_list)
		if(findtext(haystack, needle, start, end))
			return 1
	return 0

//Like above, but case sensitive
/proc/text_in_list_case(haystack, list/needle_list, start=1, end=0)
	for(var/needle in needle_list)
		if(findtextEx(haystack, needle, start, end))
			return 1
	return 0

//Adds 'u' number of zeros ahead of the text 't'
/proc/add_zero(t, u)
	while (length(t) < u)
		t = "0[t]"
	return t

//Adds 'u' number of spaces ahead of the text 't'
/proc/add_lspace(t, u)
	while(length(t) < u)
		t = " [t]"
	return t

//Adds 'u' number of spaces behind the text 't'
/proc/add_tspace(t, u)
	while(length(t) < u)
		t = "[t] "
	return t

//Returns a string with reserved characters and spaces before the first letter removed
/proc/trim_left(text)
	for (var/i = 1 to length(text))
		if (text2ascii(text, i) > 32)
			return copytext(text, i)
	return ""

/proc/uppertext_alt(var/text)
	var/lenght = length(text)
	var/new_text = null
	var/ucase_letter
	var/letter_ascii

	var/p = 1
	while(p <= lenght)
		ucase_letter = copytext(text, p, p + 1)
		letter_ascii = text2ascii(ucase_letter)

		if((letter_ascii >= 97 && letter_ascii <= 122) || (letter_ascii >= 224 && letter_ascii < 255))
			ucase_letter = ascii2text(letter_ascii - 32)
		else if(letter_ascii == text2ascii("¶"))
			ucase_letter = "ß"

		new_text += ucase_letter
		p++

	return new_text

/proc/lowertext_alt(var/text)
	var/lenght = length(text)
	var/new_text = null
	var/lcase_letter
	var/letter_ascii

	var/p = 1
	while(p <= lenght)
		lcase_letter = copytext(text, p, p + 1)
		letter_ascii = text2ascii(lcase_letter)

		if((letter_ascii >= 65 && letter_ascii <= 90) || (letter_ascii >= 192 && letter_ascii < 223))
			lcase_letter = ascii2text(letter_ascii + 32)
		else if(letter_ascii == 223)
			lcase_letter = "¶"

		new_text += lcase_letter
		p++

	return new_text

//Returns a string with reserved characters and spaces after the last letter removed
/proc/trim_right(text)
	for (var/i = length(text), i > 0, i--)
		if (text2ascii(text, i) > 32)
			return copytext(text, 1, i + 1)

	return ""

//Returns a string with reserved characters and spaces before the first word and after the last word removed.
/proc/trim(text, max_length)
	if(max_length)
		text = copytext(text, 1, max_length)
	return trim_left(trim_right(text))

//Returns a string with the first element of the string capitalized.
/proc/capitalize(t as text)
	return uppertext_alt(copytext(t, 1, 2)) + copytext(t, 2)

//Centers text by adding spaces to either side of the string.
/proc/dd_centertext(message, length)
	var/new_message = message
	var/size = length(message)
	var/delta = length - size
	if(size == length)
		return new_message
	if(size > length)
		return copytext(new_message, 1, length + 1)
	if(delta == 1)
		return new_message + " "
	if(delta % 2)
		new_message = " " + new_message
		delta--
	var/spaces = add_lspace("",delta/2-1)
	return spaces + new_message + spaces

//Limits the length of the text. Note: MAX_MESSAGE_LEN and MAX_NAME_LEN are widely used for this purpose
/proc/dd_limittext(message, length)
	var/size = length(message)
	if(size <= length)
		return message
	return copytext(message, 1, length + 1)

/*
 * Misc
 */

/proc/stringsplit(txt, character)
	var/cur_text = txt
	var/last_found = 1
	var/found_char = findtext(cur_text,character)
	var/list/list = list()
	if(found_char)
		var/fs = copytext(cur_text,last_found,found_char)
		list += fs
		last_found = found_char+length(character)
		found_char = findtext(cur_text,character,last_found)
	while(found_char)
		var/found_string = copytext(cur_text,last_found,found_char)
		last_found = found_char+length(character)
		list += found_string
		found_char = findtext(cur_text,character,last_found)
	list += copytext(cur_text,last_found,length(cur_text)+1)
	return list

/proc/rfindtext(Haystack, Needle, Start = 1, End = 0)
	var/i = findtext(Haystack, Needle, Start, End)

	while (i)
		. = i
		i = findtext(Haystack, Needle, i + 1, End)

/proc/stringmerge(text,compare,replace = "*")
//This proc fills in all spaces with the "replace" var (* by default) with whatever
//is in the other string at the same spot (assuming it is not a replace char).
//This is used for fingerprints
	var/newtext = text
	if(lentext(text) != lentext(compare))
		return 0
	for(var/i = 1, i < lentext(text), i++)
		var/a = copytext(text,i,i+1)
		var/b = copytext(compare,i,i+1)
//if it isn't both the same letter, or if they are both the replacement character
//(no way to know what it was supposed to be)
		if(a != b)
			if(a == replace) //if A is the replacement char
				newtext = copytext(newtext,1,i) + b + copytext(newtext, i+1)
			else if(b == replace) //if B is the replacement char
				newtext = copytext(newtext,1,i) + a + copytext(newtext, i+1)
			else //The lists disagree, Uh-oh!
				return 0
	return newtext

/proc/stringpercent(text,character = "*")
//This proc returns the number of chars of the string that is the character
//This is used for detective work to determine fingerprint completion.
	if(!text || !character)
		return 0
	var/count = 0
	for(var/i = 1, i <= lentext(text), i++)
		var/a = copytext(text,i,i+1)
		if(a == character)
			count++
	return count

/proc/text_ends_with(text, suffix)
	if(length(suffix) > length(text))
		return FALSE

	return (copytext(text, length(text) - length(suffix) + 1) == suffix)

/proc/reverse_text(text = "")
	var/new_text = ""
	for(var/i = length(text); i > 0; i--)
		new_text += copytext(text, i, i+1)
	return new_text

/proc/dd_splittext(text, separator, var/list/withinList)
	var/textlength = length(text)
	var/separatorlength = length(separator)
	if(withinList && !withinList.len) withinList = null
	var/list/textList = new()
	var/searchPosition = 1
	var/findPosition = 1
	var/loops = 0
	while(1)
		if(loops >= 1000)
			break
		loops++

		findPosition = findtext(text, separator, searchPosition, 0)
		var/buggyText = copytext(text, searchPosition, findPosition)
		if(!withinList || (buggyText in withinList)) textList += "[buggyText]"
		if(!findPosition) return textList
		searchPosition = findPosition + separatorlength
		if(searchPosition > textlength)
			textList += ""
			return textList
	return


var/list/zero_character_only = list("0")
var/list/hex_characters = list("0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f")
var/list/alphabet = list("a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z")
var/list/binary = list("0","1")
/proc/random_string(length, list/characters)
	. = ""
	for(var/i=1, i<=length, i++)
		. += pick(characters)

/proc/repeat_string(times, string="")
	. = ""
	for(var/i=1, i<=times, i++)
		. += string



/proc/random_short_color()
	return random_string(3, hex_characters)

/proc/random_color()
	return random_string(6, hex_characters)

/proc/add_zero2(t, u)
	var/temp1
	while (length(t) < u)
		t = "0[t]"
	temp1 = t
	if (length(t) > u)
		temp1 = copytext(t,2,u+1)
	return temp1

/proc/num2words(var/number, var/zero="zero", var/minus="minus", var/hundred="hundred", var/list/digits=number_digits, var/list/tens=number_tens, var/list/units=number_units, var/recursion=0)
	if(!isnum(number))
		warning("num2words fed a non-number: [number]")
		return list()
	number=round(number)
	//testing("num2words [recursion] ([number])")
	if(number == 0)
		return list(zero)

	if(number < 0)
		return list(minus) + num2words(abs(number), zero, minus, hundred, digits, tens, units, recursion+1)

	var/list/out=list()
	if(number < 1000)
		var/hundreds = round(number/100)
		//testing(" ([recursion]) hundreds=[hundreds]")
		if(hundreds)
			out += num2words(hundreds, zero, minus, hundred, digits, tens, units, recursion+1) + list(hundred)
			number %= 100

	if(number < 100)
		// Teens
		if(number <= 19)
			out.Add(digits[number])
		else
			var/tens_place = tens[round(number/10)+1]
			//testing(" ([recursion]) tens_place=[round(number/10)+1] = [tens_place]")
			if(tens_place!=null)
				out.Add(tens_place)
			number = number%10
			//testing(" ([recursion]) number%10+1 = [number+1] = [digits[number+1]]")
			if(number>0)
				out.Add(digits[number])
	else
		var/i=1
		while(round(number) > 0)
			var/unit_number = number%1000
			//testing(" ([recursion]) [number]%1000 = [unit_number] ([i])")
			if(unit_number > 0)
				if(units[i])
					//testing(" ([recursion]) units = [units[i]]")
					out = list(units[i]) + out
				out = num2words(unit_number, zero, minus, hundred, digits, tens, units, recursion+1) + out
			number /= 1000
			i++
	//testing(" ([recursion]) out=list("+jointext(out,", ")+")")
	return out

//merges non-null characters (3rd argument) from "from" into "into". Returns result
//e.g. into = "Hello World"
//     from = "Seeya______"
//     returns"Seeya World"
//The returned text is always the same length as into
//This was coded to handle DNA gene-splicing.
/proc/merge_text(into, from, null_char="_")
	. = ""
	if(!istext(into))
		into = ""
	if(!istext(from))
		from = ""
	var/null_ascii = istext(null_char) ? text2ascii(null_char,1) : null_char

	var/previous = 0
	var/start = 1
	var/end = length(into) + 1

	for(var/i=1, i<end, i++)
		var/ascii = text2ascii(from, i)
		if(ascii == null_ascii)
			if(previous != 1)
				. += copytext(from, start, i)
				start = i
				previous = 1
		else
			if(previous != 0)
				. += copytext(into, start, i)
				start = i
				previous = 0

	if(previous == 0)
		. += copytext(from, start, end)
	else
		. += copytext(into, start, end)



//finds the first occurrence of one of the characters from needles argument inside haystack
//it may appear this can be optimised, but it really can't. findtext() is so much faster than anything you can do in byondcode.
//stupid byond :(
/proc/findchar(haystack, needles, start=1, end=0)
	var/temp
	var/len = length(needles)
	for(var/i=1, i<=len, i++)
		temp = findtextEx(haystack, ascii2text(text2ascii(needles,i)), start, end)	//Note: ascii2text(text2ascii) is faster than copytext()
		if(temp)
			end = temp
	return end


/proc/parsepencode(t, mob/user=null, signfont=SIGNFONT)
	if(length(t) < 1)		//No input means nothing needs to be parsed
		return

	t = replacetext(t, "\[center\]", "<center>")
	t = replacetext(t, "\[/center\]", "</center>")
	t = replacetext(t, "\[br\]", "<BR>")
	t = replacetext(t, "\[b\]", "<B>")
	t = replacetext(t, "\[/b\]", "</B>")
	t = replacetext(t, "\[i\]", "<I>")
	t = replacetext(t, "\[/i\]", "</I>")
	t = replacetext(t, "\[u\]", "<U>")
	t = replacetext(t, "\[/u\]", "</U>")
	t = replacetext(t, "\[large\]", "<font size=\"4\">")
	t = replacetext(t, "\[/large\]", "</font>")
	if(user)
		t = replacetext(t, "\[sign\]", "<font face=\"[signfont]\"><i>[user.real_name]</i></font>")
	else
		t = replacetext(t, "\[sign\]", "")
	t = replacetext(t, "\[field\]", "<span class=\"paper_field\"></span>")

	t = replacetext(t, "\[*\]", "<li>")
	t = replacetext(t, "\[hr\]", "<HR>")
	t = replacetext(t, "\[small\]", "<font size = \"1\">")
	t = replacetext(t, "\[/small\]", "</font>")
	t = replacetext(t, "\[list\]", "<ul>")
	t = replacetext(t, "\[/list\]", "</ul>")

	return t


/proc/char_split(t)
	. = list()
	for(var/x in 1 to length(t))
		. += copytext(t,x,x+1)

//

var/global/list/watt_suffixes = list("W", "KW", "MW", "GW", "TW", "PW", "EW", "ZW", "YW")
/proc/format_watts(var/number)
	if(number<0)
		return "-[format_watts(number)]"
	if(number==0)
		return "0 W"

	var/i=1
	while (round(number/1000) >= 1)
		number/=1000
		i++
	return "[format_num(number)] [watt_suffixes[i]]"
var/list/number_digits=list(
	"one",
	"two",
	"three",
	"four",
	"five",
	"six",
	"seven",
	"eight",
	"nine",
	"ten",
	"eleven",
	"twelve",
	"thirteen",
	"fourteen",
	"fifteen",
	"sixteen",
	"seventeen",
	"eighteen",
	"nineteen",
)

var/list/number_tens=list(
	null, // 0 :V
	null, // teens, special case
	"twenty",
	"thirty",
	"forty",
	"fifty",
	"sixty",
	"seventy",
	"eighty",
	"ninety"
)

var/list/number_units=list(
	null, // Don't yell units
	"thousand",
	"million",
	"billion"
)

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
	text = rhtml_encode(text)
	text = sanitize_local(text)
	return text

/proc/rhtml_decode(var/msg, var/html = 0)
	text = sanitize_local(text, SANITIZE_TEMP)
	text = rhtml_decode(text)
	text = sanitize_local(text)
	return text


/proc/replace_characters(var/t,var/list/repl_chars)
	for(var/char in repl_chars)
		t = replacetext(t, char, repl_chars[char])
	return t

#define string2charlist(string) (splittext(string, regex("(.)")) - splittext(string, ""))

/proc/rot13(text = "")
	var/list/textlist = string2charlist(text)
	var/list/result = list()
	for(var/c in textlist)
		var/ca = text2ascii(c)
		if(ca >= text2ascii("a") && ca <= text2ascii("m"))
			ca += 13
		else if(ca >= text2ascii("n") && ca <= text2ascii("z"))
			ca -= 13
		else if(ca >= text2ascii("A") && ca <= text2ascii("M"))
			ca += 13
		else if(ca >= text2ascii("N") && ca <= text2ascii("Z"))
			ca -= 13
		result += ascii2text(ca)
	return jointext(result, "")

//Takes a list of values, sanitizes it down for readability and character count,
//then exports it as a json file at data/npc_saves/[filename].json.
//As far as SS13 is concerned this is write only data. You can't change something
//in the json file and have it be reflected in the in game item/mob it came from.
//(That's what things like savefiles are for) Note that this list is not shuffled.

