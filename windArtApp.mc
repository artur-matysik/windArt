using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System;
using Toybox.Communications;
using Toybox.Lang as Lang;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Graphics as Gfx;


const URL = "https://api.data.gov.sg/v1/environment/wind-speed";

class windArtApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
       makeRequest(0);
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new windArtView("Starting ") ];
    }

   // set up the response callback function
   function onReceive(responseCode, data) {
   	   // parseResponse();
   	   
   	   System.println( data );
   	   
   	   var items = data["items"][0];
   	   var readings = items["readings"];
   	   var wind_at_station = 0;
   	   
   	   for (var i = 0; i < readings.size(); ++i) {
   	    var current_station = readings[i]["station_id"];
   	   	
   	   	if (current_station.equals("S107")) {
   	   		wind_at_station = readings[i]["value"] * 1.852; // convert from knots to kmh
   	   	} 
   	   }
   	    
   	   // truncate to 2 decimal places
   	   var windTruncated = (wind_at_station*10).toNumber().toFloat()/10; 
   	   wind_at_station = windTruncated.format("%.1f");

       Ui.switchToView(new windArtView("10min ago was \n" + wind_at_station + " kmh" ), null, Ui.SLIDE_IMMEDIATE);
   }
   
   function makeRequest(delay) {
       var url = URL;
       // Time
   	   var clockTime = System.getClockTime();
   	   var hour = clockTime.hour;
   	   var min = clockTime.min;
   	   
   	   // subtract 10min (required by API due to delay)
   	   if ( min - delay >= 10 ) {
   	   	 min = min - 10 - delay;
   	   } else {
   	     min = min + 50 - delay;
   	     hour = hour - 1; 
   	   }
   	   
   	   var timeString = Lang.format("$1$:$2$:$3$", [hour.format("%02d"), min.format("%02d"),clockTime.sec.format("%02d")]);
   	   
   	   // Date
   	   var date = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
	   var dateString = Lang.format("$1$-$2$-$3$", [date.year, date.month.format("%02d"), date.day.format("%02d")]);
	   // DateTime
	   var dateTime = (dateString+"T"+timeString); // format required by API
	   
	   System.println ( dateTime );
       var params = {
       	 "date_time" => dateTime
       };
       var options = {
         :method => Communications.HTTP_REQUEST_METHOD_GET,
         :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
       };
       var responseCallback = method(:onReceive);

       Communications.makeWebRequest(url, params, options, method(:onReceive));
  }
}