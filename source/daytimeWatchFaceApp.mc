using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

class daytimeWatchFaceApp extends App.AppBase {
    hidden var view;
    hidden var sunRiseSet;

	var counter = 0;


    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
	
		sunRiseSet = new SunriseSunsetCalculator();
    	
    	view = new daytimeWatchFaceView();
    	
        Background.registerForTemporalEvent(new Time.Duration(300)); // 15 min
    	
        if( Toybox.WatchUi has :WatchFaceDelegate ) {
            return [view, new daytimeDelegate()];
        } 
           
        return [view];
	}
	
	function getServiceDelegate() {
        return [new daytimeServiceDelegate()]; 
    }
	
	function onBackgroundData(data) {
		if (data instanceof Dictionary) {
			
			var msg = data.get("msg");
			if (msg.equals("FAIL"))  {
				App.getApp().setProperty("weatherText", "Fail: !" + data.get("error") + " " + counter);
			}
			else if (msg.equals("WRONG KEY")) {
				App.getApp().setProperty("weatherText", "Wrong key");
			} else if (msg.equals("CURRENT")) {
				App.getApp().setProperty("weatherTemperature", data.get("temperature"));
			
				// source: https://www.weatherapi.com/docs/conditions.json
				var code = data.get("condition_code").toLong();
				if (code == null) {
					App.getApp().setProperty("weatherCode", 8);
				}  else if (code == 1000) { // clear, updated
					App.getApp().setProperty("weatherCode", 0);
				} else if (code == 1063 || code == 1240 || code == 1243 || code == 1246 || code == 1150 || code == 1153 || code == 1168 || code == 1171 || code == 1180 || code == 1183 || code == 1186 || code == 1189 || code == 1192 || code == 1195 || code == 1198 || code == 1201) { // updated, rain 
					App.getApp().setProperty("weatherCode", 1);
				} else if (code == 1237|| code == 1261 || code == 1264) { // hail, updated 
					App.getApp().setProperty("weatherCode", 2);                
				} else if (code == 1006) { // cloudy, updated
					App.getApp().setProperty("weatherCode", 3);
				} else if (code == 1003 || code == 1009) { // partly cloudy, updated
					App.getApp().setProperty("weatherCode", 4);
				} else if (code == 1087 || code == 1273 || code == 1276 || code == 1279 || code == 1282) { // thunderstorm, updated 
					App.getApp().setProperty("weatherCode", 5);
				} else if (code == 1069 || code == 1072 || code == 1204 || code == 1207 || code == 1249 || code == 1252) { // sleet, updated
					App.getApp().setProperty("weatherCode", 6);
				} else if (code == 1066 || code == 1255 || code == 1258 || code == 1114 || code == 1117 || code == 1210 || code == 1213|| code == 1216 || code == 1219 || code == 1222 || code == 1225) { // snow, updated
					App.getApp().setProperty("weatherCode", 7);
				} else if (code == 1135 || code == 1030  || code == 1147) { // fog, updated
					App.getApp().setProperty("weatherCode", 8);
				} else {
					App.getApp().setProperty("weatherCode", 9);
				} 

				var weatherText = data.get("condition_text");
				if(weatherText != null) {
					App.getApp().setProperty("weatherText", weatherText);
				}
			}
	
	
		}

		counter++;
    }


}