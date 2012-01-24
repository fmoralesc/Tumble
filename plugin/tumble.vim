" tumble.vim - Tumble!
" Felipe Morales <hel.sheep@gmail.com>

"Exit quickly when:
"- this plugin was already loaded (or disabled)
"- when 'compatible' is set
if (exists("g:loaded_tumblr") && g:loaded_tumblr) || &cp
    finish
endif

let g:loaded_tumblr = 1

if !exists("g:tumblr_email")
	let g:tumblr_email = ""
endif
if !exists("g:tumblr_password")
	let g:tumblr_password = ""
endif
if !exists("g:tumblr_tumblelog")
	let g:tumblr_tumblelog = ""
endif
if !exists("g:tumblr_http_proxy")
	let g:tumblr_http_proxy = ""
endif

" We create a python object, tumble_plugin
pyfile <sfile>:p:h/tumble.py

" Use Tumble to post the contents of the current buffer to tumblr.com
command! -complete=customlist,TumbleCompleteArgs -range=% -nargs=? Tumble exec 'py tumble_plugin.send_post(<f-line1>, <f-line2>, state="<args>")'
" Use TumbleLink to post a link to tumblr.com
command! -range=% -nargs=? TumbleLink exec 'py tumble_plugin.send_link(<f-line1>, <f-line2>, state="<args>")'
" Use ListTumbrDrafts to list your drafts.
command! -complete=customlist,TumbleCompleteArgs -nargs=? TumblesList exec 'py tumble_plugin.list_tumbles("<args>")'

command! -nargs=* TumbleSetUser exec 'py tumble_plugin.set_user(<f-args>)'

command! -nargs=? TumbleSetSite exec 'py tumble_plugin.set_site("<args>")'

fun! TumbleCompleteArgs(A, L, P)
	return split("published draft")
endfun
