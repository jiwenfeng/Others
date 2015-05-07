if !exists("s:load")
	let s:load = 1
	map<F5> :call Main("c") <CR>
	map<F6> :call Main("cc") <CR>
	map<F7> :call Main("cpp") <CR>
endif

"函数原型
function GenPrototype(...)
	let s:str=getline(".")
	let s:str = s:str . ";"
	let s:fname = substitute(bufname("%"), '.\w\+$', ".h", "")
	if(!bufloaded(s:fname))
		execute "tabnew " . s:fname
	endif
	let s:idx=bufnr(s:fname) "获取页签号
	execute "tabn " . s:idx
	let s:type=match(s:str, "::")
	if(s:type != -1) " 成员函数
		let s:cls_name = matchstr(s:str, '\S\+::')
		let s:str = substitute(s:str, '.\(\S\+\)::', " ", "") " 获取原型
		let s:cls_name = substitute(s:cls_name, "::", "", "")
		let s:cls_idx = search('^class\s\+' . s:cls_name, "b")
		if(s:cls_idx > 0) " 类已定义
			let s:end_cls_line = search('};$', "b")
			let s:num = search(s:str, "b")
			if(s:num > s:cls_idx && s:num < s:end_cls_line)
				return
			end
			let s:idx = search("^public:", "b")
			if(s:idx < s:end_cls_line)
				call append(s:idx + 1, "\t" . s:str)
			else
				call append(s:cls_idx + 2, "public:")
				call append(s:cls_idx + 3, "\t" . s:str)
			endif
		else " 类未定义
			call append(line("$"), "")
			let s:line = line("$") - 1
			call append(s:line, "class " . s:cls_name)
			call append(line("$") - 1, "{")
			call append(line("$") - 1, "public:")
			call append(line("$") - 1, "\t".s:str)
			call append(line("$") - 1, "};")
		endif
	else
		let s:pos = search('^\s\+' . s:str, "b")
		let s:cls_start = search('^class', "b")
		let s:cls_end = search('};$', "b")
		if(s:pos != 0 && (s:pos < s:cls_start || s:pos > s:cls_end))
			return
		endif
		let s:line = line("$")
		call append(s:line, "")
		call append(s:line, s:str)
	endif
	execute "w"
endfunction

"函数定义
function GenDefination(type)
	let s:str = getline(".") "获取当前行的内容
	if(-1 != match(s:str, 'inline\s\+')) 
		return
	endif
	let s:cur = winline()
	let s:str = substitute(s:str, "virtual", "", "") " 去掉virtual修饰符
	let s:str = substitute(s:str, ";", "", "") "去掉;
	let s:str = substitute(s:str, '^\s\+', "", "") "去掉空格
	let s:cls_start = search("^class", "b") "获取类名
	let s:cls_end = search("};$", "W")
	if(s:cur < s:cls_end && s:cur > s:cls_start) "　成员函数
		let s:cls_name = matchlist(getline(s:cls_start), 'class\s\+\(\S\+\)')[1]
		"let s:cls_name = matchstr(getline(s:cls_start), '[^class\s\+]\S\+') " 提取出类名
		let s:func_name = matchstr(s:str, '\(\S\+\s*(\)') "　提取出函数名
		if(strlen(s:func_name) == 0 || strlen(s:cls_name) == 0)
			return
		endif
		let s:str = substitute(s:str, s:func_name, s:cls_name."::".s:func_name, "")
	endif

	let s:fname = substitute(bufname("%"), '\.\(\w\+$\)', "\.".a:type, "")
	if(!bufloaded(s:fname))
		execute "tabnew " . s:fname
	endif
	let s:idx=bufnr(s:fname) "获取页签号
	execute "tabn " . s:idx

	if(search('^\s\+' . s:str, "b") == 0)
		call append(line("$"), "")
		call append(line("$"), s:str)
		call append(line("$"), "{")
		call cursor(line("$"), 0)
		call append(line("$"), "}")
	endif
	execute "w"
endfunction

function Main(type)
	let s:ext = fnamemodify(bufname("%"), ":e")
	if(s:ext == "cc" || s:ext == "cpp" || s:ext == "c")
		call GenPrototype()
	elseif(s:ext == "h" || s:ext == "hpp")
		call GenDefination(a:type)
	else
		echo "Only support C/C++"
	endif
endfunction
