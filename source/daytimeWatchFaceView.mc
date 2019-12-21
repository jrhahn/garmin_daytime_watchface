using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.ActivityMonitor as Mon;
using Toybox.Application as App;
using Toybox.Math as Math;


class daytimeWatchFaceView extends WatchUi.WatchFace {

    var sunRiseSet;
    var sunrise = 0;
    var sunset = 0;
    var is24Hour = true;
    var showLeadingZero  = true;
    var heartrateText    = "";
    
    var sunriseHH   = 7;
    var sunriseMM   = 0;
    var sunriseAmPm = "";
    var sunsetHH    = 18;
    var sunsetMM    = 0;
    var sunsetAmPm  = "";
    
    var sunriseText = "";
    var sunsetText = "";  
    var sunriseIsInit = false;  
	
	var weatherMap = {
    	0 => new ImageLibraryWeatherClear(), // clear
    	1 => new ImageLibraryWeatherRainy(), // rain
    	2 => new ImageLibraryWeatherRainy(), // hail
    	3 => new ImageLibraryWeatherCloudy(), // cloudy
    	4 => new ImageLibraryWeatherCloudy(), // partly-cloudy
    	5 => new ImageLibraryWeatherRainy(), // thunderstorm
    	6 => new ImageLibraryWeatherRainy(), // sleet
    	7 => new ImageLibraryWeatherRainy(), // snow
    	8 => new ImageLibraryWeatherClear() // default
    };
    
    var weatherMapToText = {
    	0 => "clear",  // clear
    	1 => "rain", // rain
    	2 => "hail", // hail
    	3 => "cloudy", // cloudy
    	4 => "partly-cloudy", // partly-cloudy
    	5 => "thunderstorm", // thunderstorm
    	6 => "sleet", // sleet
    	7 => "snow",  // snow
    	8 => "default" // default
    };
	
	// Called every second
    function onPartialUpdate(dc) {
        var clockTime = Sys.getClockTime();

        if ((clockTime.hour == 0 && clockTime.min == 0 && clockTime.sec == 59)
                || !sunriseIsInit) {
            sunrise = sunRiseSet.computeSunrise(true) / 3600000;
            sunset = sunRiseSet.computeSunrise(false) / 3600000;
            
            calcSunriseSunset();
            
            sunriseIsInit = true;
        }
    }

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }
	
	function loadImage(clockTime, typeWeather) {    	
    	var hour = clockTime.hour;  	
    	var minute = clockTime.min;
    	
    	var val = (hour*60 + minute) / 5;    	
    	
    	var imageLibrary = weatherMap[typeWeather];
       	                
    	if(isBefore(hour, minute, sunriseHH-1, sunriseMM)) {
    	 	var index = val % imageLibrary.night.size();
    		return WatchUi.loadResource(imageLibrary.night[index]);
		}
		else if(isBefore(hour, minute, sunriseHH+1, sunriseMM)) {
    	 	var index = val % imageLibrary.sunrise.size();
    		return WatchUi.loadResource(imageLibrary.sunrise[index]);
    	} 
    	else if(isBefore(hour, minute, sunsetHH-1, sunsetMM)) {
    	 	var index = val % imageLibrary.day.size();
        	return WatchUi.loadResource(imageLibrary.day[index]);
    	}
    	else if(isBefore(hour, minute, sunsetHH+1, sunsetMM)) {
    	    var index = val % imageLibrary.sunset.size();
    		return WatchUi.loadResource(imageLibrary.sunset[index]);
		}
    	else {
     	 	var index = val % imageLibrary.night.size();
    		return WatchUi.loadResource(imageLibrary.night[index]);
		}
    }
	
	function calcSunriseSunset() {
        sunriseHH   = Math.floor(sunrise).toNumber();
        sunriseMM   = Math.floor((sunrise-Math.floor(sunrise))*60).toNumber();
        var sunriseAmPm = "";
        sunsetHH    = Math.floor(sunset).toNumber();
        sunsetMM    = Math.floor((sunset-Math.floor(sunset))*60).toNumber();
        var sunsetAmPm  = "";

        if (sunriseMM < 10) { sunriseMM = "0" + sunriseMM; }
        if (sunsetMM < 10) { sunsetMM = "0" + sunsetMM; }
        if (!is24Hour) {
            sunriseAmPm = sunriseHH < 12 ? "A" : "P";
            sunsetAmPm  = sunsetHH < 12 ? "A" : "P";
            sunriseHH   = sunriseHH == 0 ? sunriseHH : sunriseHH % 12;
            sunsetHH    = sunsetHH == 0 ? sunsetHH : sunsetHH % 12;
        }
        if (showLeadingZero) {
            sunriseText = Lang.format("$1$:$2$$3$", [sunriseHH.format("%02d"), sunriseMM, sunriseAmPm]);
            sunsetText  = Lang.format("$1$:$2$$3$", [sunsetHH.format("%02d"), sunsetMM, sunsetAmPm]);
        } else {
            sunriseText = Lang.format("$1$:$2$$3$", [sunriseHH, sunriseMM, sunriseAmPm]);
            sunsetText  = Lang.format("$1$:$2$$3$", [sunsetHH, sunsetMM, sunsetAmPm]);
        }
    }
	
	private function updateHeartrateText() {   
    	var heartrateIterator = ActivityMonitor.getHeartRateHistory(null, true);
		var currentHeartrate = heartrateIterator.next().heartRate;
	
		if(currentHeartrate != Mon.INVALID_HR_SAMPLE) {
			heartrateText =  currentHeartrate.format("%d");
		}		
    } 

    // Update the view
    function onUpdate(dc) {
        showLeadingZero = App.getApp().getProperty("ShowLeadingZero");
        sunRiseSet = new SunriseSunsetCalculator();
        
        var stepCount = Mon.getInfo().steps.toString();        
        var battery = Sys.getSystemStats().battery;	
        
        updateHeartrateText();           	
        	
        var typeWeather = App.getApp().getProperty("type_weather");
        var clockTime = System.getClockTime();
  
        dc.drawBitmap(0, 0, loadImage(clockTime, typeWeather));
        
        dc.setColor(0x3F888F, Gfx.COLOR_TRANSPARENT);
        dc.drawText(45, 20, Gfx.FONT_NUMBER_HOT, clockTime.hour.format("%02d"), Gfx.TEXT_JUSTIFY_LEFT); 
        dc.setColor(0xff0000, Gfx.COLOR_TRANSPARENT);
        dc.drawText(45, 80, Gfx.FONT_NUMBER_HOT, clockTime.min.format("%02d"), Gfx.TEXT_JUSTIFY_LEFT); 
        
        dc.setColor(0xffffff, Gfx.COLOR_TRANSPARENT);              
        dc.drawBitmap(40, 170,  WatchUi.loadResource(Rez.Drawables.Footprints));
        dc.drawText(60, 170, Gfx.FONT_SYSTEM_XTINY, stepCount, Gfx.TEXT_JUSTIFY_LEFT);
        
        dc.drawBitmap(160, 175,  WatchUi.loadResource(Rez.Drawables.Heart));
        dc.drawText(180, 170, Gfx.FONT_SYSTEM_XTINY, heartrateText, Gfx.TEXT_JUSTIFY_LEFT);
                
        dc.drawBitmap(88, 204,  WatchUi.loadResource(Rez.Drawables.Sunrise)); 
         
        var sunText = sunriseText;      
        if(isBefore(clockTime.hour, clockTime.min, sunsetHH, sunsetMM) &&
           isBefore(sunriseHH, sunriseMM, clockTime.hour, clockTime.min)) {
           sunText = sunsetText;
        }
        dc.drawText(125, 200, Gfx.FONT_SYSTEM_XTINY, sunText, Gfx.TEXT_JUSTIFY_CENTER);                
        dc.drawText(120, 170, Gfx.FONT_SYSTEM_XTINY, typeWeather, Gfx.TEXT_JUSTIFY_CENTER);        
        dc.drawText(120, 185, Gfx.FONT_SYSTEM_XTINY, weatherMapToText[typeWeather], Gfx.TEXT_JUSTIFY_CENTER);
    }
	
	function isBefore(timeAHH, timeAMM, timeBHH, timeBMM) {
    	if(timeAHH < timeBHH) {
    		return true;
    	}
    	
    	if((timeAHH == timeBHH) && (timeAMM < timeBMM)) {
    		return true;
    	}
    	
    	return false;
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }

}
