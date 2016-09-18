document.addEventListener("DOMContentLoaded", function(event) {
  var image_id = document.getElementById('openseadragon').getAttribute('data-iiif-id');
  var url_params = new URLSearchParams(window.location.search);
  var eyebright_mode;
  if (url_params.has('eyebright_mode')) {
    eyebright_mode = url_params.get('eyebright_mode');
  } else {
    eyebright_mode = 'default';
  }
  console.log(eyebright_mode);
  osd_config = {
    id: 'openseadragon',
    prefixUrl: '../../osd/images/',
    preserveViewport: true,
    visibilityRatio: 1,
    minZoomLevel: 1,
    defaultZoomLevel: 1,
    sequenceMode: false,
    tileSources: [image_id],
    eyebright_mode: eyebright_mode
  };
  OpenSeadragon(osd_config);

});
