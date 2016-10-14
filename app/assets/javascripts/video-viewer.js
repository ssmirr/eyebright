$(document).ready(function() {

  var display_video = function(){
    $('#iiif-video').empty();
    $.ajax({
      url: $('input#iiif-video-input')[0].value,
      cache: true,
      method: 'GET',
      success: function(data) {
        var video = document.createElement('video');
        video.controls = true;
        video.poster = data.thumbnail['@id'];
        // console.log(data);
        data.sources.forEach(function(source){
          // console.log(source);
          if (video.canPlayType(source.type).length > 0 && video.src.length < 1) {
            video.src = data.id + '/' + source.width + ',' + source.height + '/default.' + source.format;
          }
        });
        $('#iiif-video').append(video);
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
