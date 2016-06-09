var gsr = {

		// init: add message listeners and call the appropriate function based on the request
		init : function() {

			if (window.top.document.body.getAttribute("gs-remote-js") != null) return;
			window.top.document.body.setAttribute("gs-remote-js", true);

		
			// Detects Speaker Notes tab
			if (window.top.location.pathname.startsWith('/presentation/') && window.top.location.pathname.endsWith('/present')) {
				if (window.top.document.getElementsByClassName("punch-viewer-speakernotes-page-next")[0])
					gsr.addPresenterJS();
				else 
				if (window.top.document.getElementsByClassName("punch-viewer-qanda-icon")[0])
					gsr.addPresentationJS();
			}

			// Detects Presentation tab
			if (window.top.location.pathname.startsWith('/presentation/') && window.top.location.pathname.endsWith('/edit')) {
				gsr.addEditJS();
			}
		
		},

		addEditJS : function() { 
			chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
				if (request.action == "getpresentationurl" && window.top.document.location.href.indexOf('/edit')>0) {
					chrome.runtime.sendMessage({action: "presentationurl", presenturl:window.top.document.location.href.split('/edit').join('/present')});
				}				
			});
		},
		
		addPresentationJS : function() {  
			chrome.runtime.sendMessage({action: "initpresentation"});
			chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
				if (request.action == "openpresenter") {
					var doc = window.top.document;
					var pres = doc.getElementsByClassName("punch-viewer-qanda-icon")[0];
					gsr.sendClick(doc, pres.parentNode.parentNode);

					var onKeyUp = function(e){
						if (e.keyCode == 27) {
							chrome.runtime.sendMessage({action: "exitpresentation"});
						}
					}
					window.addEventListener("keyup", onKeyUp, true);


					var script = document.createElement('style');
					script.textContent = "* {cursor: none;}";
					(document.head||document.documentElement).appendChild(script);

					var nav = doc.getElementsByClassName("punch-viewer-nav-floating")[0];
					if (nav)
						nav.style.display = 'none';
				}

				if (request.action == "showlaser") {
					var laser = doc.getElementsByClassName("punch-viewer-on-laser-icon")[0].parentNode;
					gsr.sendClick(doc, laser);
				}

				if (request.action == "hidelaser") {
					var laser = doc.getElementsByClassName("punch-viewer-off-laser-icon")[0].parentNode;
					gsr.sendClick(doc, laser);
				}
			});
		},
		
		addPresenterJS : function() {  

				var doc = window.top.document;

				var pageNumber = doc.getElementsByClassName('punch-viewer-speakernotes-text-header-container')[0];
				var nextSlide = doc.getElementsByClassName("punch-viewer-speakernotes-page-next")[0];
				var prevSlide = doc.getElementsByClassName("punch-viewer-speakernotes-page-previous")[0];
				var notes = doc.getElementsByClassName("punch-viewer-speakernotes-text-body")[0];

				var slidelist;
				setTimeout(function(){
					var drop = doc.getElementsByClassName("goog-flat-menu-button-dropdown")[0];
					gsr.sendClick(doc, drop.parentNode);
					setTimeout(function(){
						slidelist = doc.getElementsByClassName("goog-menu-vertical")[0];
						gsr.sendClick(doc, drop.parentNode);
					}, 100);
				}, 1000);

				var getPresentationData = function() {
					var obj = {action: "presdata"};

					var t = doc.title;
					obj.name = t.substring(t.indexOf(' - ')+3, t.lastIndexOf(' - '));

					var pagenums = pageNumber.textContent.match(/\d+/g);
					obj.count = pagenums[1];
					
					chrome.runtime.sendMessage({toNative: obj});
				}

				var getPage = function() {
					var obj = {};

					var pagenums = pageNumber.textContent.match(/\d+/g);
					obj.currentPage = pagenums[0];
					
					chrome.runtime.sendMessage({toNative: obj});
				}

				var getNotes = function() {
					var extras = [];
					var extraLabels = [];

					var re = /\[(youtube|url):([^:]+):([^\]]+)\]/g;
					var input = notes.textContent;
					var match;
					while ((match = re.exec(input)) != null) {
						extras.push({type:match[1], label:match[2], link:match[3]});
						extraLabels.push(match[2]);
					}

					chrome.runtime.sendMessage({extras: extras});
					chrome.runtime.sendMessage({toNative: {extras:extraLabels}});
				}

				pageNumber.addEventListener('DOMSubtreeModified', getPage);
				notes.addEventListener('DOMSubtreeModified', getNotes);

				chrome.runtime.sendMessage({action: "init"});
				chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {

						if (request.fromNative.action == "next")
							nextSlide.click();
						else if (request.fromNative.action == "prev")
							prevSlide.click();
						else if (request.fromNative.action == "goto") {	
							if (slidelist) {
								var el = slidelist.childNodes[request.fromNative.slide-1];
								gsr.sendClick(doc, el);
							}
						}
						else if (request.fromNative.action == "reqpresdata")
							getPresentationData();
						else if (request.fromNative.action == "ready") {
							getPage();
							getNotes();
						}

				});
		},

		sendClick(doc, el) {
			var evtd = doc.createEvent("MouseEvents");
			evtd.initEvent("mousedown", true, true);
			var evtu = doc.createEvent("MouseEvents");
			evtu.initEvent("mouseup", true, true);
			el.dispatchEvent(evtd);
			el.dispatchEvent(evtu);
		}
}

gsr.init();
