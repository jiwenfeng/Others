if !exists("s:load")
	let s:load = 1
	map<F12> :call Main("c") <CR>
	map<F11> :call Main("cc") <CR>
	map<F10> :call Main("cpp") <CR>
endif

"����ԭ��
function GenPrototype(...)
	let s:str=getline(".")
	let s:str = s:str . ";"
	let s:fname = substitute(bufname("%"), '.\w\+$', ".h", "")
	if(!bufloaded(s:fname))
		execute "tabnew " . s:fname
	endif
	let s:old_page_idx=bufnr(bufname("%"))
	let s:idx=bufnr(s:fname) "��ȡҳǩ��
	execute "tabn " . s:idx
	let s:type=match(s:str, "::")
	if(s:type != -1) " ��Ա����
		let s:cls_name = matchstr(s:str, '\S\+::')
		let s:str = substitute(s:str, '.\(\S\+\)::', " ", "") " ��ȡԭ��
		let s:cls_name = substitute(s:cls_name, "::", "", "")
		let s:cls_idx = search('^class\s\+' . s:cls_name, "b")
		if(s:cls_idx > 0) " ���Ѷ���
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
		else " ��δ����
			call append(line("$"), "")
			let s:line = line("$") - 1
			call append(s:line, "class " . s:cls_name)
			call append(line("$") - 1, "{")
			call append(line("$") - 1, "public:")
			call append(line("$") - 1, "\t".s:str)
			call append(line("$") - 1, "};")
		endif
	else
		if(search('^\s\+' . s:str, "b") == 0)
			let s:line = line("$") - 1 " �Է����һ����#endif
		endif
	endif
	execute "w"
endfunction

"��������
function GenDefination(type)
	let s:str = getline(".") "��ȡ��ǰ�е�����
	let s:cur = winline()
	let s:str = substitute(s:str, "virtual", "", "") " ȥ��virtual���η�
	let s:str = substitute(s:str, "inline", "", "") "ȥ��inline���η�
	let s:str = substitute(s:str, ";", "", "") "ȥ��;
	let s:str = substitute(s:str, '^\s\+', "", "") "ȥ���ո�
	let s:ln = search("^class", "b") "��ȡ����
	let s:end_cls_line = search("};$", "W")
	if(s:cur < s:end_cls_line)
		"let s:cls_name = matchlist(getline(s:ln), 'class\s\+\(\S\+\)')[1]
		let s:cls_name = matchstr(getline(s:ln), '[^class\s\+]\S\+')
		let s:fun_name = matchstr(s:str, '\(\S\+\s*(\)')
		if(strlen(s:fun_name) == 0)
			return
		endif
	endif
	let s:fname=bufname("%")
	let s:str=getline(".")
	let s:str = s:str . ";"
	let s:fname = substitute(bufname("%"), '.\w\+$', ".h", "")
	if(!bufloaded(s:fname))
		execute "tabnew " . s:fname
	endif
	let s:old_page_idx=bufnr(bufname("%"))
	let s:idx=bufnr(s:fname) "��ȡҳǩ��
	execute "tabn " . s:idx
	let s:type=match(s:str, "::")
	if(s:type != -1) " ��Ա����
		let s:cls_name = matchstr(s:str, '\S\+::')
		let s:str = substitute(s:str, '.\(\S\+\)::', " ", "") " ��ȡԭ��
		let s:cls_name = substitute(s:cls_name, "::", "", "")
		let s:cls_idx = search('^class\s\+' . s:cls_name, "b")
		if(s:cls_idx > 0) " ���Ѷ���
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
		else " ��δ����
			call append(line("$"), "")
			let s:line = line("$") - 1
			call append(s:line, "class " . s:cls_name)
			call append(line("$") - 1, "{")
			call append(line("$") - 1, "public:")
			call append(line("$") - 1, "\t".s:str)
			call append(line("$") - 1, "};")
		endif
	else
		if(search('^\s\+' . s:str, "b") == 0)
			let s:line = line("$") - 1 " �Է����һ����#endif
		endif
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
