if !exists("s:load")
	let s:load = 1
	map<F12> :call Gen("c") <CR>
	map<F11> :call Gen("cc") <CR>
	map<F10> :call Gen("cpp") <CR>
endif

"����ԭ��
function GenPrototype(...)
	let s:str=getline(".")
	echo "GenPrototype"
endfunction

"��������
function GenDefination(type)
	let s:str=getline(".") "��ȡ��ǰ�е�����
	let s:str=substitute(s:str, "virtual", "", "") " ȥ��virtual���η�
	let s:str=substitute(s:str, "inline", "", "") "ȥ��inline���η�
	let s:str=substitute(s:str, ";", "", "") "ȥ��;
	let s:ln=search("^class", "b") "��ȡ����
	if(s:ln > 0)
		"let s:cls_name = matchlist(getline(s:ln), 'class\s\+\(\S\+\)')[1]
		let s:cls_name = matchstr(getline(s:ln), '[^class\s\+]\S\+')
		let s:fun_name = matchstr(s:str, '\(\S\+\s*(\)')
		let s:str = substitute(s:str, s:fun_name, s:cls_name."::".s:fun_name, "")
	endif
	let s:str = substitute(s:str, '\s*', "", "")
	let s:fname=bufname("%")
	let s:fname=substitute(s:fname, "[\.h]$", a:type, "")
	if(!bufloaded(s:fname))
		execute "tabnew ".s:fname
	endif
	let s:idx=bufnr(s:fname)
	execute "tabn ".s:idx
	call append(line("$"), "")
	call append(line("$"), s:str)
	call append(line("$"), "{")
	let s:l=line("$")
	call cursor(s:l, 0)
	call append(line("$"), "}")

endfunction

function Gen(type)
	let s:ext = fnamemodify(bufname("%"), ":e")
	if(s:ext == "cc" || s:ext == "cpp" || s:ext == "c")
		call GenPrototype()
	elseif(s:ext == "h" || s:ext == "hpp")
		call GenDefination(a:type)
	else
		echo "Only support C/C++"
	endif
endfunction
