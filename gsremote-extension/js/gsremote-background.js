var gsr = {

	presentationWindowId: null,
	presentationTabId: null,
	presenterTabId: null,
	extraTabId: null,
	extraWindowId: null,
	nativeBridge: null,
	inPresentation: false,
	initNextPresenter: false,
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

					chrome.windows.create({url:chrome.extension.getURL('html/blank.html'), focused:true, state:'fullscreen', type:'popup'}, function(newwindow) {
						gsr.extraWindowId = newwindow.id;
						gsr.extraTabId = newwindow.tabs[0].id;

						setTimeout(function(){
							chrome.windows.update(gsr.presentationWindowId, {focused:true});
						}, 1500);

						setTimeout(function(){
							chrome.tabs.sendMessage(gsr.presentationTabId, {action: 'openpresenter'});
						}, 500);

					});
					
				}
			}

			else if (request.action == "exitpresentation") {
				if (gsr.inPresentation) {
					chrome.windows.remove(gsr.presentationWindowId, gsr.catchError);
				}
			}

			else if (request.action == "init" && gsr.initNextPresenter) {

				gsr.initNextPresenter = false;

				if (gsr.inPresentation) {
					chrome.windows.remove(sender.tab.windowId, gsr.catchError);
					return;
				}

				gsr.inPresentation = true;
				gsr.presenterTabId = sender.tab.id;

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

						if (extra.type == 'youtube')
							chrome.tabs.update(gsr.extraTabId, {url:'https://www.youtube.com/_forcedembed_/'+extra.link});
						else if (extra.type == 'url')
							chrome.tabs.update(gsr.extraTabId, {url:extra.link});

						setTimeout(function(){
							chrome.windows.update(gsr.extraWindowId, {focused:true});
						}, 0);
						

					} else if (msg.action == 'presentation') {
						chrome.windows.update(gsr.presentationWindowId, {focused:true});
						chrome.tabs.update(gsr.extraTabId, {url:chrome.extension.getURL('html/blank.html')});
					} else {
						chrome.tabs.sendMessage(gsr.presenterTabId, {fromNative: msg});
					}
				});
				bridge.onDisconnect.addListener(function() {
					console.log("Native bridge disconnected");
					chrome.tabs.remove(gsr.presenterTabId, gsr.catchError);
					chrome.windows.remove(gsr.extraWindowId, gsr.catchError);
					chrome.windows.remove(gsr.presentationWindowId, gsr.catchError);
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

		});

		chrome.tabs.onRemoved.addListener(function(tabId, isWindowClosing) {
			if (tabId == gsr.presenterTabId || tabId == gsr.extraTabId) {
				console.log('Presenter tab closed');
				try {
					gsr.nativeBridge.postMessage({action:'killbridge'});
				} catch (e) {}
				chrome.windows.remove(gsr.extraWindowId, gsr.catchError);
				chrome.windows.remove(gsr.presentationWindowId, gsr.catchError);
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
