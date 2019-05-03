" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not mofidify the code nor insert new lines before '" ___vital___'
if v:version > 703 || v:version == 703 && has('patch1170')
  function! vital#_over#Gift#import() abort
    return map({'flatten': '', 'uniq_tabpagenr': '', 'tabpagewinnr_list': '', 'execute': '', 'getwinvar': '', 'winnr': '', 'jump_window': '', '_vital_depends': '', 'uniq_winnr': '', 'setwinvar': '', 'find': '', 'openable_bufnr_list': '', 'to_fullpath': '', 'bufnr': '', 'set_current_window': '', 'tabpagewinnr': '', 'close_window': '', 'close_window_by': '', 'uniq_winnr_list': '', '_vital_loaded': '', 'find_by': ''},  'function("s:" . v:key)')
  endfunction
else
  function! s:_SID() abort
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
  endfunction
  execute join(['function! vital#_over#Gift#import() abort', printf("return map({'flatten': '', 'uniq_tabpagenr': '', 'tabpagewinnr_list': '', 'execute': '', 'getwinvar': '', 'winnr': '', 'jump_window': '', '_vital_depends': '', 'uniq_winnr': '', 'setwinvar': '', 'find': '', 'openable_bufnr_list': '', 'to_fullpath': '', 'bufnr': '', 'set_current_window': '', 'tabpagewinnr': '', 'close_window': '', 'close_window_by': '', 'uniq_winnr_list': '', '_vital_loaded': '', 'find_by': ''}, \"function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
  delfunction s:_SID
endif
" ___vital___
scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


function! s:_vital_loaded(V)
	let s:V = a:V
	let s:Window = s:V.import("Gift.Window")
	let s:Tabpage = s:V.import("Gift.Tabpage")
endfunction


function! s:_vital_depends()
	return [
\		"Gift.Window",
\		"Gift.Tabpage",
\	]
endfunction


function! s:to_fullpath(filename)
	let name = substitute(fnamemodify(a:filename, ":p"), '\', '/', "g")
	if filereadable(name)
		return name
	else
		return a:filename
	endif
endfunction


function! s:flatten(list)
	return eval(join(a:list, "+"))
endfunction


function! s:bufnr(expr)
	return type(a:expr) == type([])
\		 ? s:bufnr(s:uniq_winnr(a:expr[1], a:expr[0]))
\		 : s:Window.bufnr(a:expr)
endfunction


function! s:openable_bufnr_list()
	return map(s:tabpagewinnr_list(), "s:bufnr([v:val[0], v:val[1]])")
endfunction


function! s:tabpagewinnr(...)
	return a:0 == 0 ? s:tabpagewinnr(s:uniq_winnr())
\		 : s:Window.tabpagewinnr(a:1)
endfunction


function! s:tabpagewinnr_list()
	return s:Window.tabpagewinnr_list()
" 	return s:flatten(map(range(1, tabpagenr("$")), "map(range(1, tabpagewinnr(v:val, '$')), '['.v:val.', v:val]')"))
endfunction



function! s:uniq_winnr(...)
	return call(s:Window.uniq_nr, a:000, s:Window)
endfunction


function! s:winnr(uniqnr)
	let [tabnr, winnr] = s:Window.tabpagewinnr(a:uniqnr)
	return winnr
endfunction


function! s:uniq_winnr_list(...)
	return map(s:tabpagewinnr_list(), "s:uniq_winnr(v:val[1], v:val[0])")
endfunction



function! s:find(expr)
	let gift_find_result = []
	for [tabnr, winnr] in s:tabpagewinnr_list()
		let bufnr = s:bufnr([tabnr, winnr])
		if eval(a:expr)
			call add(gift_find_result, [tabnr, winnr])
		endif
	endfor
	return gift_find_result
endfunction


function! s:find_by(expr)
	if type(a:expr) == type(function("tr"))
		return filter(s:tabpagewinnr_list(), "a:expr(s:bufnr([v:val[0], v:val[1]]), v:val[0], v:val[1])")
	else
		return s:find(a:expr)
	endif
endfunction


function! s:jump_window(expr)
	return type(a:expr) == type([])
\		 ? s:jump_window(s:uniq_winnr(a:expr[1], a:expr[0]))
\		 : s:Window.jump(a:expr)
endfunction


function! s:set_current_window(expr)
	return s:jump_window(a:expr)
endfunction


function! s:close_window(expr, ...)
	let close_cmd = get(a:, 1, "close")
	return type(a:expr) == type([])
\		 ? s:close_window(s:uniq_winnr(a:expr[1], a:expr[0]), close_cmd)
\		 : s:Window.close(a:expr, close_cmd)
endfunction


function! s:close_window_by(expr, ...)
	let close_cmd = get(a:, 1, "close")
	return map(map(s:find(a:expr), "s:uniq_winnr(v:val[1], v:val[0])"), 's:close_window(v:val, close_cmd)')
endfunction


function! s:execute(expr, execute)
	return type(a:expr) == type([])
\		 ? s:execute(s:uniq_winnr(a:expr[1], a:expr[0]), a:execute)
\		 : s:Window.execute(a:expr, a:execute)
endfunction


function! s:getwinvar(uniq_winnr, varname, ...)
	let def = get(a:, 1, "")
	return s:Window.getvar(a:uniq_winnr, a:varname, def)
endfunction


function! s:setwinvar(uniq_winnr, varname, val)
	return s:Window.setvar(a:uniq_winnr, a:varname, a:val)
endfunction


function! s:uniq_tabpagenr(...)
	return call(s:Tabpage.uniq_nr, a:000, s:Tabpage)
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
