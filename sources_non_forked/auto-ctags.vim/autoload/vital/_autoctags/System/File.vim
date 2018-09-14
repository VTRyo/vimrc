" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not mofidify the code nor insert new lines before '" ___vital___'
function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
execute join(['function! vital#_autoctags#System#File#import() abort', printf("return map({'copy_dir_vim': '', '_vital_depends': '', 'mkdir_nothrow': '', 'copy_exe': '', 'open': '', 'move_vim': '', 'copy': '', 'move': '', 'copy_dir_exe': '', 'copy_vim': '', 'move_exe': '', 'copy_dir': '', 'rmdir': '', '_vital_loaded': ''}, \"vital#_autoctags#function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
delfunction s:_SID
" ___vital___
" Utilities for file copy/move/mkdir/etc.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:Filepath = a:V.import('System.Filepath')
endfunction

function! s:_vital_depends() abort
  return ['System.Filepath']
endfunction

let s:is_unix = has('unix')
let s:is_windows = has('win16') || has('win32') || has('win64') || has('win95')
let s:is_cygwin = has('win32unix')
let s:is_mac = !s:is_windows && !s:is_cygwin
      \ && (has('mac') || has('macunix') || has('gui_macvim') ||
      \   (!isdirectory('/proc') && executable('sw_vers')))
" As of 7.4.122, the system()'s 1st argument is converted internally by Vim.
" Note that Patch 7.4.122 does not convert system()'s 2nd argument and
" return-value. We must convert them manually.
let s:need_trans = v:version < 704 || (v:version == 704 && !has('patch122'))

" Open a file.
function! s:open(filename) abort
  let filename = fnamemodify(a:filename, ':p')

  " Detect desktop environment.
  if s:is_windows
    " For URI only.
    if s:need_trans
      let filename = iconv(filename, &encoding, 'char')
    endif
    " Note:
    "   # and % required to be escaped (:help cmdline-special)
    silent execute printf(
          \ '!start rundll32 url.dll,FileProtocolHandler %s',
          \ escape(filename, '#%'),
          \)
  elseif s:is_cygwin
    " Cygwin.
    call system(printf('%s %s', 'cygstart',
          \ shellescape(filename)))
  elseif executable('xdg-open')
    " Linux.
    call system(printf('%s %s &', 'xdg-open',
          \ shellescape(filename)))
  elseif exists('$KDE_FULL_SESSION') && $KDE_FULL_SESSION ==# 'true'
    " KDE.
    call system(printf('%s %s &', 'kioclient exec',
          \ shellescape(filename)))
  elseif exists('$GNOME_DESKTOP_SESSION_ID')
    " GNOME.
    call system(printf('%s %s &', 'gnome-open',
          \ shellescape(filename)))
  elseif executable('exo-open')
    " Xfce.
    call system(printf('%s %s &', 'exo-open',
          \ shellescape(filename)))
  elseif s:is_mac && executable('open')
    " Mac OS.
    call system(printf('%s %s &', 'open',
          \ shellescape(filename)))
  else
    " Give up.
    throw 'vital: System.File: open(): Not supported.'
  endif
endfunction


" Move a file.
" Dispatch s:move_exe() or s:move_vim().
" FIXME: Currently s:move_vim() does not support
" moving a directory.
function! s:move(src, dest) abort
  if s:_has_move_exe() || isdirectory(a:src)
    return s:move_exe(a:src, a:dest)
  else
    return s:move_vim(a:src, a:dest)
  endif
endfunction

if s:is_unix
  function! s:_has_move_exe() abort
    return executable('mv')
  endfunction
elseif s:is_windows
  function! s:_has_move_exe() abort
    return 1
  endfunction
else
  function! s:_has_move_exe() abort
    throw 'vital: System.File: _has_move_exe(): your platform is not supported'
  endfunction
endif

" Move a file.
" Implemented by external program.
if s:is_unix
  function! s:move_exe(src, dest) abort
    if !s:_has_move_exe()
      return 0
    endif
    let [src, dest] = [a:src, a:dest]
    call system('mv ' . shellescape(src) . ' ' . shellescape(dest))
    return !v:shell_error
  endfunction
elseif s:is_windows
  function! s:move_exe(src, dest) abort
    if !s:_has_move_exe()
      return 0
    endif
    let [src, dest] = [a:src, a:dest]
    " Normalize successive slashes to one slash.
    let src  = substitute(src, '[/\\]\+', '\', 'g')
    let dest = substitute(dest, '[/\\]\+', '\', 'g')
    " src must not have trailing '\'.
    let src  = substitute(src, '\\$', '', 'g')
    " All characters must be encoded to system encoding.
    if s:need_trans
      let src  = iconv(src, &encoding, 'char')
      let dest = iconv(dest, &encoding, 'char')
    endif
    let cmd_exe = (&shell =~? 'cmd\.exe$' ? '' : 'cmd /c ')
    call system(cmd_exe . 'move /y ' . src  . ' ' . dest)
    return !v:shell_error
  endfunction
else
  function! s:move_exe() abort
    throw 'vital: System.File: move_exe(): your platform is not supported'
  endfunction
endif

" Move a file.
" Implemented by pure Vim script.
function! s:move_vim(src, dest) abort
  return !rename(a:src, a:dest)
endfunction

function! s:copy_dir(src, dest) abort
  if s:_has_copy_dir_exe()
    return s:copy_dir_exe(a:src, a:dest)
  else
    return s:copy_dir_vim(a:src, a:dest)
  endif
endfunction

" Copy a directory.
" Implemented by external program.
if s:is_unix
  function! s:copy_dir_exe(src, dest) abort
    if !s:_has_copy_dir_exe()
      return 0
    endif
    let [src, dest] = [a:src, a:dest]
    call system('cp -R ' . shellescape(src) . ' ' . shellescape(dest))
    return !v:shell_error
  endfunction
elseif s:is_windows
  function! s:copy_dir_exe(src, dest) abort
    if !s:_has_copy_dir_exe()
      return 0
    endif
    let src  = s:_shellescape_robocopy(a:src)
    let dest = s:_shellescape_robocopy(a:dest)
    call system('robocopy /e ' . src . ' ' . dest)
    return v:shell_error <# 8
  endfunction
  function! s:_shellescape_robocopy(path) abort
    let path = tr(a:path, '/', '\')
    let path = escape(path, '"')
    return '"' . path . '"'
  endfunction
else
  function! s:copy_dir_exe() abort
    throw 'vital: System.File: copy_dir_exe(): your platform is not supported'
  endfunction
endif

" Copy a file.
" Implemented by pure Vim script.
function! s:copy_dir_vim(src, dest) abort
  if isdirectory(a:src)
    for src in glob(s:Filepath.join(a:src, '*'), 1, 1)
      let basename = s:Filepath.basename(src)
      let dest = s:Filepath.join(a:dest, basename)
      if !s:copy_dir_vim(src, dest)
        return 0
      endif
    endfor
    return 1
  elseif filereadable(a:src)
    return s:copy_vim(a:src, a:dest)
  else " XXX: ???
    return 0
  endif
endfunction

if s:is_unix
  function! s:_has_copy_dir_exe() abort
    return executable('cp')
  endfunction
elseif s:is_windows
  function! s:_has_copy_dir_exe() abort
    return executable('robocopy')
  endfunction
else
  function! s:_has_copy_dir_exe() abort
    throw 'vital: System.File: copy_dir_exe(): '
    \   . 'your platform is not supported'
  endfunction
endif


" Copy a file.
" Dispatch s:copy_exe() or s:copy_vim().
function! s:copy(src, dest) abort
  if s:_has_copy_exe()
    return s:copy_exe(a:src, a:dest)
  else
    return s:copy_vim(a:src, a:dest)
  endif
endfunction

if s:is_unix
  function! s:_has_copy_exe() abort
    return executable('cp')
  endfunction
elseif s:is_windows
  function! s:_has_copy_exe() abort
    return 1
  endfunction
else
  function! s:_has_copy_exe() abort
    throw 'vital: System.File: _has_copy_exe(): your platform is not supported'
  endfunction
endif

" Copy a file.
" Implemented by external program.
if s:is_unix
  function! s:copy_exe(src, dest) abort
    if !s:_has_copy_exe()
      return 0
    endif
    let [src, dest] = [a:src, a:dest]
    call system('cp ' . shellescape(src) . ' ' . shellescape(dest))
    return !v:shell_error
  endfunction
elseif s:is_windows
  function! s:copy_exe(src, dest) abort
    if !s:_has_copy_exe()
      return 0
    endif
    let [src, dest] = [a:src, a:dest]
    let src  = substitute(src, '/', '\', 'g')
    let dest = substitute(dest, '/', '\', 'g')
    let cmd_exe = (&shell =~? 'cmd\.exe$' ? '' : 'cmd /c ')
    call system(cmd_exe . 'copy /y ' . src . ' ' . dest)
    return !v:shell_error
  endfunction
else
  function! s:copy_exe() abort
    throw 'vital: System.File: copy_exe(): your platform is not supported'
  endfunction
endif

" Copy a file.
" Implemented by pure Vim script.
function! s:copy_vim(src, dest) abort
  let ret = writefile(readfile(a:src, 'b'), a:dest, 'b')
  if ret == -1
    return 0
  endif
  return 1
endfunction

" mkdir() but does not throw an exception.
" Returns true if success.
" Returns false if failure.
function! s:mkdir_nothrow(...) abort
  try
    return call('mkdir', a:000)
  catch
    return 0
  endtry
endfunction


" Delete a file/directory.
if has('patch-7.4.1128')
  function! s:rmdir(path, ...) abort
    let flags = a:0 ? a:1 : ''
    let delete_flags = flags =~# 'r' ? 'rf' : 'd'
    let result = delete(a:path, delete_flags)
    if result == -1
      throw 'vital: System.File: rmdir(): cannot delete "' . a:path . '"'
    endif
  endfunction

elseif s:is_unix
  function! s:rmdir(path, ...) abort
    let flags = a:0 ? a:1 : ''
    let cmd = flags =~# 'r' ? 'rm -rf' : 'rmdir'
    let ret = system(cmd . ' ' . shellescape(a:path))
    if v:shell_error
      let ret = iconv(ret, 'char', &encoding)
      throw 'vital: System.File: rmdir(): ' . substitute(ret, '\n', '', 'g')
    endif
  endfunction

elseif s:is_windows
  function! s:rmdir(path, ...) abort
    let flags = a:0 ? a:1 : ''
    if &shell =~? 'sh$'
      let cmd = flags =~# 'r' ? 'rm -rf' : 'rmdir'
      let ret = system(cmd . ' ' . shellescape(a:path))
    else
      " 'f' flag does not make sense.
      let cmd = 'rmdir /Q'
      let cmd .= flags =~# 'r' ? ' /S' : ''
      let ret = system(cmd . ' "' . a:path . '"')
    endif
    if v:shell_error
      let ret = iconv(ret, 'char', &encoding)
      throw 'vital: System.File: rmdir(): ' . substitute(ret, '\n', '', 'g')
    endif
  endfunction

else
  function! s:rmdir(...) abort
    throw 'vital: System.File: rmdir(): your platform is not supported'
  endfunction
endif


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
