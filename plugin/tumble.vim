" tumble.vim - Tumble!
" Felipe Morales <hel.sheep@gmail.com>

"Exit quickly when:
"- this plugin was already loaded (or disabled)
"- when 'compatible' is set
if (exists("g:loaded_tumblr") && g:loaded_tumblr) || &cp
    finish
endif

let g:loaded_tumblr = 0

" Use Tumble to post the contents of the current buffer to tumblr.com
command! -range=% -nargs=? Tumble exec('py tumble_send_post(<f-line1>, <f-line2>, "<args>")')
" Use TumbleLink to post a link to tumblr.com
command! -range=% -nargs=? TumbleLink exec('py tumble_send_link(<f-line1>, <f-line2>)')
" Use ListTumbrDrafts to list your drafts.
command! -nargs=? ListTumbles exec('py list_tumbles("<args>")')

python <<EOF
import vim
from urllib import *
import xml.etree.ElementTree

tumblr_write_api = "http://www.tumblr.com/api/write"

def tumble_send_link(rstart, rend):
	email = vim.eval("g:tumblr_email")
	password = vim.eval("g:tumblr_password")
	tumblelog = vim.eval("g:tumblr_tumblelog")
	post_info = {"email" : email, "password" : password,  "group" : tumblelog, "type" : "link"}

	text = vim.current.buffer.range(int(rstart), int(rend))
	post_info["url"] = text[0]
	print post_info["url"]
	if len(text) > 1:
		post_info["name"] = text[1]
		print 
		if len(text) > 2:
			post_info["description"] = "\n".join(text[2:])

	data = urlencode(post_info)
	
	try:
		res = urlopen(tumblr_write_api, data)
		print "tumble.vim: Link sent successfully."
		return True
	except:
		print "tumble.vim: Couldn't post link to tumblr.com"
		return False

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
			try:
				tumble_read = urlopen("http://"+ tumblelog + "/api/read")
			except:
				print "tumble.vim: couldn't receive posts data."

			if tumble_read:
				posts = xml.etree.ElementTree.XML(tumble_read.read()).find('posts')

				for post in posts.findall('post'):
					if post.get("type") == "regular":
						titledata = post.find("regular-title")
						if titledata != None:
							if titledata.text.find(post_info["title"]) > -1:
								post_info["post-id"] = post.get("id")
	
	data = urlencode(post_info)

	try:
		res = urlopen(tumblr_write_api, data)
		print "tumble.vim: Post sent successfully."
		return True
	except:
		print "tumble.vim: Couldn't post to tumblr.com"
		return False

def list_tumbles(post_state="published"):
	email = vim.eval("g:tumblr_email")
	password = vim.eval("g:tumblr_password")
	tumblelog = vim.eval("g:tumblr_tumblelog")

	tumblr_last_list = post_state

	vim.command("normal ggdG")
	vim.command("set filetype=mkd")
	vim.current.buffer[0] = "#" + tumblelog + " " + post_state
	vim.current.buffer.append("")

	sec_info = urlencode({"email" : email, "password" : password, "state" : post_state, "num" : "50", "filter" : "none"})
	data = urlopen("http://" + tumblelog + "/api/read", sec_info)
	text = data.read()
	posts = xml.etree.ElementTree.XML(text).find('posts')

	for post in posts.findall('post'):
		if post.get("type") == "regular":
				title = post.find("regular-title").text.encode("utf-8")
				vim.current.buffer.append(post.get("id") + "\t" + title)
 	vim.command("set nomodified")
	vim.command("map <enter> :py edit_post(\"" +  tumblr_last_list + "\")<cr>")
	vim.command("map <delete> :py delete_post(\"" +  tumblr_last_list + "\")<cr>")

def edit_post(tumblr_last_list):
	email = vim.eval("g:tumblr_email")
	password = vim.eval("g:tumblr_password")
	tumblelog = vim.eval("g:tumblr_tumblelog")

	post_id = vim.current.line.split("\t")[0]
	post_title = vim.current.line.split("\t")[1]
	vim.command("set modified")
	vim.command("normal ggjdG")

	header_tail = ""
	for count in range(len(post_title)):
			header_tail = header_tail + "="
	
	vim.current.buffer[0] = post_title
	vim.current.buffer.append(header_tail)
	vim.current.buffer.append("")

	post_info = { "filter" : "none", "id" : post_id }

	if tumblr_last_list == "draft":
		post_info["email"] = email
		post_info["password"] = password
		post_info["state"] = "draft"

	data = urlopen("http://" + tumblelog + "/api/read", urlencode(post_info))
	post = xml.etree.ElementTree.XML(data.read()).find('posts').find('post')
	body = post.find("regular-body").text.encode("utf-8").split("\n")
	vim.current.buffer.append(body)

def delete_post(tumblr_last_list):
	email = vim.eval("g:tumblr_email")
	password = vim.eval("g:tumblr_password")

	post_id = vim.current.line.split("\t")[0]

	post_info = { "email" : email, "password" : password, "post-id" : post_id }

	try:
		call = urlopen("http://www.tumblr.com/api/delete", urlencode(post_info))
		print "tumble.vim: Post deleted."
	except:
		print "tumble.vim: Couldn't delete the post."
	list_tumbles(tumblr_last_list)
EOF
