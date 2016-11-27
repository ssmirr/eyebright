var vjsvideo = null;
$(document).ready(function() {

  var display_video = function(){
    $('#iiif-video').empty();
    $('#currentType').empty();
    if (vjsvideo){
      vjsvideo.dispose();
      vjsvideo = null;
    }
    $.ajax({
      url: $('input#iiif-video-input')[0].value,
      cache: true,
      method: 'GET',
      success: function(data) {
        var video = document.createElement('video');
        video.id = 'dynamic-video';
        video.controls = true;
        video.poster = data.thumbnail['id'];
        video.className = "video-js vjs-default-skin vjs-fluid";
        data.tracks.forEach(function(track_info){
          var track = document.createElement('track');
          track.src = track_info.id;
          track.kind = track_info.kind;
          track.srclang = track_info.language;
          track.label = track_info.kind + ' (' + track_info.language + ')';
          $(video).append(track);
        });
        $('#iiif-video').append(video);
        vjsvideo = videojs('dynamic-video', {});
        var sources = [];
        data.sources.forEach(function(source){
          sources.push({type: source.type, src: source.id});
        });

        vjsvideo.src(sources);
        $('#currentType').html(vjsvideo.currentType());
        vjsvideo.play();
      }
    });
  }

  $('button#iiif-video-button').on('click', function () {
    display_video();
  });

  $('.info-json').on('click', function(event){
    $('input#iiif-video-input')[0].value = this.href;
    display_video();
    event.preventDefault();
  });

});
