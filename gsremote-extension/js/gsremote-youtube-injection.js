function messageToExtension(msg) {
    document.dispatchEvent(new CustomEvent('GSRYoutube_connectExtension', {
        detail: msg
    }));
}

var tag = document.createElement('script');
tag.src = "https://www.youtube.com/iframe_api";
var firstScriptTag = document.getElementsByTagName('script')[0];
firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);


var player;
function onYouTubeIframeAPIReady() {

	messageToExtension("onYouTubeIframeAPIReady");
	
	player = new YT.Player('youtube-video', {

		events: {
			'onReady': onPlayerReady,
			'onStateChange': onPlayerStateChange
		}
	});

}

function onPlayerReady(e) {
	messageToExtension("onPlayerReady");
}

function onPlayerStateChange(e) {
	messageToExtension({'status':e.data});
}