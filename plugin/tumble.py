import vim
from urllib import urlencode, urlopen
import xml.etree.ElementTree

class Tumble(object):
	def __init__(self):
		self._eval_vars()

	def _get_proxy(self):
		if vim.eval('exists("g:tumblr_http_proxy")') == "1":
			return {"http": vim.eval("g:tumblr_http_proxy")}
		else:
			return {}
	
	def _eval_vars(self):
		self.user = vim.eval("g:tumblr_email")
		self.password = vim.eval("g:tumblr_password")
		self.site = vim.eval("g:tumblr_tumblelog")

	def set_user(self, email, password):
		vim.command("let g:tumblr_email = \"" + self.email + "\"")
		vim.command("let g:tumblr_password = \"" + self.password + "\"")
		self._eval_vars()

	def set_site(self, site):
		vim.command("let g:tumblr_tumblelog = \"" + self.site + "\"")
		self._eval_vars()
	
	def send_post(self, range_start, range_end, type="regular", state="published"):
		proxy = self._get_proxy()
		self._eval_vars()
		
		post_info = { "email": self.user, "password": self.password, 
				"state": state, "group": self.site,
				"type": type, "format": "markdown" }

		text = vim.current.buffer.range(int(range_start), int(range_end))
		
		if type == "regular":
			first_line = text[0]
			if len(text) > 1 and text[1].find("=") > -1:
					post_info["title"] = first_line
					post_info["body"] = "\n".join(text[2:])
			else:
					post_info["body"] = "\n".join(text[0:])
			
			#if post title is the same as the one from a previous post, it overwrites it.
			if "title" in post_info:
					try:
						tumble_read = urlopen("http://"+ self.site + "/api/read", proxies=proxy)
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
	
		elif type == "link":
			post_info["url"] = text[0]
			if len(text) > 1:
				post_info["name"] = text[1]
				if len(text) > 2:
					post_info["description"] = "\n".join(text[2:])

		data = urlencode(post_info)

		try:
			res = urlopen("http://www.tumblr.com/api/write", data, proxies=proxy)
			print "tumble.vim: Post sent successfully."
		except:
			print "tumble.vim: Couldn't send link."

	def send_link(self, range_start, range_end, state="publish"):
		self.send_post(range_start, range_end, "link", state)

	def list_tumbles(self, post_state="published"):
		proxy = self._get_proxy()
		self._eval_vars()

		tumblr_last_list = post_state

		vim.command("10new")
		vim.current.buffer[0] = "# " + self.site + " " + post_state
		vim.current.buffer.append("")

		sec_info = urlencode({"email" : self.user, "password" : self.password, "state" : post_state, "num" : "50", "filter" : "none"})
		try:
			data = urlopen("http://" + self.site + "/api/read", sec_info, proxies=proxy)
		except:
			print "tumble.vim: couldn't retrieve previous posts"
			return False
			
		text = data.read()
		posts = xml.etree.ElementTree.XML(text).find('posts')

		for post in posts.findall('post'):
			if post.get("type") == "regular":
				postdata = post.find("regular-title")
				if postdata != None:
					title = post.find("regular-title").text.encode("utf-8")
				else:
					title = "No title"
				vim.current.buffer.append(post.get("id") + "\t" + title)

		vim.command("setlocal nomodified")
		vim.command("setlocal nomodifiable")
		vim.command("noremap <buffer> <enter> :py tumble_plugin.edit_post(\"" +  tumblr_last_list + "\")<cr>")
		vim.command("noremap <buffer> <delete> :py tumble_plugin.delete_post(\"" +  tumblr_last_list + "\")<cr>")

	def edit_post(self, post_state):
		proxy = self._get_proxy()
		self._eval_vars()

		post_id = vim.current.line.split("\t")[0]
		post_title = vim.current.line.split("\t")[1]
		vim.command("bd!")
		vim.command("new tumble_" + post_id + ".mkd")

		header_tail = ""
		for count in range(len(post_title)):
				header_tail = header_tail + "="
		
		vim.current.buffer[0] = post_title
		vim.current.buffer.append(header_tail)
		vim.current.buffer.append("")

		post_info = { "filter" : "none", "id" : post_id }

		if post_state == "draft":
			post_info["state"] = "draft"
		post_info["email"] = self.user
		post_info["password"] = self.password

		data = urlopen("http://" + self.site + "/api/read", urlencode(post_info), proxies=proxy)
		post = xml.etree.ElementTree.XML(data.read()).find('posts').find('post')
		body = post.find("regular-body").text.encode("utf-8").split("\n")
		vim.current.buffer.append(body)
		vim.command("setlocal nomodified")

	def delete_post(self, post_state):
		proxy = self._get_proxy()
		self._eval_vars()

		post_id = vim.current.line.split("\t")[0]

		post_info = { "email" : self.user, "password" : self.password, "post-id" : post_id }

		try:
			call = urlopen("http://www.tumblr.com/api/delete", urlencode(post_info), proxies=proxy)
			print "tumble.vim: Post deleted."
		except:
			print "tumble.vim: Couldn't delete the post."
		self.list_tumbles(post_state)

tumble_plugin = Tumble()
