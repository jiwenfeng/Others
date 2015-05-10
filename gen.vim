if exists("g:load_gen")
	finish
endif

let g:load_gen = 1

map<F2> :call Main("c") <CR>
map<F3> :call Main("cc") <CR>
map<F4> :call Main("cpp) <CR>

function! IsFunction(str)
	return match(a:str, '(.*)') != -1
endfunction

function! GenPrototype(...)
	let s:str=getline(".")
	if(!IsFunction(s:str))
		return
	endif
	let s:str = s:str . ";"
	let s:fname = substitute(bufname("%"), '.\w\+$', ".h", "")
	if(!bufloaded(s:fname))
		execute "tabnew " . s:fname
	endif
	let s:idx=bufnr(s:fname)
	execute "tabn " . s:idx
	let s:type=match(s:str, "::")
	if(s:type != -1)
		let s:cls_name = matchstr(s:str, '\w\+::')
		let s:str = substitute(s:str, '.\(\S\+\)::', " ", "")
		let s:cmp_str = substitute(s:str, '*', '\\*', "g")
		let s:cls_name = substitute(s:cls_name, "::", "", "")
		let s:cls_idx = search('^class\s\+' . s:cls_name, "b")
		let s:cls_end_line = search('^};$', "W")
		if(s:cls_idx > 0)
			let s:num = search('^\s*' . s:cmp_str, "b")
			if(s:num > s:cls_idx && s:num < s:cls_end_line)
				return
			endif
			call cursor(s:cls_idx, 0)
			let s:idx = search('^\s*public', "W")
			if(s:idx > s:cls_idx && s:idx < s:cls_end_line)
				call append(s:idx, "\t" . s:str)
			elseif
				call append(s:cls_idx + 1, "public:")
				call append(s:cls_idx + 2, "\t" . s:str)
			endif
		else 
			call append(line("$"), "")
			let s:line = line("$") - 1
			call append(s:line, "class " . s:cls_name)
			call append(s:line, "{")
			call append(s:line, "public:")
			call append(s:line - 1, "\t".s:str)
			call append(s:line - 1, "};")
		endif
	else
		let s:cmp_str = substitute(s:str, '*', '\\*', "g")
		let s:num = search('^\s*' . s:cmp_str, "b")
		let s:cls_start = search('^class\s\+', "W")
		let s:cls_end_line = search('^};$', "W")
		if(s:num != 0 && (s:num < s:cls_idx || s:num > s:cls_end_line))
			return
		endif
		let s:line = line("$")
		call append(s:line - 1, "")
		call append(s:line - 1, s:str)
	endif
	execute "w"
endfunction

function! GenDefination(type)
	let s:str = getline(".")
	if(!IsFunction(s:str))
		return
	endif
	if(-1 != match(s:str, 'inline\s\+')) 
		return
	endif
	let s:cur = line(".")
	let s:str = substitute(s:str, '\s\+', " ", "g")
	let s:str = substitute(s:str, "virtual", "", "") 
	let s:str = substitute(s:str, ";", "", "") 
	let s:str = substitute(s:str, '^\s\+', "", "") 
	let s:cls_start = search('^class', "b")
	let s:cls_end = search('^};$', "W")
	if(s:cur < s:cls_end && s:cur > s:cls_start) 
		let s:cls_name = matchlist(getline(s:cls_start), 'class\s\+\(\S\+\)')[1]
		"let s:cls_name = matchstr(getline(s:cls_start), '[^class\s\+]\S\+') 
		let s:func_name = matchstr(s:str, '\(\w\+\s*(\)') 
		if(strlen(s:func_name) == 0 || strlen(s:cls_name) == 0)
			return
		endif
		let s:str = substitute(s:str, s:func_name, s:cls_name."::".s:func_name, "")
	endif

	let s:fname = substitute(bufname("%"), '.\(\w\+\)$', "." . a:type, "")
	if(!bufloaded(s:fname))
		execute "tabnew " . s:fname
	endif
	let s:idx=bufnr(s:fname) 
	execute "tabn " . s:idx

	let s:str1 = substitute(s:str, '*', '\\*', "g")
	if(search(s:str1 , "b") == 0)
		call append(line("$"), "")
		call append(line("$"), s:str)
		call append(line("$"), "{")
		call cursor(line("$"), 0)
		call append(line("$"), "}")
	endif
	execute "w"
endfunction

function! Main(type)
	let s:ext = fnamemodify(bufname("%"), ":e")
	if(s:ext == "cc" || s:ext == "cpp" || s:ext == "c")
		call GenPrototype()
	elseif(s:ext == "h" || s:ext == "hpp")
		call GenDefination(a:type)
	else
		echo "Only support C/C++"
	endif
endfunction
