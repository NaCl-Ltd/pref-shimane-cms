// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery.isloading.min
//= require jquery_ujs
//= require jquery.ui.all
//= require twitter/bootstrap
//= require bootstrap
//= require fancytree/jquery.fancytree.min

var Susanoo = {};

$(function() {
  // prevent disabled link
  $(document).on('click', "a[disabled=disabled]", function(e){
    e.preventDefault();
    return false;
  });

  // popup link
  $(document).on('click', "a[data-popup='true']", function(e){
    var href = $(this).attr('href');
    window.open(href, '')
    e.preventDefault();
  });

  /*
  $(document).on('ajax:beforeSend', "*[data-spinner]", function(e){
    var loading = $(this).attr("data-loading");
    var spinner = $(this).attr("data-spinner");
    if (loading && spinner) {
      $("#"+loading).hide();
      $("#"+spinner).show();
      e.stopPropagation();
    }
  });

  $(document).on('ajax:complete', "*[data-spinner]", function(){
    var loading = $(this).attr("data-loading");
    var spinner = $(this).attr("data-spinner");
    if (loading && spinner) {
      $("#"+spinner).hide();
      $("#"+loading).show();
    }
  });
  */
});


