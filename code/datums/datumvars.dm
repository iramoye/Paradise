// reference: /client/proc/modify_variables(var/atom/O, var/param_var_name = null, var/autodetect_class = 0)

/**
  * Proc to check if a datum allows proc calls on it
  *
  * Returns TRUE if you can call a proc on the datum, FALSE if you cant
  *
  */
/datum/proc/CanProcCall(procname)
	return TRUE

/datum/proc/can_vv_get(var_name)
	return TRUE

/mob/can_vv_get(var_name)
	var/static/list/protected_vars = list(
		"lastKnownIP", "computer_id", "attack_log_old"
	)
	if(!check_rights(R_ADMIN, FALSE, usr) && (var_name in protected_vars))
		return FALSE
	return TRUE

/client/can_vv_get(var_name)
	var/static/list/protected_vars = list(
		"address", "computer_id", "connection", "jbh", "pm_tracker", "related_accounts_cid", "related_accounts_ip", "watchlisted"
	)
	if(!check_rights(R_ADMIN, FALSE, usr) && (var_name in protected_vars))
		return FALSE
	return TRUE

/datum/proc/vv_edit_var(var_name, var_value) //called whenever a var is edited
	switch(var_name)
		if("vars")
			return FALSE
		if("var_edited")
			return FALSE
	var_edited = TRUE
	vars[var_name] = var_value

	. = TRUE


/client/vv_edit_var(var_name, var_value) //called whenever a var is edited
	switch(var_name)
		// I know we will never be in a world where admins are editing client vars to let people bypass TOS
		// But guess what, if I have the ability to overengineer something, I am going to do it
		if("tos_consent")
			return FALSE
		// Dont fuck with this
		if("cui_entries")
			return FALSE
		// or this
		if("jbh")
			return FALSE
		if("vars")
			return FALSE
		if("var_edited")
			return FALSE
	var_edited = TRUE
	vars[var_name] = var_value

	. = TRUE

/datum/proc/vv_get_var(var_name)
	switch(var_name)
		if("attack_log_old", "debug_log")
			return debug_variable(var_name, vars[var_name], 0, src, sanitize = FALSE)
		if("vars")
			return debug_variable(var_name, list(), 0, src)
	return debug_variable(var_name, vars[var_name], 0, src)

/client/vv_get_var(var_name)
	switch(var_name)
		if("vars")
			return debug_variable(var_name, list(), 0, src)
	return debug_variable(var_name, vars[var_name], 0, src)

/datum/proc/can_vv_delete()
	return TRUE

//please call . = ..() first and append to the result, that way parent items are always at the top and child items are further down
//add seperaters by doing . += "---"
/datum/proc/vv_get_dropdown()
	. = list()
	. += "---"
	.["Call Proc"] = "byond://?_src_=vars;proc_call=[UID()]"
	.["Mark Object"] = "byond://?_src_=vars;mark_object=[UID()]"
	.["Jump to Object"] = "byond://?_src_=vars;jump_to=[UID()]"
	.["Delete"] = "byond://?_src_=vars;delete=[UID()]"
	.["Modify Traits"] = "byond://?_src_=vars;traitmod=[UID()]"
	.["Add Component/Element"] = "byond://?_src_=vars;addcomponent=[UID()]"
	.["Remove Component/Element"] = "byond://?_src_=vars;removecomponent=[UID()]"
	.["Mass Remove Component/Element"] = "byond://?_src_=vars;massremovecomponent=[UID()]"
	. += "---"

/client/vv_get_dropdown()
	. = list()
	.["Manipulate Colour Matrix"] = "byond://?_src_=vars;manipcolours=[UID()]"
	. += "---"
	.["Call Proc"] = "byond://?_src_=vars;proc_call=[UID()]"
	.["Mark Object"] = "byond://?_src_=vars;mark_object=[UID()]"
	.["Delete"] = "byond://?_src_=vars;delete=[UID()]"
	.["Modify Traits"] = "byond://?_src_=vars;traitmod=[UID()]"
	. += "---"

/client/proc/debug_variables(datum/D in world)
	set name = "\[Admin\] View Variables"

	var/static/cookieoffset = rand(1, 9999) //to force cookies to reset after the round.

	if(!check_rights(R_ADMIN|R_VIEWRUNTIMES))
		to_chat(usr, "<span class='warning'>You need to be an administrator to access this.</span>")
		return

	if(!D)
		return

	var/datum/asset/asset_cache_datum = get_asset_datum(/datum/asset/simple/vv)
	asset_cache_datum.send(usr)

	var/islist = islist(D)
	var/isclient = isclient(D)
	if(!islist && !isclient && !istype(D))
		return

	var/title = ""
	var/icon/sprite
	var/hash
	var/refid

	if(!islist)
		refid = "[D.UID()]"
	else
		refid = "\ref[D]"

	var/type = /list
	if(!islist)
		type = D.type

	if(isatom(D))
		var/atom/A = D
		if(A.icon && A.icon_state)
			sprite = new /icon(A.icon, A.icon_state)
			hash = md5(A.icon)
			hash = md5(hash + A.icon_state)
			usr << browse_rsc(sprite, "vv[hash].png")


	var/sprite_text
	if(sprite)
		sprite_text = "<img src='vv[hash].png'></td><td>"


	var/list/atomsnowflake = list()
	if(isatom(D))
		var/atom/A = D
		if(isliving(A))
			var/mob/living/L = A
			atomsnowflake += "<a href='byond://?_src_=vars;rename=[L.UID()]'><b>[L]</b></a>"
			if(L.dir)
				atomsnowflake += "<br><font size='1'><a href='byond://?_src_=vars;rotatedatum=[L.UID()];rotatedir=left'><<</a> <a href='byond://?_src_=vars;datumedit=[L.UID()];varnameedit=dir'>[dir2text(L.dir)]</a> <a href='byond://?_src_=vars;rotatedatum=[L.UID()];rotatedir=right'>>></a></font>"
			atomsnowflake += {"
				<br><font size='1'><a href='byond://?_src_=vars;datumedit=[L.UID()];varnameedit=ckey'>[L.ckey ? L.ckey : "No ckey"]</a> / <a href='byond://?_src_=vars;datumedit=[L.UID()];varnameedit=real_name'>[L.real_name ? L.real_name : "No real name"]</a></font>
				<br><font size='1'>
					BRUTE:<font size='1'><a href='byond://?_src_=vars;mobToDamage=[L.UID()];adjustDamage=brute'>[L.getBruteLoss()]</a>
					FIRE:<font size='1'><a href='byond://?_src_=vars;mobToDamage=[L.UID()];adjustDamage=fire'>[L.getFireLoss()]</a>
					TOXIN:<font size='1'><a href='byond://?_src_=vars;mobToDamage=[L.UID()];adjustDamage=toxin'>[L.getToxLoss()]</a>
					OXY:<font size='1'><a href='byond://?_src_=vars;mobToDamage=[L.UID()];adjustDamage=oxygen'>[L.getOxyLoss()]</a>
					CLONE:<font size='1'><a href='byond://?_src_=vars;mobToDamage=[L.UID()];adjustDamage=clone'>[L.getCloneLoss()]</a>
					BRAIN:<font size='1'><a href='byond://?_src_=vars;mobToDamage=[L.UID()];adjustDamage=brain'>[L.getBrainLoss()]</a>
					STAMINA:<font size='1'><a href='byond://?_src_=vars;mobToDamage=[L.UID()];adjustDamage=stamina'>[L.getStaminaLoss()]</a>
				</font>
			"}
		else
			atomsnowflake += "<a href='byond://?_src_=vars;datumedit=[A.UID()];varnameedit=name'><b>[A]</b></a>"
			if(A.dir)
				atomsnowflake += "<br><font size='1'><a href='byond://?_src_=vars;rotatedatum=[A.UID()];rotatedir=left'><<</a> <a href='byond://?_src_=vars;datumedit=[A.UID()];varnameedit=dir'>[dir2text(A.dir)]</a> <a href='byond://?_src_=vars;rotatedatum=[D.UID()];rotatedir=right'>>></a></font>"
	else
		atomsnowflake += "<b>[D]</b>"


	var/formatted_type = "[type]"
	if(length(formatted_type) > 25)
		var/middle_point = length(formatted_type) / 2
		var/splitpoint = findtext(formatted_type, "/", middle_point)
		if(splitpoint)
			formatted_type = "[copytext(formatted_type, 1, splitpoint)]<br>[copytext(formatted_type, splitpoint)]"
		else
			formatted_type = "Type too long" //No suitable splitpoint (/) found.


	var/marked
	if(holder.marked_datum && holder.marked_datum == D)
		marked = "<br><font size='1' color='red'><b>Marked Object</b></font>"


	var/varedited_line = ""
	if(isatom(D))
		var/atom/A = D
		if(A.admin_spawned)
			varedited_line += "<br><font size='1' color='red'><b>Admin Spawned</b></font>"


	if(!islist && D.var_edited)
		varedited_line += "<br><font size='1' color='red'><b>Var Edited</b></font>"


	var/dropdownoptions = list()
	if(islist)
		dropdownoptions = list(
			"---",
			"Add Item" = "byond://?_src_=vars;listadd=[refid]",
			"Remove Nulls" = "byond://?_src_=vars;listnulls=[refid]",
			"Remove Dupes" = "byond://?_src_=vars;listdupes=[refid]",
			"Set len" = "byond://?_src_=vars;listlen=[refid]",
			"Shuffle" = "byond://?_src_=vars;listshuffle=[refid]"
		)
	else
		dropdownoptions = D.vv_get_dropdown()


	var/list/dropdownoptions_html = list()
	for(var/name in dropdownoptions)
		var/link = dropdownoptions[name]
		if(link)
			dropdownoptions_html += "<option value='[link]'>[name]</option>"
		else
			dropdownoptions_html += "<option value>[name]</option>"


	var/list/names = list()
	if(!islist)
		for(var/V in D.vars)
			names += V


	sleep(1) // Without a sleep here, VV sometimes disconnects clients


	var/list/variable_html = list()
	if(islist)
		var/list/L = D
		for(var/i in 1 to length(L))
			var/key = L[i]
			var/value
			if(IS_NORMAL_LIST(L) && !isnum(key))
				value = L[key]
			variable_html += debug_variable(i, value, 0, D)
	else
		names = sortList(names)
		for(var/V in names)
			if(D.can_vv_get(V))
				variable_html += D.vv_get_var(V)

	var/html = {"
<html>
	<head>
		<meta charset="UTF-8">
		<title>[title]</title>
		<link rel="stylesheet" type="text/css" href="[SSassets.transport.get_asset_url("view_variables.css")]">
		[window_scaling ? "<style>body {zoom: [100 / window_scaling]%;}</style>" : ""]
	</head>
	<body onload='selectTextField(); updateSearch()' onkeydown='return checkreload()' onkeyup='updateSearch()'>
		<script type="text/javascript">
			function checkreload() {
				if(event.keyCode == 116){	//F5 (to refresh properly)
					document.getElementById("refresh_link").click();
					event.preventDefault ? event.preventDefault() : (event.returnValue = false)
					return false;
				}
				return true;
			}
			function updateSearch(){
				var filter_text = document.getElementById('filter');
				var filter = filter_text.value.toLowerCase();
				if(event.keyCode == 13){	//Enter / return
					var vars_ol = document.getElementById('vars');
					var lis = vars_ol.getElementsByTagName("li");
					for(var i = 0; i < lis.length; ++i)
					{
						try{
							var li = lis\[i\];
							if(li.style.backgroundColor == "#ffee88")
							{
								alist = lis\[i\].getElementsByTagName("a")
								if(alist.length > 0){
									location.href=alist\[0\].href;
								}
							}
						}catch(err) {   }
					}
					return
				}
				if(event.keyCode == 38){	//Up arrow
					var vars_ol = document.getElementById('vars');
					var lis = vars_ol.getElementsByTagName("li");
					for(var i = 0; i < lis.length; ++i)
					{
						try{
							var li = lis\[i\];
							if(li.className == "var visible" && li.style.backgroundColor == "#ffee88")
							{
								for(var j = i-1; j >= 0; --j) {
									var li_new = lis\[j\];
									if(li_new.className == "var visible") {
										li.style.backgroundColor = "white";
										li_new.style.backgroundColor = "#ffee88";
										return
									}
								}
							}
						}catch(err) {  }
					}
					return
				}
				if(event.keyCode == 40){	//Down arrow
					var vars_ol = document.getElementById('vars');
					var lis = vars_ol.getElementsByTagName("li");
					for(var i = 0; i < lis.length; ++i)
					{
						try{
							var li = lis\[i\];
							if(li.className == "var visible" && li.style.backgroundColor == "#ffee88")
							{
								for(var j = i+1; j < lis.length; ++j) {
									var li_new = lis\[j\];
									if(li_new.className == "var visible") {
										li.style.backgroundColor = "white";
										li_new.style.backgroundColor = "#ffee88";
										return
									}
								}
							}
						}catch(err) {  }
					}
					return
				}

				document.cookie="[refid][cookieoffset]search="+encodeURIComponent(filter);
				var vars_ol = document.getElementById('vars');
				var lis = vars_ol.getElementsByTagName("li");
				var first = true;
				for(var i = 0; i < lis.length; ++i)
				{
					try{
						var li = lis\[i\];
						li.style.backgroundColor = "white";
						if(li.innerText.toLowerCase().indexOf(filter) == -1)
						{
							li.className = "var";
						} else {
							if(first) {
								li.style.backgroundColor = "#ffee88";
								first = false;
							}
							li.className = "var visible";
						}
					}catch(err) {   }
				}
			}
			function selectTextField() {
				var filter_text = document.getElementById('filter');
				filter_text.focus();
				filter_text.select();
				var lastsearch = getCookie("[refid][cookieoffset]search");
				if(lastsearch) {
					filter_text.value = lastsearch;
					updateSearch();
				}
			}
			function loadPage(list) {
				if(list.options\[list.selectedIndex\].value == ""){
					return;
				}
				location.href=list.options\[list.selectedIndex\].value;
			}
			function getCookie(cname) {
				var name = cname + "=";
				var ca = document.cookie.split(';');
				for(var i=0; i<ca.length; i++) {
					var c = ca\[i\];
					while(c.charAt(0)==' ') c = c.substring(1,c.length);
					if(c.indexOf(name)==0) return c.substring(name.length,c.length);
				}
				return "";
			}

		</script>
		<div align='center'>
			<table width='100%'>
				<tr>
					<td width='50%'>
						<table align='center' width='100%'>
							<tr>
								<td>
									[sprite_text]
									<div align='center'>
										[atomsnowflake.Join()]
									</div>
								</td>
							</tr>
						</table>
						<div align='center'>
							<b><font size='1'>[formatted_type]</font></b>
							[marked]
							[varedited_line]
						</div>
					</td>
					<td width='50%'>
						<div align='center'>
							<a id='refresh_link' href='byond://?_src_=vars;[islist ? "listrefresh=\ref[D]" : "datumrefresh=[D.UID()]"]'>Refresh</a>
							<form>
								<select name="file" size="1"
									onchange="loadPage(this.form.elements\[0\])"
									target="_parent._top"
									onmouseclick="this.focus()"
									style="background-color:#ffffff">
									<option value selected>Select option</option>
									[dropdownoptions_html.Join()]
								</select>
							</form>
						</div>
					</td>
				</tr>
			</table>
		</div>
		<hr>
		<font size='1'>
			<b>E</b> - Edit, tries to determine the variable type by itself.<br>
			<b>C</b> - Change, asks you for the var type first.<br>
			<b>M</b> - Mass modify: changes this variable for all objects of this type.<br>
		</font>
		<hr>
		<table width='100%'>
			<tr>
				<td width='20%'>
					<div align='center'>
						<b>Search:</b>
					</div>
				</td>
				<td width='80%'>
					<input type='text' id='filter' name='filter_text' value='' style='width:100%;'>
				</td>
			</tr>
		</table>
		<hr>
		<ol id='vars'>
			[variable_html.Join()]
		</ol>
		<script type='text/javascript'>
			var vars_ol = document.getElementById("vars");
			var complete_list = vars_ol.innerHTML;
		</script>
	</body>
</html>
	"}

	if(istype(D, /datum))
		log_admin("[key_name(usr)] opened VV for [D] ([D.UID()])")

	var/size_string = window_scaling ? "size=[475 * window_scaling]x[650 * window_scaling]" : "size=[475]x[650]"
	usr << browse(html, "window=variables[refid];[size_string]")

#define VV_HTML_ENCODE(thing) ( sanitize ? html_encode(thing) : thing )
/proc/debug_variable(name, value, level, datum/owner, sanitize = TRUE)
	var/header
	if(owner)
		if(islist(owner))
			var/list/debug_list = owner
			var/index = name
			if(value)
				name = debug_list[name] // name is really the index until this line
			else
				value = debug_list[name]
			header = "<li class='vars visible'>(<a href='byond://?_src_=vars;listedit=\ref[owner];index=[index]'>E</a>) (<a href='byond://?_src_=vars;listchange=\ref[owner];index=[index]'>C</a>) (<a href='byond://?_src_=vars;listremove=\ref[owner];index=[index]'>-</a>) "
		else
			header = "<li class='vars visible'>(<a href='byond://?_src_=vars;datumedit=[owner.UID()];varnameedit=[name]'>E</a>) (<a href='byond://?_src_=vars;datumchange=[owner.UID()];varnamechange=[name]'>C</a>) (<a href='byond://?_src_=vars;datummass=[owner.UID()];varnamemass=[name]'>M</a>) "
	else
		header = "<li>"

	var/name_part = VV_HTML_ENCODE(name)
	if(level > 0 || islist(owner)) //handling keys in assoc lists
		if(isdatum(name))
			var/datum/datum_key = name
			name_part = "<a href='byond://?_src_=vars;Vars=[datum_key.UID()]'>[VV_HTML_ENCODE(name)] \ref[datum_key]</a>"
		else if(isclient(name))
			var/client/client_key = name
			name_part = "<a href='byond://?_src_=vars;Vars=[client_key.UID()]'>[VV_HTML_ENCODE(client_key)] \ref[client_key]</a> ([client_key] [client_key.type])"
		else if(islist(name))
			var/list/list_value = name
			name_part = "<a href='byond://?_src_=vars;VarsList=\ref[list_value]'> /list ([length(list_value)]) \ref[name]</a>"

	var/item = _debug_variable_value(name, value, level, owner, sanitize)

	return "[header][name_part] = [item]</li>"

/proc/_debug_variable_value(name, value, level, datum/owner, sanitize)

	. = "<font color='red'>DISPLAY_ERROR:</font> ([value] \ref[value]s)"

	if(isnull(value))
		return "<span class='value'>null</span>"

	else if(is_color_text(value))
		return "<span class='value'><span class='colorbox' style='width: 1em; background-color: [value]; border: 1px solid black; display: inline-block'>&nbsp;</span> \"[value]\"</span>"

	else if(istext(value))
		return "<span class='value'>\"[VV_HTML_ENCODE(value)]\"</span>"

	else if(isicon(value))
		#ifdef VARSICON
		return "/icon (<span class='value'>[value]</span>) [bicon(value, use_class=0)]"
		#else
		return "/icon (<span class='value'>[value]</span>)"
		#endif

	else if(istype(value, /image))
		var/image/I = value
		#ifdef VARSICON
		return "<a href='byond://?_src_=vars;Vars=[I.UID()]'>[name] \ref[value]</a> /image (<span class='value'>[value]</span>) [bicon(value, use_class=0)]"
		#else
		return "<a href='byond://?_src_=vars;Vars=[I.UID()]'>[name] \ref[value]</a> /image (<span class='value'>[value]</span>)"
		#endif

	else if(isfile(value))
		return "<span class='value'>'[value]'</span>"

	else if(istype(value, /datum))
		var/datum/D = value
		return D.debug_variable_value(sanitize)

	else if(islist(value))
		var/list/L = value
		var/list/items = list()

		if(length(L) > 0 && !(name == "underlays" || name == "overlays" || name == "vars" || length(L) > (IS_NORMAL_LIST(L) ? 250 : 300)))
			for(var/i in 1 to length(L))
				var/key = L[i]
				var/val
				if(IS_NORMAL_LIST(L) && !isnum(key))
					val = L[key]
				if(isnull(val))
					val = key
					key = i

				items += debug_variable(key, val, level + 1, sanitize = sanitize)

			return "<a href='byond://?_src_=vars;VarsList=\ref[L]'>/list ([length(L)])</a><ul>[items.Join()]</ul>"

		else
			return "<a href='byond://?_src_=vars;VarsList=\ref[L]'>/list ([length(L)])</a>"

	else if(name in GLOB.bitfields)
		return "<span class='value'>[VV_HTML_ENCODE(translate_bitfield(VV_BITFIELD, name, value))]</span>"
	else
		return "<span class='value'>[VV_HTML_ENCODE(value)]</span>"

/datum/proc/debug_variable_value(sanitize)
	return "<a href='byond://?_src_=vars;Vars=[UID()]'>[VV_HTML_ENCODE(src)] \ref[src]</a> ([type])"

/matrix/debug_variable_value(sanitize)
	return {"<span class='value'>
			<table class='matrixbrak'><tbody><tr><td class='lbrak'>&nbsp;</td><td>
			<table class='matrix'>
			<tbody>
				<tr><td>[a]</td><td>[d]</td><td>0</td></tr>
				<tr><td>[b]</td><td>[e]</td><td>0</td></tr>
				<tr><td>[c]</td><td>[f]</td><td>1</td></tr>
			</tbody>
			</table></td><td class='rbrak'>&nbsp;</td></tr></tbody></table></span>"} //TODO link to modify_transform wrapper for all matrices

/client/proc/view_var_Topic(href, href_list, hsrc)
	//This should all be moved over to datum/admins/Topic() or something ~Carn
	if(!check_rights(R_ADMIN|R_MOD, FALSE) \
		&& !((href_list["datumrefresh"] || href_list["Vars"] || href_list["VarsList"]) && check_rights(R_VIEWRUNTIMES, FALSE)) \
		&& !((href_list["proc_call"]) && check_rights(R_PROCCALL, FALSE)) \
	)
		return // clients with R_VIEWRUNTIMES can still refresh the window/view references/view lists. they cannot edit anything else however.

	if(view_var_Topic_list(href, href_list, hsrc))  // done because you can't use UIDs with lists and I don't want to snowflake into the below check to supress warnings
		return

	// Correct and warn about any VV topic links that aren't using UIDs
	for(var/paramname in href_list)
		if(findtext(href_list[paramname], "]_"))
			continue // Contains UID-specific formatting, skip it
		var/datum/D = locate(href_list[paramname])
		if(!D)
			continue
		var/datuminfo = "[D]"
		if(istype(D))
			datuminfo = datum_info_line(D)
			href_list[paramname] = D.UID()
		else if(isclient(D))
			var/client/C = D
			href_list[paramname] = C.UID()
		stack_trace("Found \\ref-based '[paramname]' param in VV topic for [datuminfo], should be UID: [href]")

	if(href_list["Vars"])
		debug_variables(locateUID(href_list["Vars"]))

	//~CARN: for renaming mobs (updates their name, real_name, mind.name, their ID/PDA and datacore records).
	else if(href_list["rename"])
		if(!check_rights(R_ADMIN))	return

		var/mob/M = locateUID(href_list["rename"])
		if(!istype(M))
			to_chat(usr, "This can only be used on instances of type /mob")
			return

		var/new_name = reject_bad_name(sanitize(copytext_char(input(usr, "What would you like to name this mob?", "Input a name", M.real_name) as text|null, 1, MAX_NAME_LEN)), allow_numbers = TRUE)
		if(!new_name || !M)	return

		message_admins("Admin [key_name_admin(usr)] renamed [key_name_admin(M)] to [new_name].")
		M.rename_character(M.real_name, new_name)
		href_list["datumrefresh"] = href_list["rename"]

	else if(href_list["varnameedit"] && href_list["datumedit"])
		if(!check_rights(R_VAREDIT))	return

		var/D = locateUID(href_list["datumedit"])
		if(!istype(D,/datum) && !isclient(D))
			to_chat(usr, "This can only be used on instances of types /client or /datum")
			return

		modify_variables(D, href_list["varnameedit"], 1)

	else if(href_list["togbit"])
		if(!check_rights(R_VAREDIT))	return

		var/atom/D = locateUID(href_list["subject"])
		if(!istype(D,/datum) && !isclient(D))
			to_chat(usr, "This can only be used on instances of types /client or /datum")
			return
		if(!(href_list["var"] in D.vars))
			to_chat(usr, "Unable to find variable specified.")
			return
		var/value = D.vars[href_list["var"]]
		value ^= 1 << text2num(href_list["togbit"])

		D.vars[href_list["var"]] = value

	else if(href_list["varnamechange"] && href_list["datumchange"])
		if(!check_rights(R_VAREDIT))	return

		var/D = locateUID(href_list["datumchange"])
		if(!istype(D,/datum) && !isclient(D))
			to_chat(usr, "This can only be used on instances of types /client or /datum")
			return

		modify_variables(D, href_list["varnamechange"], 0)

	else if(href_list["varnamemass"] && href_list["datummass"])
		if(!check_rights(R_VAREDIT))	return

		var/atom/A = locateUID(href_list["datummass"])
		if(!istype(A))
			to_chat(usr, "This can only be used on instances of type /atom")
			return

		cmd_mass_modify_object_variables(A, href_list["varnamemass"])


	else if(href_list["mob_player_panel"])
		if(!check_rights(R_ADMIN|R_MOD))	return

		var/mob/M = locateUID(href_list["mob_player_panel"])
		if(!istype(M))
			to_chat(usr, "This can only be used on instances of type /mob")
			return

		src.holder.show_player_panel(M)
		href_list["datumrefresh"] = href_list["mob_player_panel"]

	else if(href_list["give_spell"])
		if(!check_rights(R_SERVER|R_EVENT))	return

		var/mob/M = locateUID(href_list["give_spell"])
		if(!istype(M))
			to_chat(usr, "This can only be used on instances of type /mob")
			return

		src.give_spell(M)
		href_list["datumrefresh"] = href_list["give_spell"]

	else if(href_list["givemartialart"])
		if(!check_rights(R_SERVER|R_EVENT))	return

		var/mob/living/carbon/C = locateUID(href_list["givemartialart"])
		if(!istype(C))
			to_chat(usr, "This can only be done to instances of type /mob/living/carbon")
			return

		var/list/artpaths = subtypesof(/datum/martial_art)
		var/list/artnames = list()
		for(var/i in artpaths)
			var/datum/martial_art/M = i
			artnames[initial(M.name)] = M

		var/result = input(usr, "Choose the martial art to teach", "JUDO CHOP") as null|anything in artnames
		if(!usr)
			return
		if(QDELETED(C))
			to_chat(usr, "Mob doesn't exist anymore")
			return

		if(result)
			var/chosenart = artnames[result]
			var/datum/martial_art/MA = new chosenart
			MA.teach(C)

		href_list["datumrefresh"] = href_list["givemartialart"]

	else if(href_list["give_disease"])
		if(!check_rights(R_SERVER|R_EVENT))	return

		var/mob/M = locateUID(href_list["give_disease"])
		if(!istype(M))
			to_chat(usr, "This can only be used on instances of type /mob")
			return

		src.give_disease(M)
		href_list["datumrefresh"] = href_list["give_spell"]

	else if(href_list["godmode"])
		if(!check_rights(R_EVENT))	return

		var/mob/M = locateUID(href_list["godmode"])
		if(!istype(M))
			to_chat(usr, "This can only be used on instances of type /mob")
			return

		src.cmd_admin_godmode(M)
		href_list["datumrefresh"] = href_list["godmode"]

	else if(href_list["gib"])
		if(!check_rights(R_ADMIN|R_EVENT))	return

		var/mob/M = locateUID(href_list["gib"])
		if(!istype(M))
			to_chat(usr, "This can only be used on instances of type /mob")
			return

		src.cmd_admin_gib(M)

	else if(href_list["build_mode"])
		if(!check_rights(R_BUILDMODE))	return

		var/mob/M = locateUID(href_list["build_mode"])
		if(!istype(M))
			to_chat(usr, "This can only be used on instances of type /mob")
			return

		togglebuildmode(M)
		href_list["datumrefresh"] = href_list["build_mode"]

	else if(href_list["drop_everything"])
		if(!check_rights(R_DEBUG|R_ADMIN))	return

		var/mob/M = locateUID(href_list["drop_everything"])
		if(!istype(M))
			to_chat(usr, "This can only be used on instances of type /mob")
			return

		if(usr.client)
			usr.client.cmd_admin_drop_everything(M)

	else if(href_list["direct_control"])
		if(!check_rights(R_DEBUG|R_ADMIN))	return

		var/mob/M = locateUID(href_list["direct_control"])
		if(!istype(M))
			to_chat(usr, "This can only be used on instances of type /mob")
			return

		if(usr.client)
			usr.client.cmd_assume_direct_control(M)

	else if(href_list["make_skeleton"])
		if(!check_rights(R_SERVER|R_EVENT))	return

		var/mob/living/carbon/human/H = locateUID(href_list["make_skeleton"])
		if(!istype(H))
			to_chat(usr, "This can only be used on instances of type /mob/living/carbon/human")
			return

		var/confirm = alert("Are you sure you want to turn this mob into a skeleton?","Confirm Skeleton Transformation","Yes","No")
		if(confirm != "Yes")
			return

		H.makeSkeleton()
		message_admins("[key_name(usr)] has turned [key_name(H)] into a skeleton")
		log_admin("[key_name_admin(usr)] has turned [key_name_admin(H)] into a skeleton")
		href_list["datumrefresh"] = href_list["make_skeleton"]

	else if(href_list["hallucinate"])
		if(!check_rights(R_SERVER | R_EVENT))
			return

		var/mob/living/carbon/human/C = locateUID(href_list["hallucinate"])
		if(!istype(C))
			to_chat(usr, "<span class='warning'>This can only be used on instances of type /mob/living/carbon/human</span>")
			return

		var/haltype = tgui_input_list(usr, "Select Hallucination Type", "Hallucinate", (subtypesof(/obj/effect/hallucination) + subtypesof(/datum/hallucination_manager)))
		if(!haltype)
			return
		C.invoke_hallucination(haltype)
		message_admins("[key_name(usr)] has given [key_name(C)] the [haltype] hallucination")
		log_admin("[key_name_admin(usr)] has given [key_name_admin(C)] the [haltype] hallucination")
		href_list["datumrefresh"] = href_list["hallucinate"]

	else if(href_list["offer_control"])
		if(!check_rights(R_ADMIN))	return

		var/mob/M = locateUID(href_list["offer_control"])
		if(!istype(M))
			to_chat(usr, "This can only be used on instances of type /mob")
			return
		offer_control(M)

	else if(href_list["delete"])
		if(!check_rights(R_DEBUG, 0))
			return

		var/datum/D = locateUID(href_list["delete"])
		if(!D)
			to_chat(usr, "Unable to locate item!")
		admin_delete(D)
		href_list["datumrefresh"] = href_list["delete"]

	else if(href_list["delall"])
		if(!check_rights(R_DEBUG|R_SERVER))	return

		var/obj/O = locateUID(href_list["delall"])
		if(!isobj(O))
			to_chat(usr, "This can only be used on instances of type /obj")
			return

		var/action_type = alert("Strict type ([O.type]) or type and all subtypes?", null,"Strict type","Type and subtypes","Cancel")
		if(action_type == "Cancel" || !action_type)
			return

		if(alert("Are you really sure you want to delete all objects of type [O.type]?", null,"Yes","No") != "Yes")
			return

		if(alert("Second confirmation required. Delete?", null,"Yes","No") != "Yes")
			return

		var/O_type = O.type
		switch(action_type)
			if("Strict type")
				var/i = 0
				for(var/obj/Obj in world)
					if(Obj.type == O_type)
						i++
						qdel(Obj)
				if(!i)
					to_chat(usr, "No objects of this type exist")
					return
				log_admin("[key_name(usr)] deleted all objects of type [O_type] ([i] objects deleted)")
				message_admins("[key_name_admin(usr)] deleted all objects of type [O_type] ([i] objects deleted)")
			if("Type and subtypes")
				var/i = 0
				for(var/obj/Obj in world)
					if(istype(Obj,O_type))
						i++
						qdel(Obj)
				if(!i)
					to_chat(usr, "No objects of this type exist")
					return
				log_admin("[key_name(usr)] deleted all objects of type or subtype of [O_type] ([i] objects deleted)")
				message_admins("[key_name_admin(usr)] deleted all objects of type or subtype of [O_type] ([i] objects deleted)")

	else if(href_list["makespeedy"])
		if(!check_rights(R_DEBUG|R_ADMIN))
			return
		var/obj/A = locateUID(href_list["makespeedy"])
		if(!istype(A))
			return
		A.var_edited = TRUE
		A.makeSpeedProcess()
		log_admin("[key_name(usr)] has made [A] speed process")
		message_admins("<span class='notice'>[key_name(usr)] has made [A] speed process</span>")
		return TRUE

	else if(href_list["makenormalspeed"])
		if(!check_rights(R_DEBUG|R_ADMIN))
			return
		var/obj/A = locateUID(href_list["makenormalspeed"])
		if(!istype(A))
			return
		A.var_edited = TRUE
		A.makeNormalProcess()
		log_admin("[key_name(usr)] has made [A] process normally")
		message_admins("<span class='notice'>[key_name(usr)] has made [A] process normally</span>")
		return TRUE

	else if(href_list["modifyarmor"])
		if(!check_rights(R_DEBUG|R_ADMIN))
			return
		var/obj/A = locateUID(href_list["modifyarmor"])
		if(!istype(A))
			return
		A.var_edited = TRUE
		var/list/armorlist = A.armor.getList()
		var/list/displaylist

		var/result
		do
			displaylist = list()
			for(var/key in armorlist)
				displaylist += "[key] = [armorlist[key]]"
			result = input(usr, "Select an armor type to modify..", "Modify armor") as null|anything in displaylist + "(ADD ALL)" + "(SET ALL)" + "(DONE)"

			if(result == "(DONE)")
				break
			else if(result == "(ADD ALL)" || result == "(SET ALL)")
				var/new_amount = input(usr, result == "(ADD ALL)" ? "Enter armor to add to all types:" : "Enter new armor value for all types:", "Modify all types") as num|null
				if(isnull(new_amount))
					continue
				var/proper_amount = text2num(new_amount)
				if(isnull(proper_amount))
					continue
				for(var/key in armorlist)
					armorlist[key] = (result == "(ADD ALL)" ? armorlist[key] : 0) + proper_amount
			else if(result)
				var/list/fields = splittext(result, " = ")
				if(length(fields) != 2)
					continue
				var/type = fields[1]
				if(isnull(armorlist[type]))
					continue
				var/new_amount = input(usr, "Enter new armor value for [type]:", "Modify [type]") as num|null
				if(isnull(new_amount))
					continue
				var/proper_amount = text2num(new_amount)
				if(isnull(proper_amount))
					continue
				armorlist[type] = proper_amount
		while(result)

		if(!result || !A)
			return TRUE

		A.armor = A.armor.setRating(armorlist[MELEE], armorlist[BULLET], armorlist[LASER], armorlist[ENERGY], armorlist[BOMB], armorlist[RAD], armorlist[FIRE], armorlist[ACID], armorlist[MAGIC])

		log_admin("[key_name(usr)] modified the armor on [A] to: melee = [armorlist[MELEE]], bullet = [armorlist[BULLET]], laser = [armorlist[LASER]], energy = [armorlist[ENERGY]], bomb = [armorlist[BOMB]], rad = [armorlist[RAD]], fire = [armorlist[FIRE]], acid = [armorlist[ACID]], magic = [armorlist[MAGIC]]")
		message_admins("<span class='notice'>[key_name(usr)] modified the armor on [A] to: melee = [armorlist[MELEE]], bullet = [armorlist[BULLET]], laser = [armorlist[LASER]], energy = [armorlist[ENERGY]], bomb = [armorlist[BOMB]], rad = [armorlist[RAD]], fire = [armorlist[FIRE]], acid = [armorlist[ACID]], magic = [armorlist[MAGIC]]")
		return TRUE

	else if(href_list["addreagent"]) /* Made on /TG/, credit to them. */
		if(!check_rights(R_DEBUG|R_ADMIN))	return

		var/atom/A = locateUID(href_list["addreagent"])

		if(!A.reagents)
			var/amount = input(usr, "Specify the reagent size of [A]", "Set Reagent Size", 50) as num
			if(amount)
				A.create_reagents(amount)

		if(A.reagents)
			var/chosen_id
			var/list/reagent_options = sortAssoc(GLOB.chemical_reagents_list)
			switch(alert(usr, "Choose a method.", "Add Reagents", "Enter ID", "Choose ID"))
				if("Enter ID")
					var/valid_id
					while(!valid_id)
						chosen_id = stripped_input(usr, "Enter the ID of the reagent you want to add.")
						if(!chosen_id) //Get me out of here!
							break
						for(var/ID in reagent_options)
							if(ID == chosen_id)
								valid_id = 1
						if(!valid_id)
							to_chat(usr, "<span class='warning'>A reagent with that ID doesn't exist!</span>")
				if("Choose ID")
					chosen_id = input(usr, "Choose a reagent to add.", "Choose a reagent.") as null|anything in reagent_options
			if(chosen_id)
				var/amount = input(usr, "Choose the amount to add.", "Choose the amount.", A.reagents.maximum_volume) as num
				if(amount)
					A.reagents.add_reagent(chosen_id, amount)
					log_admin("[key_name(usr)] has added [amount] units of [chosen_id] to \the [A]")
					message_admins("<span class='notice'>[key_name(usr)] has added [amount] units of [chosen_id] to \the [A]</span>")

	else if(href_list["editreagents"])
		if(!check_rights(R_DEBUG|R_ADMIN))
			return

		var/atom/A = locateUID(href_list["editreagents"])

		try_open_reagent_editor(A)

	else if(href_list["explode"])
		if(!check_rights(R_DEBUG|R_EVENT))	return

		var/atom/A = locateUID(href_list["explode"])
		if(!isobj(A) && !ismob(A) && !isturf(A))
			to_chat(usr, "This can only be done to instances of type /obj, /mob and /turf")
			return

		src.cmd_admin_explosion(A)
		href_list["datumrefresh"] = href_list["explode"]

	else if(href_list["emp"])
		if(!check_rights(R_DEBUG|R_EVENT))	return

		var/atom/A = locateUID(href_list["emp"])
		if(!isobj(A) && !ismob(A) && !isturf(A))
			to_chat(usr, "This can only be done to instances of type /obj, /mob and /turf")
			return

		src.cmd_admin_emp(A)
		href_list["datumrefresh"] = href_list["emp"]

	else if(href_list["mark_object"])
		if(!check_rights(0))	return

		var/datum/D = locateUID(href_list["mark_object"])
		if(!istype(D))
			to_chat(usr, "This can only be done to instances of type /datum")
			return

		src.holder.marked_datum = D
		href_list["datumrefresh"] = href_list["mark_object"]

	else if(href_list["proc_call"])
		if(!check_rights(R_PROCCALL))
			return

		var/T = locateUID(href_list["proc_call"])

		if(T)
			callproc_datum(T)

	else if(href_list["jump_to"])
		if(!check_rights(R_ADMIN))
			return

		var/atom/A = locateUID(href_list["jump_to"])
		var/turf/T = get_turf(A)
		if(T)
			usr.client.jumptoturf(T)
		href_list["datumrefresh"] = href_list["jump_to"]


	else if(href_list["rotatedatum"])
		if(!check_rights(R_DEBUG|R_ADMIN))	return

		var/atom/A = locateUID(href_list["rotatedatum"])
		if(!istype(A))
			to_chat(usr, "This can only be done to instances of type /atom")
			return

		switch(href_list["rotatedir"])
			if("right")	A.dir = turn(A.dir, -45)
			if("left")	A.dir = turn(A.dir, 45)

		message_admins("[key_name_admin(usr)] has rotated \the [A]")
		log_admin("[key_name(usr)] has rotated \the [A]")
		href_list["datumrefresh"] = href_list["rotatedatum"]

	else if(href_list["addlanguage"])
		if(!check_rights(R_SPAWN))	return

		var/mob/H = locateUID(href_list["addlanguage"])
		if(!istype(H))
			to_chat(usr, "This can only be done to instances of type /mob")
			return

		var/new_language = input("Please choose a language to add.","Language",null) as null|anything in GLOB.all_languages

		if(!new_language)
			return

		if(!H)
			to_chat(usr, "Mob doesn't exist anymore")
			return

		if(H.add_language(new_language, TRUE))
			to_chat(usr, "Added [new_language] to [H].")
			message_admins("[key_name_admin(usr)] has given [key_name_admin(H)] the language [new_language]")
			log_admin("[key_name(usr)] has given [key_name(H)] the language [new_language]")
		else
			to_chat(usr, "Mob already knows that language.")

	else if(href_list["remlanguage"])
		if(!check_rights(R_SPAWN))	return

		var/mob/H = locateUID(href_list["remlanguage"])
		if(!istype(H))
			to_chat(usr, "This can only be done to instances of type /mob")
			return

		if(!length(H.languages))
			to_chat(usr, "This mob knows no languages.")
			return

		var/datum/language/rem_language = input("Please choose a language to remove.","Language",null) as null|anything in H.languages

		if(!rem_language)
			return

		if(!H)
			to_chat(usr, "Mob doesn't exist anymore")
			return

		if(H.remove_language(rem_language.name, TRUE))
			to_chat(usr, "Removed [rem_language] from [H].")
			message_admins("[key_name_admin(usr)] has removed language [rem_language] from [key_name_admin(H)]")
			log_admin("[key_name(usr)] has removed language [rem_language] from [key_name(H)]")
		else
			to_chat(usr, "Mob doesn't know that language.")

	else if(href_list["addverb"])
		if(!check_rights(R_DEBUG))			return

		var/mob/living/H = locateUID(href_list["addverb"])

		if(!istype(H))
			to_chat(usr, "This can only be done to instances of type /mob/living")
			return
		var/list/possibleverbs = list()
		possibleverbs += "Cancel" 								// One for the top...
		possibleverbs += typesof(/mob/proc,/mob/verb,/mob/living/proc,/mob/living/verb)
		switch(H.type)
			if(/mob/living/carbon/human)
				possibleverbs += typesof(/mob/living/carbon/proc,/mob/living/carbon/verb,/mob/living/carbon/human/verb,/mob/living/carbon/human/proc)
			if(/mob/living/silicon/robot)
				possibleverbs += typesof(/mob/living/silicon/proc,/mob/living/silicon/robot/proc,/mob/living/silicon/robot/verb)
			if(/mob/living/silicon/ai)
				possibleverbs += typesof(/mob/living/silicon/proc,/mob/living/silicon/ai/proc,/mob/living/silicon/ai/verb)
		possibleverbs -= H.verbs
		possibleverbs += "Cancel" 								// ...And one for the bottom

		var/verb = input("Select a verb!", "Verbs",null) as anything in possibleverbs
		if(!H)
			to_chat(usr, "Mob doesn't exist anymore")
			return
		if(!verb || verb == "Cancel")
			return
		else
			add_verb(H, verb)
			message_admins("[key_name_admin(usr)] has given [key_name_admin(H)] the verb [verb]")
			log_admin("[key_name(usr)] has given [key_name(H)] the verb [verb]")

	else if(href_list["remverb"])
		if(!check_rights(R_DEBUG))			return

		var/mob/H = locateUID(href_list["remverb"])

		if(!istype(H))
			to_chat(usr, "This can only be done to instances of type /mob")
			return
		var/verb = input("Please choose a verb to remove.","Verbs",null) as null|anything in H.verbs
		if(!H)
			to_chat(usr, "Mob doesn't exist anymore")
			return
		if(!verb)
			return
		else
			remove_verb(H, verb)
			message_admins("[key_name_admin(usr)] has removed verb [verb] from [key_name_admin(H)]")
			log_admin("[key_name(usr)] has removed verb [verb] from [key_name(H)]")

	else if(href_list["addorgan"])
		if(!check_rights(R_SPAWN))	return

		var/mob/living/carbon/M = locateUID(href_list["addorgan"])
		if(!istype(M))
			to_chat(usr, "This can only be done to instances of type /mob/living/carbon")
			return

		var/new_organ = tgui_input_list(usr, "Please choose an organ to add.", "Organ", subtypesof(/obj/item/organ))
		if(!new_organ)
			return

		if(!M)
			to_chat(usr, "Mob doesn't exist anymore")
			return

		if(locateUID(new_organ) in M.internal_organs)
			to_chat(usr, "Mob already has that organ.")
			return
		var/obj/item/organ/internal/organ = new new_organ
		organ.insert(M)
		message_admins("[key_name_admin(usr)] has given [key_name_admin(M)] the organ [new_organ]")
		log_admin("[key_name(usr)] has given [key_name(M)] the organ [new_organ]")

	else if(href_list["remorgan"])
		if(!check_rights(R_SPAWN))	return

		var/mob/living/carbon/M = locateUID(href_list["remorgan"])
		if(!istype(M))
			to_chat(usr, "This can only be done to instances of type /mob/living/carbon")
			return

		var/obj/item/organ/internal/rem_organ = tgui_input_list(usr, "Please choose an organ to remove.", "Organ", M.internal_organs)

		if(!M)
			to_chat(usr, "Mob doesn't exist anymore")
			return

		if(!(rem_organ in M.internal_organs))
			to_chat(usr, "Mob does not have that organ.")
			return

		to_chat(usr, "Removed [rem_organ] from [M].")
		rem_organ.remove(M)
		message_admins("[key_name_admin(usr)] has removed the organ [rem_organ] from [key_name_admin(M)]")
		log_admin("[key_name(usr)] has removed the organ [rem_organ] from [key_name(M)]")
		qdel(rem_organ)

	else if(href_list["regenerateicons"])
		if(!check_rights(0))	return

		var/mob/M = locateUID(href_list["regenerateicons"])
		if(!ismob(M))
			to_chat(usr, "This can only be done to instances of type /mob")
			return
		M.regenerate_icons()

	else if(href_list["adjustDamage"] && href_list["mobToDamage"])
		if(!check_rights(R_DEBUG|R_ADMIN|R_EVENT))	return

		var/mob/living/L = locateUID(href_list["mobToDamage"])
		if(!istype(L)) return

		var/Text = href_list["adjustDamage"]

		var/amount =	input("Deal how much damage to mob? (Negative values here heal)","Adjust [Text]loss",0) as num

		if(!L)
			to_chat(usr, "Mob doesn't exist anymore")
			return

		switch(Text)
			if("brute")
				if(ishuman(L))
					var/mob/living/carbon/human/H = L
					H.adjustBruteLoss(amount, robotic = TRUE)
				else
					L.adjustBruteLoss(amount)
			if("fire")
				if(ishuman(L))
					var/mob/living/carbon/human/H = L
					H.adjustFireLoss(amount, robotic = TRUE)
				else
					L.adjustFireLoss(amount)
			if("toxin")
				L.adjustToxLoss(amount)
			if("oxygen")
				L.adjustOxyLoss(amount)
			if("brain")
				L.adjustBrainLoss(amount)
			if("clone")
				L.adjustCloneLoss(amount)
			if("stamina")
				L.adjustStaminaLoss(amount)
			else
				to_chat(usr, "You caused an error. DEBUG: Text:[Text] Mob:[L]")
				return

		if(amount != 0)
			log_admin("[key_name(usr)] dealt [amount] amount of [Text] damage to [L]")
			message_admins("[key_name_admin(usr)] dealt [amount] amount of [Text] damage to [L]")
			href_list["datumrefresh"] = href_list["mobToDamage"]

	else if(href_list["traitmod"])
		if(!check_rights(NONE))
			return
		var/datum/A = locateUID(href_list["traitmod"])
		if(!istype(A))
			return
		holder.modify_traits(A)

	if(href_list["addcomponent"])
		if(!check_rights(NONE))
			return
		var/datum/target = locateUID(href_list["addcomponent"])
		if(!target)
			return
		var/list/names = list()
		var/list/componentsubtypes = sortList(subtypesof(/datum/component), GLOBAL_PROC_REF(cmp_typepaths_asc))
		names += "---Components---"
		names += componentsubtypes
		names += "---Elements---"
		names += sortList(subtypesof(/datum/element), GLOBAL_PROC_REF(cmp_typepaths_asc))

		var/result = tgui_input_list(usr, "Choose a component/element to add", "Add Component", names)
		if(isnull(result))
			return
		if(!usr || result == "---Components---" || result == "---Elements---")
			return

		if(QDELETED(src))
			to_chat(usr, "That thing doesn't exist anymore!", confidential = TRUE)
			return

		var/list/lst = get_callproc_args()
		if(!lst)
			return

		var/datumname = "error"
		lst.Insert(1, result)
		if(result in componentsubtypes)
			datumname = "component"
			target._AddComponent(lst)
		else
			datumname = "element"
			target._AddElement(lst)
		log_admin("[key_name(usr)] has added [result] [datumname] to [key_name(target)].")
		message_admins("<span class='notice'>[key_name_admin(usr)] has added [result] [datumname] to [key_name_admin(target)].</span>")
	if(href_list["removecomponent"] || href_list["massremovecomponent"])
		if(!check_rights(NONE))
			return
		var/datum/target = href_list["removecomponent"] ? locateUID(href_list["removecomponent"]) : locateUID(href_list["massremovecomponent"])
		if(!target)
			return
		var/mass_remove = href_list["massremovecomponent"]
		var/list/components = target.datum_components.Copy()
		var/list/names = list()
		names += "---Components---"
		if(length(components))
			names += sortList(components, GLOBAL_PROC_REF(cmp_typepaths_asc))
		names += "---Elements---"
		// We have to list every element here because there is no way to know what element is on this object without doing some sort of hack.
		names += sortList(subtypesof(/datum/element), GLOBAL_PROC_REF(cmp_typepaths_asc))
		var/path = tgui_input_list(usr, "Choose a component/element to remove. All elements listed here may not be on the datum.", "Remove element", names)
		if(isnull(path))
			return
		if(!usr || path == "---Components---" || path == "---Elements---")
			return
		if(QDELETED(src))
			to_chat(usr, "That thing doesn't exist anymore!")
			return
		var/list/targets_to_remove_from = list(target)
		if(mass_remove)
			var/method = vv_subtype_prompt(target.type)
			targets_to_remove_from = get_all_of_type(target.type, method)

			if(alert(usr, "Are you sure you want to mass-delete [path] on [target.type]?", "Mass Remove Confirmation", "Yes", "No") == "No")
				return

		var/list/ele_list = list()
		if(ispath(path, /datum/element))
			ele_list = get_callproc_args()
			ele_list.Insert(1, path)
		for(var/datum/target_to_remove_from as anything in targets_to_remove_from)
			if(ispath(path, /datum/element))
				target._RemoveElement(ele_list)
			else
				var/list/components_actual = target_to_remove_from.GetComponents(path)
				for(var/to_delete in components_actual)
					qdel(to_delete)

		message_admins("<span class='notice'>[key_name_admin(usr)] has [mass_remove ? "mass" : ""] removed [path] component from [mass_remove ? target.type : key_name_admin(target)].</span>")
	if(href_list["datumrefresh"])
		var/datum/DAT = locateUID(href_list["datumrefresh"])
		if(!istype(DAT, /datum) && !isclient(DAT))
			return
		src.debug_variables(DAT)

	if(href_list["manipcolours"])
		if(!check_rights(R_DEBUG))
			return

		var/datum/target = locateUID(href_list["manipcolours"])
		if(!(isatom(target) || isclient(target)))
			to_chat(usr, "This can only be used on atoms and clients")
			return

		message_admins("[key_name_admin(usr)] is manipulating the colour matrix for [target]")
		var/datum/ui_module/colour_matrix_tester/CMT = new(target=target)
		CMT.ui_interact(usr)

	if(href_list["grantdeadchatcontrol"])
		if(!check_rights(R_EVENT))
			return

		var/atom/movable/A = locateUID(href_list["grantdeadchatcontrol"])
		if(!istype(A))
			return

		if(!GLOB.dsay_enabled)
			// TODO verify what happens when deadchat is muted
			to_chat(usr, "<span class='warning'>Deadchat is globally muted, un-mute deadchat before enabling this.</span>")
			return

		if(A.GetComponent(/datum/component/deadchat_control))
			to_chat(usr, "<span class='warning'>[A] is already under deadchat control!</span>")
			return

		var/control_mode = input(usr, "Please select the control mode","Deadchat Control", null) as null|anything in list("democracy", "anarchy")

		var/selected_mode
		switch(control_mode)
			if("democracy")
				selected_mode = DEADCHAT_DEMOCRACY_MODE
			if("anarchy")
				selected_mode = DEADCHAT_ANARCHY_MODE
			else
				return

		var/cooldown = input(usr, "Please enter a cooldown time in seconds. For democracy, it's the time between actions (must be greater than zero). For anarchy, it's the time between each user's actions, or -1 for no cooldown.", "Cooldown", null) as null|num
		if(isnull(cooldown) || (cooldown == -1 && selected_mode == DEADCHAT_DEMOCRACY_MODE))
			return
		if(cooldown < 0 && selected_mode == DEADCHAT_DEMOCRACY_MODE)
			to_chat(usr, "<span class='warning'>The cooldown for democracy mode must be greater than zero.</span>")
			return
		if(cooldown == -1)
			cooldown = 0
		else
			cooldown = cooldown SECONDS

		A.deadchat_plays(selected_mode, cooldown)
		message_admins("[key_name_admin(usr)] provided deadchat control to [A].")

	if(href_list["removedeadchatcontrol"])
		if(!check_rights(R_EVENT))
			return

		var/atom/movable/A = locateUID(href_list["removedeadchatcontrol"])
		if(!istype(A))
			return

		if(!A.GetComponent(/datum/component/deadchat_control))
			to_chat(usr, "<span class='warning'>[A] is not currently under deadchat control!</span>")
			return

		A.stop_deadchat_plays()
		message_admins("[key_name_admin(usr)] removed deadchat control from [A].")

/client/proc/view_var_Topic_list(href, href_list, hsrc)
	if(href_list["VarsList"])
		debug_variables(locate(href_list["VarsList"]))
		return TRUE

	if(href_list["listedit"] && href_list["index"])
		var/index = text2num(href_list["index"])
		if(!index)
			return TRUE

		var/list/L = locate(href_list["listedit"])
		if(!istype(L))
			to_chat(usr, "This can only be used on instances of type /list")
			return

		mod_list(L, null, "list", "contents", index, autodetect_class = TRUE)
		return TRUE

	if(href_list["listchange"] && href_list["index"])
		var/index = text2num(href_list["index"])
		if(!index)
			return TRUE

		var/list/L = locate(href_list["listchange"])
		if(!istype(L))
			to_chat(usr, "This can only be used on instances of type /list")
			return

		mod_list(L, null, "list", "contents", index, autodetect_class = FALSE)
		return TRUE

	if(href_list["listremove"] && href_list["index"])
		var/index = text2num(href_list["index"])
		if(!index)
			return TRUE

		var/list/L = locate(href_list["listremove"])
		if(!istype(L))
			to_chat(usr, "This can only be used on instances of type /list")
			return

		var/variable = L[index]
		var/prompt = alert("Do you want to remove item number [index] from list?", "Confirm", "Yes", "No")
		if(prompt != "Yes")
			return
		L.Cut(index, index+1)
		log_world("### ListVarEdit by [src]: /list's contents: REMOVED=[html_encode("[variable]")]")
		log_admin("[key_name(src)] modified list's contents: REMOVED=[variable]")
		message_admins("[key_name_admin(src)] modified list's contents: REMOVED=[variable]")
		return TRUE

	if(href_list["listadd"])
		var/list/L = locate(href_list["listadd"])
		if(!istype(L))
			to_chat(usr, "This can only be used on instances of type /list")
			return TRUE

		mod_list_add(L, null, "list", "contents")
		return TRUE

	if(href_list["listdupes"])
		var/list/L = locate(href_list["listdupes"])
		if(!istype(L))
			to_chat(usr, "This can only be used on instances of type /list")
			return TRUE

		uniqueList_inplace(L)
		log_world("### ListVarEdit by [src]: /list contents: CLEAR DUPES")
		log_admin("[key_name(src)] modified list's contents: CLEAR DUPES")
		message_admins("[key_name_admin(src)] modified list's contents: CLEAR DUPES")
		return TRUE

	if(href_list["listnulls"])
		var/list/L = locate(href_list["listnulls"])
		if(!istype(L))
			to_chat(usr, "This can only be used on instances of type /list")
			return TRUE

		listclearnulls(L)
		log_world("### ListVarEdit by [src]: /list contents: CLEAR NULLS")
		log_admin("[key_name(src)] modified list's contents: CLEAR NULLS")
		message_admins("[key_name_admin(src)] modified list's contents: CLEAR NULLS")
		return TRUE

	if(href_list["listlen"])
		var/list/L = locate(href_list["listlen"])
		if(!istype(L))
			to_chat(usr, "This can only be used on instances of type /list")
			return TRUE
		var/value = vv_get_value(VV_NUM)
		if(value["class"] != VV_NUM)
			return TRUE

		L.len = value["value"]
		log_world("### ListVarEdit by [src]: /list len: [length(L)]")
		log_admin("[key_name(src)] modified list's len: [length(L)]")
		message_admins("[key_name_admin(src)] modified list's len: [length(L)]")
		return TRUE

	if(href_list["listshuffle"])
		var/list/L = locate(href_list["listshuffle"])
		if(!istype(L))
			to_chat(usr, "This can only be used on instances of type /list")
			return TRUE

		shuffle_inplace(L)
		log_world("### ListVarEdit by [src]: /list contents: SHUFFLE")
		log_admin("[key_name(src)] modified list's contents: SHUFFLE")
		message_admins("[key_name_admin(src)] modified list's contents: SHUFFLE")
		return TRUE

	if(href_list["listrefresh"])
		debug_variables(locate(href_list["listrefresh"]))
		return TRUE

/client/proc/debug_global_variables(var_search as text)
	set category = "Debug"
	set name = "Debug Global Variables"

	if(!check_rights(R_ADMIN|R_VIEWRUNTIMES))
		to_chat(usr, "<span class='warning'>You need to be an administrator to access this.</span>")
		return

	var_search = trim(var_search)
	if(!var_search)
		return
	if(!GLOB.can_vv_get(var_search))
		return
	switch(var_search)
		if("vars")
			return FALSE
	if(!(var_search in GLOB.vars))
		to_chat(src, "<span class='debug'>GLOB.[var_search] does not exist.</span>")
		return
	log_and_message_admins("is debugging the Global Variables controller with the search term \"[var_search]\"")
	var/result = GLOB.vars[var_search]
	if(islist(result) || isclient(result) || istype(result, /datum))
		to_chat(src, "<span class='debug'>Now showing GLOB.[var_search].</span>")
		return debug_variables(result)
	to_chat(src, "<span class='debug'>GLOB.[var_search] returned [result].</span>")

#undef VV_HTML_ENCODE
