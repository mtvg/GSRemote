function setupHideCursor(doc) {
	var style = doc.createElement('style');
	style.textContent = "* {cursor: none;}";
	(doc.head||doc.documentElement).appendChild(style);

	var toMouse;
	doc.addEventListener('mousemove', function(e){
		style.textContent = "";
		clearTimeout(toMouse);
		toMouse = setTimeout(function(){
			style.textContent = "* {cursor: none;}";
		}, 2000);
	});
}

setupHideCursor(document);

var player = plyr.setup('#playerContainer')[0].plyr;

var video = {
	type: 'video',
	autoplay: true,
	volume: 10,
	controls: [],
	sources: [{}]
};

var index = document.location.search.indexOf('=');
if (index > 0) {
	var type = document.location.search.substring(1, index);
	var src = document.location.search.substr(index+1);

	if (type == 'youtube' || type == 'vimeo' || type == 'url') {
		if (type == 'url') 
			type = 'video/mp4';
		video.sources[0].type = type;
		video.sources[0].src = src;
		player.source(video);
	}
}

var initOnPlay = true;

var currentTime = 0;
var duration = 0;

//player.media.addEventListener('timeupdate', function(e){});
setInterval(function(){
	if (duration != player.media.duration || currentTime != player.media.currentTime) {
		duration = player.media.duration;
		currentTime = player.media.currentTime;
		dispatch({dur:duration, pos:currentTime});
	}
}, 1000);

player.media.addEventListener('pause', function(e){
	dispatch({status:'paused'});
});
player.media.addEventListener('playing', function(e){
	dispatch({status:'playing'});
	if (initOnPlay) {
		player.setVolume(10);

		var iframe = document.getElementsByTagName("iframe")[0];
		if (iframe)
			setupHideCursor(iframe.contentDocument);

		initOnPlay = false;
	}
	
});
player.media.addEventListener('seeked', function(e){
	dispatch({status:'seeked'});
});
player.media.addEventListener('seeking', function(e){
	dispatch({status:'seeking'});
});
player.media.addEventListener('volumechange', function(e){
	dispatch({muted:player.media.muted});
});
player.media.addEventListener('ready', function(e){
	player.setVolume(10);
});

function execCommand(cmd, arg) {
	if (cmd == "play" || cmd == "pause" || cmd == "restart" || cmd == "togglePlay" || cmd == "toggleMute") {
		player[cmd]();
	}
	if (cmd == "rewind" || cmd == "forward" || cmd == "seek") {
		player[cmd](arg);
	}
}

function dispatch(event) {
	document.dispatchEvent(new CustomEvent('PlayerEvents', {detail: event}));	
}

if (document.location.href.indexOf('www.youtube.com') == -1) {
	document.addEventListener('PlayerEvents', function(e) {
		chrome.runtime.sendMessage({toNative:{player: e.detail}});
	});	
	chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
		if (request.cmd)
			execCommand(request.cmd, request.arg);
	});
}