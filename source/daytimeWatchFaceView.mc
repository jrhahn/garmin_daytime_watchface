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
    
    var colorMain = 0x3F888F;
    var colorHighlight = 0xFF0000;
    
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
    
    var maxHeartRate = 185;
    var minHeartRate = 40;
    var doDrawAxes = false;
    
    var lastMinute = -1;
      
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
        
    	maxHeartRate = App.getApp().getProperty("maxHeartRate");
    	minHeartRate = App.getApp().getProperty("minHeartRate");         
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
        
        if(App.getApp().getProperty("IsSummerTime")) { sunsetHH += 1; }        	

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
    
    private function getColor(isDayTime, step) {
    	if(isDayTime) {
    		if(0 == step) {
    			return 0x3F888F;
			} else if(1 == step) {
				return 0x8FC8CF;
			} else {
				return 0xFFFFFF;
			}			
		}
		else {
			if(0 == step) {
    			return 0xFFFFFF;
			} else if(1 == step) {
				return 0xAAAAAA;
			} else {
				return 0x555555;
			}
		}
		
		return 0x555555;
    }
    
    private function plotHeartrateGraph(dc, originX, originY, sizeX, sizeY, duration, color) {     	  	
		var heartrateIterator = ActivityMonitor.getHeartRateHistory(null, true);
		var lastHRSample = heartrateIterator.next();			    	 			

		var timeHorizon = new Time.Duration(duration); 
		heartrateIterator = ActivityMonitor.getHeartRateHistory(timeHorizon, false);	
		
    	maxHeartRate = heartrateIterator.getMax();
    	minHeartRate = heartrateIterator.getMin();
    	
		dc.setColor(color, Gfx.COLOR_TRANSPARENT);
			
		if(doDrawAxes) {
	    	dc.drawLine(originX-1, originY, originX-1, originY-sizeY);
	    	dc.drawLine(originX-1, originY, originX+sizeX+1, originY);
	    }   
    	
    	var heartRateSamplesPerSecond = App.getApp().getProperty("heartRateSamplesPerSecond");
    	    	
//		y-axis
//    	y = mx + n//    	
//    	originY-sizeY = m * maxHeartRate + n
//    	originY = m * minHeartRate + n
//    	sizeY = m * (minHeartRate-maxHeartRate)
//      n = originY - m * minHeartRate 

		var m_y = 0;
		
		if(0 != minHeartRate - maxHeartRate) {
			m_y = sizeY / (minHeartRate - maxHeartRate).toFloat();
		}
		
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
    	var m_x = 1.0 * sizeX / timeHorizon.value().toFloat();    	
    	var n_x = originX - (lastHRSample.when.value()-timeHorizon.value()) * m_x;  
    	 
    	var numSamples = (heartRateSamplesPerSecond * duration / 3600 * sizeX).toNumber();
    	
    	var hrSampleMax = lastHRSample;
    	var hrSampleMin = lastHRSample;
    	
    	var prevX_ = -1;
    	var prevY_ = -1;

		for(var ii = 0; ii < numSamples ; ii++) {
			var sample_ = heartrateIterator.next();
    		
    		if(null == sample_) {
    			continue;
    		}
    		
    		var hr_ = sample_.heartRate;    		
    		var time_ = sample_.when.value();
    		
    		if(Mon.INVALID_HR_SAMPLE == hr_) {
    			continue;
    		}    		
    		
    		if(null == hrSampleMax || hrSampleMax.heartRate < hr_) {
    			hrSampleMax = sample_;
			}
			
			if(null == hrSampleMin || hrSampleMin.heartRate > hr_) {
    			hrSampleMin = sample_;
			}
    		
    		var posX_ = (m_x * time_ + n_x).toNumber(); 	    		    		
    		var posY_ = (m_y * hr_ + n_y).toNumber();
    		
    		if(prevX_ >= 0 && prevY_ >= 0) {
    			dc.setPenWidth(1);   
    			dc.drawLine(prevX_, prevY_, posX_, posY_);  
    		}
    		
    		prevX_ = posX_;
			prevY_ = posY_;
    		
    		dc.setPenWidth(2);   
    		dc.drawPoint(posX_, posY_);
    	}
    	    	
    	printHearRateInPlot(dc, hrSampleMax, m_x, m_y, n_x, n_y, originX, originY);
    	printHearRateInPlot(dc, hrSampleMin, m_x, m_y, n_x, n_y, originX, originY);
    }
    
    private function printHearRateInPlot(dc, heartRateSample, m_x, m_y, n_x, n_y, originX, originY) {
    
    	if(null != heartRateSample) {
    		var posX_ = (m_x * heartRateSample.when.value() + n_x).toNumber(); 
    		var posY_ = (m_y * heartRateSample.heartRate + n_y).toNumber();

			dc.setColor(colorMain, Gfx.COLOR_TRANSPARENT);
			dc.drawLine(originX+5, posY_, posX_, posY_);
    		
    		var heartrateText_ = heartRateSample.heartRate.format("%d"); 
    		dc.setPenWidth(2);   	
	        dc.setColor(colorHighlight, Gfx.COLOR_TRANSPARENT);	
			dc.drawText(originX, posY_ - 10, Gfx.FONT_SYSTEM_XTINY, heartrateText_, Gfx.TEXT_JUSTIFY_RIGHT);
		}
    }

    // Update the view
    function onUpdate(dc) {
    	var clockTime = System.getClockTime();
    	
    	if(lastMinute == clockTime.min) {
    		return;
    	}
    	
    	lastMinute = clockTime.min;
    
        var temperature = App.getApp().getProperty("weather_temp");
        showLeadingZero = App.getApp().getProperty("ShowLeadingZero");
        sunRiseSet = new SunriseSunsetCalculator();
        
        var stepCount = Mon.getInfo().steps.toString();        
        var battery = Sys.getSystemStats().battery;	
        
        updateHeartrateText();           	
        	
        var typeWeather = App.getApp().getProperty("type_weather").toNumber();
        
  
        dc.drawBitmap(0, 0, loadImage(typeWeather));
        
        dc.setColor(colorMain, Gfx.COLOR_TRANSPARENT);
        dc.drawText(45, 20, Gfx.FONT_NUMBER_HOT, clockTime.hour.format("%02d"), Gfx.TEXT_JUSTIFY_LEFT); 
        dc.setColor(colorHighlight, Gfx.COLOR_TRANSPARENT);
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
                
        // last 4 hours
        var colorHeartRate = getColor(isDayTime, 0);
        plotHeartrateGraph(dc, 150, 100, 60, 50, 4*3600, colorHeartRate);        
    }
	
	function isBefore(timeAHH, timeAMM, timeBHH, timeBMM) {
    	if(timeAHH.toNumber() < timeBHH.toNumber()) {
    		return true;
    	}
    	
    	if(timeAHH.toNumber() > timeBHH.toNumber()) {
    		return false;
    	}
    	
    	if(timeAMM.toNumber() < timeBMM.toNumber()) {
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
