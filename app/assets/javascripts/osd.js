document.addEventListener("DOMContentLoaded", function(event) {
  image_id = document.getElementById('openseadragon').getAttribute('data-iiif-id');
  osd_config = {
    id: 'openseadragon',
    prefixUrl: '../../osd/images/',
    preserveViewport: true,
    visibilityRatio: 1,
    minZoomLevel: 1,
    defaultZoomLevel: 1,
    sequenceMode: false,
    tileSources: [image_id]
  };
  OpenSeadragon(osd_config);

});
