var gs = {

		yid : "",

		// init: add message listeners and call the appropriate function based on the request
		init : function() {

			console.log("init "+window.location);

			if (window.top.document.body.getAttribute("gs-remote-js") != null) return;
			window.top.document.body.setAttribute("gs-remote-js", true);

			var paths = window.location.pathname.split('/');
			gs.yid = paths[paths.length-1];

			gs.addPlyr();
		
		},

		addPlyr : function() { 

			// Clear 404 document 
			var head = document.getElementsByTagName("head")[0];
			while (head.firstChild) head.removeChild(head.firstChild);
			var body = document.getElementsByTagName("body")[0];
			while (body.firstChild) body.removeChild(body.firstChild);

			// Document setup
			document.title = "Youtube Embed";
			var s = document.createElement("style");
			s.innerText = "*{margin:0;padding:0;border:0}html,body{height:100%;background-color:black;}iframe,video{position:absolute;width:100%;height:100%}button,.plyr__controls{display:none;}";
			head.appendChild(s);

			body.innerHTML = '<video id="playerContainer"></video>';
			gs.injectScript(chrome.extension.getURL('js/plyr.js'), function(){
				gs.injectScript(chrome.extension.getURL('js/plyr-player.js'));
			});	

			document.addEventListener('PlayerEvents', function(e) {
				chrome.runtime.sendMessage({toNative:{player: e.detail}});
			});

			chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
				if (request.cmd)
					gs.injectCode("execCommand('"+request.cmd+"', "+request.arg+")");
			});
		},

		injectScript : function(src, onload) {
			var s = document.createElement('script');
			s.src = src;
			(document.head||document.documentElement).appendChild(s);
			if (onload)
				s.onload = onload;
			else
				s.onload = function() {s.parentNode.removeChild(s);};
		},

		injectCode : function(code) {
			var script = document.createElement('script');
			script.textContent = code;
			(document.head||document.documentElement).appendChild(script);
			script.parentNode.removeChild(script);
		}
		
}

gs.init();
