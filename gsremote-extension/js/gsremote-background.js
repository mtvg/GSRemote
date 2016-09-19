var gsr = {

	presentationWindowId: null,
	presentationTabId: null,
	presenterTabId: null,
	presenterWindowId: null,
	extraTabId: null,
	extraWindowId: null,
	nativeBridge: null,
	homeDirectory: "",
	inPresentation: false,
	initNextPresenter: false,
	currentExtra: null,
	currentExtras: [],


	init : function() {

		// Show the icon
		chrome.runtime.onInstalled.addListener(function() {
			// Replace all rules ...
			chrome.declarativeContent.onPageChanged.removeRules(undefined, function() {
			// With a new rule ...
			chrome.declarativeContent.onPageChanged.addRules([{
				conditions: [
					new chrome.declarativeContent.PageStateMatcher({
						pageUrl: { urlMatches: 'docs.google.com/[*/]?presentation/d' },
					})
				],
				// And shows the extension's page action.
				actions: [ new chrome.declarativeContent.ShowPageAction() ]
			}]);
		  });
		});  

		chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {

			if (request.action == "presentationurl") {
				gsr.initNextPresenter = true;
				chrome.windows.create({url:request.presenturl, focused:true, state:'fullscreen', type:'popup'}, function(newwindow) {
					gsr.presentationWindowId = newwindow.id;
					gsr.presentationTabId = newwindow.tabs[0].id;
					console.log('Setting presentation windowId: '+gsr.presentationWindowId);
				});
			}

			else if (request.action == "initpresentation") {
				if (gsr.initNextPresenter) {

					chrome.tabs.sendMessage(gsr.presentationTabId, {action: 'openpresenter'});
					setTimeout(function(){
						chrome.windows.update(gsr.presentationWindowId, {focused:true});
					}, 500);
					
				}
			}

			else if (request.action == "exitpresentation") {
				if (gsr.inPresentation) {
					chrome.windows.remove(gsr.presentationWindowId, gsr.catchError);
				}
			}

			else if (request.action == "opensettings") {
				chrome.tabs.create({url:'chrome://extensions/?id=bejldbalomejcoebpmifodlkokjckbbo'});
			}

			else if (request.action == "init" && gsr.initNextPresenter) {

				gsr.initNextPresenter = false;

				if (gsr.inPresentation) {
					chrome.windows.remove(sender.tab.windowId, gsr.catchError);
					return;
				}

				gsr.inPresentation = true;
				gsr.presenterTabId = sender.tab.id;
				gsr.presenterWindowId = sender.tab.windowId;

				console.log('Presenter tab opened');

				var bridge = chrome.runtime.connectNative('net.mtvg.gsremotehelper');
				bridge.onMessage.addListener(function(msg) {
					console.log('Message from native: ');
					console.log(msg);

					if (msg.action == 'extra') {
						if (msg.control) {
							chrome.tabs.sendMessage(gsr.extraTabId, {fromNative: msg});
							return;
						} 

						var extra = gsr.currentExtras[msg.extra];
						if (!extra) return;

						gsr.currentExtra = extra;
						var extraLink = chrome.extension.getURL('html/blank.html');

						if (extra.link.substr(0, 2)=='~/') {
							extra.link = 'file://'+gsr.homeDirectory+extra.link.substr(1);
						}

						if (extra.type == 'Y')
							extraLink = 'https://www.youtube.com/_forcedembed_/?youtube='+extra.link;
						if (extra.type == 'V')
							extraLink = chrome.extension.getURL('html/video.html')+'?url='+extra.link;
						if (extra.type == 'O')
							extraLink = 'https://www.youtube.com/_forcedembed_/?vimeo='+extra.link;
						else if (extra.type == 'U')
							extraLink = extra.link;

						if (gsr.extraWindowId) {
							chrome.tabs.update(gsr.extraTabId, {url:extraLink});
							setTimeout(function(){
								chrome.windows.update(gsr.extraWindowId, {focused:true});
							}, 0);
						} else {
							chrome.windows.create({url:extraLink, focused:true, state:'fullscreen', type:'popup'}, function(newwindow) {
								gsr.extraWindowId = newwindow.id;
								gsr.extraTabId = newwindow.tabs[0].id;
							});
						}


						try {
							gsr.nativeBridge.postMessage({action:'extra', label:extra.label, type:extra.type});
						} catch (e) {}
						

					} else if (msg.action == 'presentation') {
						gsr.currentExtra = null;

						chrome.windows.update(gsr.presentationWindowId, {focused:true});
						chrome.tabs.update(gsr.extraTabId, {url:chrome.extension.getURL('html/blank.html')});
						try {
							gsr.nativeBridge.postMessage({action:'presentation'});
						} catch (e) {}
					} else if (msg.action == 'laseron' || msg.action == 'laseroff') {
						chrome.tabs.sendMessage(gsr.presentationTabId, msg);
					} else {
						chrome.tabs.sendMessage(gsr.presenterTabId, {fromNative: msg});
					}

					if (msg.action == 'reqpresdata') {
						if (msg.home)
							gsr.homeDirectory = msg.home;
						chrome.windows.get(gsr.presentationWindowId, function(win){
							try {
								gsr.nativeBridge.postMessage({action:'windowpos', top:win.top, left:win.left});
							} catch (e) {}
						});
					}

					if (msg.action == 'ready' && gsr.currentExtra) {
						try {
							gsr.nativeBridge.postMessage({action:'extra', label:gsr.currentExtra.label, type:gsr.currentExtra.type});
						} catch (e) {}									
					}

					if (msg.player) {
						chrome.tabs.sendMessage(gsr.extraTabId, msg.player);
					}
				});
				bridge.onDisconnect.addListener(function() {
					console.log("Native bridge disconnected");
					chrome.tabs.remove(gsr.presenterTabId, gsr.catchError);
					if (gsr.extraWindowId)
						chrome.windows.remove(gsr.extraWindowId, gsr.catchError);
					chrome.windows.remove(gsr.presentationWindowId, gsr.catchError);
					gsr.extraWindowId = null;
					gsr.extraTabId = null;
					gsr.currentExtra = null;
					setTimeout(function(){gsr.inPresentation = false;}, 1000);
				});

				gsr.nativeBridge = bridge;
			} 

			else if (request.extras) {
				gsr.currentExtras = request.extras;
			}

			else if (request.toNative) {
				console.log('Message to native: ');
				console.log(request.toNative);
				try {
					gsr.nativeBridge.postMessage(request.toNative);
				} catch (e) {}
			} 

			else if (request.convertSVG) {
				try {
					gsr.nativeBridge.postMessage({action:'svg', svg:request.convertSVG});
				} catch (e) {}	
			} 

		});

		chrome.tabs.onRemoved.addListener(function(tabId, isWindowClosing) {
			if (tabId == gsr.presenterTabId || tabId == gsr.extraTabId) {
				console.log('Presenter tab closed');
				try {
					gsr.nativeBridge.postMessage({action:'killbridge'});
				} catch (e) {}
				if (gsr.extraWindowId)
					chrome.windows.remove(gsr.extraWindowId, gsr.catchError);
				chrome.windows.remove(gsr.presentationWindowId, gsr.catchError);
				gsr.extraWindowId = null;
				gsr.extraTabId = null;
				gsr.currentExtra = null;
				setTimeout(function(){gsr.inPresentation = false;}, 1000);
			}
		});

		chrome.pageAction.onClicked.addListener(function(tab) {
			if (gsr.inPresentation) {
				chrome.tabs.remove(gsr.presenterTabId, gsr.catchError);
				return;
			}

			chrome.tabs.sendMessage(tab.id, {action: "getpresentationurl"});
		});
	},

	catchError : function() {chrome.runtime.lastError;}
}

gsr.init();
