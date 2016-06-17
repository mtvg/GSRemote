var gsr = {

		// init: add message listeners and call the appropriate function based on the request
		init : function() {

			if (window.top.document.body.getAttribute("gs-remote-js") != null) return;
			window.top.document.body.setAttribute("gs-remote-js", true);

			window.top.document.addEventListener('Settings', function(e){
				chrome.runtime.sendMessage({action: "opensettings"});
			});

			window.top.document.getElementById('extensionStatus').innerHTML = 'The extension is successfully installed. <br/>To play local video files, please <a href="#" onclick="document.dispatchEvent(new CustomEvent(\'Settings\'));">allow access to file URLs in the extension settings</a>. ';
		
		}
}

gsr.init();
