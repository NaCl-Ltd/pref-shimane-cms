// TODO namespace

function getElement(id) {
  if(document.getElementById) {
    return document.getElementById(id);
  } else if(document.all){
    return document.all[id];
  }
}

function initBannerAd() {
  console.log('test');
  var banner_image = getElement("header_banner_image");
  var link = getElement("header_banner_anchor");
  if(banner_image && link) {
  console.log('test');
    var bannerCount = Math.floor(Math.random() * BANNERS.length);
    banner_image.setAttribute('src', BANNERS[bannerCount].image);
    banner_image.setAttribute('alt', BANNERS[bannerCount].alt);
    link.setAttribute('href', BANNERS[bannerCount].url);
  }
}

$(function(){
  initBannerAd();
});
