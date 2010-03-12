" tumble.vim - Tumble!
" Maintainer:   Felipe Morales <hel.sheep@gmail.com>
" Time-stamp: <Sun Feb  21 20:32:00 GMT-4 2009 Felipe Morales>
" Based in tumblr.vim by Travis Jeffery

"Exit quickly when:
"- this plugin was already loaded (or disabled)
"- when 'compatible' is set
if (exists("g:loaded_tumblr") && g:loaded_tumblr) || &cp
    finish
endif

let g:loaded_tumblr = 1

" Use Tumble to post the contents of the current buffer to tumblr.com
command! -range=% -nargs=? Tumble exec("py send_post(<f-line1>, <f-line2>, '<args>')")

python <<EOF
import vim
from urllib import *
import xml.etree.ElementTree

def send_post(rstart, rend, state="published"):
	tumblr_write = "http://www.tumblr.com/api/write"
	#these variables must be set for tumble! to work.
	email = vim.eval("g:tumblr_email")
	password = vim.eval("g:tumblr_password")
	tumblelog = vim.eval("g:tumblr_tumblelog")

	post_info = {"email" : email, "password" : password,  "group" : tumblelog, "state" : state, "type" : "regular", "format" : "markdown"}
	
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

	res = urlopen(tumblr_write, data)
EOF
