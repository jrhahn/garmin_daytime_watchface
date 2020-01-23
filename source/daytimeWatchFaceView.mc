using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.ActivityMonitor as Mon;
using Toybox.Application as App;
using Toybox.Math as Math;
using Toybox.Time;


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
	
    var imageLibClear = new ImageLibraryWeatherClear();
    var imageLibRainy = new ImageLibraryWeatherRainy();
    var imageLibCloudy = new ImageLibraryWeatherCloudy();
    
    const maxHeartRate = 185;
	const minHeartRate = 40;
    
//    var heartRateMeasurementsValues = new [sizeXAxis];
//    var heartRateMeasurementsTimestamps = new [sizeXAxis];
//    var heartRateMeasurementsIndex = 0;
    
    var weatherMap = {
    	0 => imageLibClear,  // clear
    	1 => imageLibRainy, // rain
    	2 => imageLibRainy, // hail
    	3 => imageLibCloudy, // cloudy
    	4 => imageLibCloudy, // partly-cloudy
    	5 => imageLibRainy, // thunderstorm
    	6 => imageLibRainy, // sleet
    	7 => imageLibRainy,  // snow
    	8 => imageLibClear // default
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
    	8 => "" // default
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
	
	function loadImage(typeWeather) { 
        var clockTime = Sys.getClockTime();   	
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
		
//		heartrateIterator = ActivityMonitor.getHeartRateHistory(sizeXAxis, false);	
//
//		for(var i = 0; i < sizeXAxis; i++) {
//			heartRateMeasurementsValues[i] = heartrateIterator.next().heartRate;
//		}			
//						
//	    heartRateMeasurementsValues[sizeXAxis-1] = currentHeartrate;	
		
//		// shift
//		for(var i = 0; i < sizeXAxis-1; i++) {
//			heartRateMeasurementsValues[i] = heartRateMeasurementsValues[i+1];
//		}			
//						
//	    heartRateMeasurementsValues[sizeXAxis-1] = currentHeartrate;
    } 
    
    private function plotHeartrateGraph(dc, originX, originY, sizeX, sizeY, isDayTime) { 
    	// todo make color time dependent     		
		var heartrateIterator = ActivityMonitor.getHeartRateHistory(null, true);
		var lastHRSample = heartrateIterator.next();
		
		var timeHorizon = new Time.Duration(4*3600); // last 4 hours
		heartrateIterator = ActivityMonitor.getHeartRateHistory(timeHorizon, false);	
    	
    	if(isDayTime) {
    		dc.setColor(0x112277, Gfx.COLOR_TRANSPARENT);
		}
		else {
			dc.setColor(0xFFFFFF, Gfx.COLOR_TRANSPARENT);
		}
			
    	dc.drawLine(originX-1, originY, originX-1, originY-sizeY);
    	dc.drawLine(originX-1, originY, originX+sizeX+1, originY);
    	    	
//		y-axis
//    	y = mx + n//    	
//    	originY-sizeY = m * maxHeartRate + n
//    	originY = m * minHeartRate + n
//    	sizeY = m * (minHeartRate-maxHeartRate)
//      n = originY - m * minHeartRate 

    	var m_y = sizeY / (minHeartRate - maxHeartRate).toFloat();
    	var n_y = originY - m_y * minHeartRate;
    	
    	// x-axis
    	// y = mx+n
    	// I. originX = (last-timeHorizon)*m + n
    	// II originX+sizeXAxis = last*m + n
    	// --> sizeXAxis = timeHorizon * m
    	// --> m = sizeXAxis / timeHorizon
    	// --> n = originX + (timeHorizon-last)*m 
    	// --> n = originX + sizeXAxis - last * sizeXAxis / timeHorizon
    	// --> n = originX + sizeXAxis - first * sizeXAxis / timeHorizon
    	// --> n = originX + sizeXAxis - (last-timeHz) * sizeXAxis / timeHorizon
    	var m_x = sizeX / timeHorizon.value().toFloat();    	
    	var n_x = originX - (lastHRSample.when.value()-timeHorizon.value()) * m_x;
    	//var n_x = originX + sizeX *( 1 - lastHRSample.when.value() / timeHorizon.value().toFloat());
//    	var n_x = originX + sizeX - (lastHRSample.when.value();
    	    	
    	for(var i=0; i < sizeX; i++) {  
    		var sample_ = heartrateIterator.next();
    		
    		if(null == sample_) {
    			continue;
    		}
    		
    		var hr_ = sample_.heartRate;
    		var time_ = sample_.when.value();
    		
    		var posX_ = m_x * time_ + n_x;
    		
    		System.println("n_x: " + n_x);
    		System.println("time_: " + time_);
    		System.println("m_x: " + m_x);
    		System.println("pos_x: " + posX_);
    		System.println("time horizon: " + timeHorizon.value());
			System.println("last: " + lastHRSample.when.value());
    		
    		if(Mon.INVALID_HR_SAMPLE == hr_) {
    			continue;
    		}
    		
    		var posY_ = m_y * hr_ + n_y;
//            dc.setColor(0x3F888F-sizeXAxis+i, Gfx.COLOR_TRANSPARENT);
    		dc.drawCircle(posX_.toNumber(), posY_.toNumber(), 1);
    	}
    }

    // Update the view
    function onUpdate(dc) {
        var temperature = App.getApp().getProperty("weather_temp");
        showLeadingZero = App.getApp().getProperty("ShowLeadingZero");
        sunRiseSet = new SunriseSunsetCalculator();
        
        var stepCount = Mon.getInfo().steps.toString();        
        var battery = Sys.getSystemStats().battery;	
        
        updateHeartrateText();           	
        	
        var typeWeather = App.getApp().getProperty("type_weather").toNumber();
        var clockTime = System.getClockTime();
  
        dc.drawBitmap(0, 0, loadImage(typeWeather));
        
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
         
        var isDayTime = false;
        var sunText = sunriseText;      
        if(isBefore(clockTime.hour, clockTime.min, sunsetHH, sunsetMM) &&
           isBefore(sunriseHH, sunriseMM, clockTime.hour, clockTime.min)) {
           sunText = sunsetText;
           isDayTime = true;
        }
        dc.drawText(125, 200, Gfx.FONT_SYSTEM_XTINY, sunText, Gfx.TEXT_JUSTIFY_CENTER);                
        dc.drawText(120, 170, Gfx.FONT_SYSTEM_XTINY, Lang.format("$1$°C", [temperature.format("%0.1f")]), Gfx.TEXT_JUSTIFY_CENTER); 
        dc.drawText(120, 185, Gfx.FONT_SYSTEM_XTINY, weatherMapToText[typeWeather], Gfx.TEXT_JUSTIFY_CENTER);
        
        plotHeartrateGraph(dc, 150, 100, 60, 50, isDayTime);
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
