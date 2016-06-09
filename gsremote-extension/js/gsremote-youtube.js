var gs = {

		yid : "",

		// init: add message listeners and call the appropriate function based on the request
		init : function() {

			console.log("init "+window.location);

			if (window.top.document.body.getAttribute("gs-remote-js") != null) return;
			window.top.document.body.setAttribute("gs-remote-js", true);

			var paths = window.location.pathname.split('/');
			gs.yid = paths[paths.length-1];

			gs.addJS();
		
		},

		addJS : function() { 

			// Clear 404 document 
			var head = document.getElementsByTagName("head")[0];
			while (head.firstChild) head.removeChild(head.firstChild);
			var body = document.getElementsByTagName("body")[0];
			while (body.firstChild) body.removeChild(body.firstChild);

			// Document setup
			document.title = "Youtube Embed";
			var s = document.createElement("style");
			s.innerText = "* { margin:0;padding:0;border:0}html,body{height:100%;}";
			head.appendChild(s);

			// Add Youtube iframe
			var iframe = document.createElement("iframe");
			iframe.width = "100%";
			iframe.height= "100%";
			iframe.frameborder = "0";
			iframe.scrolling = "no";
			iframe.style = "display:block;border:0;";
			/*iframe.enablejsapi = "1";*/
			iframe.src = "https://www.youtube.com/embed/"+gs.yid+"?rel=0&controls=1&showinfo=0&autoplay=1&enablejsapi=1";
			iframe.id = "youtube-video";
			body.appendChild(iframe);


			// JS injection
			gs.injectScript(chrome.extension.getURL('js/gsremote-youtube-injection.js'));
			document.addEventListener('GSRYoutube_connectExtension', function(e) {
				console.log(e.detail);

				if (e.detail.status) {
					chrome.runtime.sendMessage({toNative: {'status':e.detail.status==1?'playing':'paused'}});
				}
			});


			// Setup Native bridge
			chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {

					if (request.fromNative.control == "pan") {
						gs.panVideo(request.fromNative.dir);
					}
					if (request.fromNative.control == "play") {
						gs.injectCode("player.playVideo();");
					}
					if (request.fromNative.control == "pause") {
						gs.injectCode("player.pauseVideo();");
					}

			});			

		},

		panVideo : function(dir) {
			var iframe = document.getElementById("youtube-video");
			if (!iframe) return;
			var iframedoc = iframe.contentWindow.document;
			var ctl360 = iframedoc.getElementsByClassName("ytp-webgl-spherical-control")[0];
			if (!ctl360) return;
			var evt = iframedoc.createEvent('MouseEvent');
			evt.initMouseEvent("mousedown", true, true, null, 0, 0, 0, dir=='right'?50:(dir=='left'?30:40), dir=='up'?30:(dir=='down'?50:40));
			var evtup = iframedoc.createEvent('MouseEvent');
			evtup.initMouseEvent("mouseup", true, true);
			ctl360.dispatchEvent(evt);setTimeout(function(){ctl360.dispatchEvent(evtup);}, 50);
		},

		injectScript : function(src) {
			var s = document.createElement('script');
			s.src = src;
			(document.head||document.documentElement).appendChild(s);
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
