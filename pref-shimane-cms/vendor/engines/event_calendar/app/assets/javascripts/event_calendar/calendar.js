
function setup(year, month, calendar, objxml) {

  var event_days = "";
  try{
    if (typeof objxml["events"]["event"]["date"] != 'undefined'){
      objxml["events"]["event"]["date"].match(/(\d\d\d\d)-(\d\d|\d)-(\d\d|\d)/);
      if (parseInt(RegExp.$1) == year && parseInt(RegExp.$2) == month) {
        event_days += month + "/" + RegExp.$3 + "/" + year + ",";
      }
    }else{
      for (i in objxml["events"]["event"]) {
        objxml["events"]["event"][i]["date"].match(/(\d\d\d\d)-(\d\d|\d)-(\d\d|\d)/);
        if (parseInt(RegExp.$1) == year && parseInt(RegExp.$2) == month) {
          event_days += month + "/" + RegExp.$3 + "/" + year + ",";
        }
      }
    }
  } catch ( error ){
  }

  var days = "";
  for (i=1; i<=31; i++){
    date = new RegExp(month + "/" + String(i) + "/" + year + ",");
    if ( !event_days.match(date) ){
      days += month + "/" + String(i) + "/" + year + ",";
    }
  }

  calendar.addRenderer(
    days,
    calendar.renderBodyCellRestricted
  );

  if ( event_days != '' ){
    return true;
  }else{
    return false;
  }
}

function handle_calendar(uri, calendar, objxml) {
  month = ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"];
  calendar.cfg.setProperty("MONTHS_LONG", month);
  calendar.cfg.setProperty("WEEKDAYS_SHORT", ["<div class='sunday'>日</div>", "月", "火", "水", "木", "金", "<div class='saturday'>土</div>"]);

  var dateSelected = function(type, args, obj) {
    String(args).match(/(\d\d\d\d),(\d\d|\d),(\d\d|\d)/);
    document.location = uri + RegExp.$1 + "/" + RegExp.$2 + "/" + RegExp.$3 + ".html";
  };
  calendar.selectEvent.subscribe(dateSelected, calendar, true);

  var beforeRender = function(type, args, obj) {
    var pagedate = this.cfg.getProperty("pagedate");
    mm = pagedate.getMonth() + 1;
    yyyy = pagedate.getYear();
    if ( yyyy < 1900 ) yyyy+=1900;
    flag_event = setup(yyyy, mm, calendar, objxml);
    var c_month = ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"];
    if ( flag_event ) c_month[mm-1] = "<a href=" + uri + yyyy + "/" + mm + "/>" + mm + "月" + "</a>";
    calendar.cfg.setProperty("MONTHS_LONG", c_month);
  };
  calendar.beforeRenderEvent.subscribe(beforeRender, calendar, true);

  calendar.render();
}

