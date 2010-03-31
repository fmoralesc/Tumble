" tumble.vim - Tumble!
" Maintainer:   Felipe Morales <hel.sheep@gmail.com>
" Time-stamp: Tue, 30 Mar 2010 18:38:44 -0300
" Based in tumblr.vim by Travis Jeffery

"Exit quickly when:
"- this plugin was already loaded (or disabled)
"- when 'compatible' is set
if (exists("g:loaded_tumblr") && g:loaded_tumblr) || &cp
    finish
endif

let g:loaded_tumblr = 1

" Use Tumble to post the contents of the current buffer to tumblr.com
command! -range=% -nargs=? Tumble exec('py tumble_send_post(<f-line1>, <f-line2>, "<args>")')

python <<EOF
import vim
from urllib import *
import xml.etree.ElementTree

tumblr_write_api = "http://www.tumblr.com/api/write"

def tumble_send_post(rstart, rend, state="publish"):
	#these variables must be set for tumble! to work.
	#they are initialized here so we can change them on the fly (useful when we can want to post to several blogs.).
	email = vim.eval("g:tumblr_email")
	password = vim.eval("g:tumblr_password")
	tumblelog = vim.eval("g:tumblr_tumblelog")

	#load the basic info
	post_info = {"email" : email, "password" : password,  "group" : tumblelog, "type" : "regular", "format" : "markdown"}
	
	#state can be "published" or "draft". we want to make sure it is one of them.
	if state == "publish":
			post_info["state"] = "published"
	elif state == "draft":
			post_info["state"] = state

	#if the first buffer line is a setext style h1 title, it grabs it as a title for the post in tumblr.
	text = vim.current.buffer.range(int(rstart), int(rend))
	first_line = text[0]
	if len(text) > 1 and text[1].find("=") > -1:
			post_info["title"] = first_line
			post_info["body"] = "\n".join(text[2:])
	else:
			post_info["body"] = "\n".join(text[0:])
	
	#if post title is the same as the one from a previous post, it overwrites it.
	if "title" in post_info:
			tumble_read = urlopen("http://"+ tumblelog + "/api/read")
			posts = xml.etree.ElementTree.XML(tumble_read.read()).find('posts')

			for post in posts.findall('post'):
				if post.get("type") == "regular" and post.find("regular-title").text.find(post_info["title"]) > -1:
						post_info["post-id"] = post.get("id")
	
	data = urlencode(post_info)

	try:
		res = urlopen(tumblr_write_api, data)
	except:
		print "tumble.vim: Couldn't post to tumblr.com"
EOF
