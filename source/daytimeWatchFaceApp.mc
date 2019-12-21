using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

class daytimeWatchFaceApp extends Application.AppBase {
    hidden var view;
    hidden var sunRiseSet;


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
	
		sunRiseSet = new SunRiseSunSet();
    	
    	view = new daytimeWatchFaceView();
    	
        Background.registerForTemporalEvent(new Time.Duration(900)); // 15 min
    	
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
			if (msg.equals("FAIL") || msg.equals("WRONG KEY")) {
			} else if (msg.equals("CURRENTLY")) {
				App.getApp().setProperty("weather_temp", data.get("temp"));
			} else if (msg.equals("DAILY")) {
				App.getApp().setProperty("weather_temp_min", data.get("tempMin"));
				App.getApp().setProperty("weather_temp_max", data.get("tempMax"));
			}
			// rain, snow, sleet, wind, fog, cloudy
			var icon = data.get("icon");
			if (icon == null) {
				App.getApp().setProperty("type_weather", "8");
			}  else if (icon.equals("clear-day") || icon.equals("clear-night")) {
				App.getApp().setProperty("type_weather", 0);
			} else if (icon.equals("rain")) {
				App.getApp().setProperty("type_weather", 1);
			} else if (icon.equals("hail")) {
				App.getApp().setProperty("type_weather", 2);                
			} else if (icon.equals("cloudy")) {
				App.getApp().setProperty("type_weather", 3);
			} else if (icon.equals("partly-cloudy-day") || icon.equals("partly-cloudy-night")) {
				App.getApp().setProperty("type_weather", 4);
			} else if (icon.equals("thunderstorm")) {
				App.getApp().setProperty("type_weather", 5);
			} else if (icon.equals("sleet")) {
				App.getApp().setProperty("type_weather", 6);
			} else if (icon.equals("snow")) {
				App.getApp().setProperty("type_weather", 7);
			} else {
				App.getApp().setProperty("type_weather", 8);
			}
		}
    }

}