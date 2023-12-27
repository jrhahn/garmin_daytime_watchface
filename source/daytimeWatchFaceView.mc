using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.WatchUi;
using Toybox.ActivityMonitor as Mon;
using Toybox.Application as App;
using Toybox.Math as Math;
using Toybox.Time;
import Toybox.Lang;



class daytimeWatchFaceView extends WatchUi.WatchFace {

    var sunRiseSet;
    var sunrise = 0;
    var sunset = 0;
    var is24Hour = true;
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
    	8 => imageLibRainy, // mist
		9 => imageLibClear // default
    };
    
	// Called every second
    function onPartialUpdate(dc) {
        var clockTime = Sys.getClockTime();

        if (
			(clockTime.hour == 0 && clockTime.min == 0 && clockTime.sec == 59) ||
			!sunriseIsInit
		) {
            sunrise = sunRiseSet.computeSunrise(true);
            sunset = sunRiseSet.computeSunrise(false);
            
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
    function onLayout(dc) as Void {
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
		        
		sunriseText = format("$1$:$2$$3$", [sunriseHH.format("%02d"), sunriseMM, sunriseAmPm]);
		sunsetText  = format("$1$:$2$$3$", [sunsetHH.format("%02d"), sunsetMM, sunsetAmPm]);        
    }
	
	private function updateHeartrateText() {   
    	var heartrateIterator = ActivityMonitor.getHeartRateHistory(null, true);
		var currentHeartrate = heartrateIterator.next().heartRate;
	
		if(currentHeartrate != Mon.INVALID_HR_SAMPLE) {
			heartrateText =  currentHeartrate.format("%d");
		}		
    } 
    
    private function getColor(
		isDayTime as Boolean,
		step as Number
	) as Number {
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
    }
    
    private function plotHeartrateGraph(
		dc, 
		originX as Number, 
		originY as Number, 
		sizeX as Number, 
		sizeY as Number, 
		duration as Number, 
		color as Number
	) {     	
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
    	    	
    	printHeartrateInPlot(dc, hrSampleMax, m_x, m_y, n_x, n_y, originX, originY);
    	printHeartrateInPlot(dc, hrSampleMin, m_x, m_y, n_x, n_y, originX, originY);
    }
    
    private function printHeartrateInPlot(
		dc,
		heartRateSample as Null or Toybox.ActivityMonitor.HeartRateSample,
		m_x as Float, 
		m_y as Number, 
		n_x as Float, 
		n_y as Number, 
		originX as Number, 
		originY as Number) as Void {
    
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
    	
    	/*if(lastMinute == clockTime.min) {
    		return;
    	}*/
    	
    	lastMinute = clockTime.min;
    
        var temperature = App.getApp().getProperty("weatherTemperature");
        sunRiseSet = new SunriseSunsetCalculator();
        
        var stepCount = Mon.getInfo().steps.toString();        
        var battery = Sys.getSystemStats().battery;	
        
        updateHeartrateText();           	
        	
        var typeWeatherCode = App.getApp().getProperty("weatherCode").toNumber();        
		var typeWeatherText = App.getApp().getProperty("weatherText");        
  
        dc.drawBitmap(0, 0, loadImage(typeWeatherCode));
        
        dc.setColor(colorMain, Gfx.COLOR_TRANSPARENT);
        dc.drawText(41, 27, Gfx.FONT_NUMBER_THAI_HOT, clockTime.hour.format("%02d"), Gfx.TEXT_JUSTIFY_LEFT); 
        dc.setColor(colorHighlight, Gfx.COLOR_TRANSPARENT);
        dc.drawText(41, 92, Gfx.FONT_NUMBER_THAI_HOT, clockTime.min.format("%02d"), Gfx.TEXT_JUSTIFY_LEFT);         

		// footprints
        dc.setColor(0xffffff, Gfx.COLOR_TRANSPARENT);              
        dc.drawBitmap(33, 180,  WatchUi.loadResource(Rez.Drawables.Footprints));		
        dc.drawText(55, 180, Gfx.FONT_SYSTEM_XTINY, stepCount, Gfx.TEXT_JUSTIFY_LEFT);

		// temperature
		dc.drawText(138, 180, Gfx.FONT_SYSTEM_XTINY, format("$1$°C", [temperature.format("%0.1f")]), Gfx.TEXT_JUSTIFY_CENTER); 
        
		// heartrate
        dc.drawBitmap(173, 184,  WatchUi.loadResource(Rez.Drawables.Heart));
        dc.drawText(190, 180, Gfx.FONT_SYSTEM_XTINY, heartrateText, Gfx.TEXT_JUSTIFY_LEFT);
                                 
        var isDayTime = false;
        var sunText = sunriseText;      
        if(isBefore(clockTime.hour, clockTime.min, sunsetHH, sunsetMM) &&
           isBefore(sunriseHH, sunriseMM, clockTime.hour, clockTime.min)) {
           sunText = sunsetText;
           isDayTime = true;
        }

		// weather
        dc.drawText(138, 200, Gfx.FONT_SYSTEM_XTINY, typeWeatherText, Gfx.TEXT_JUSTIFY_CENTER);

		// time sunset / sunrise
		dc.drawBitmap(95, 225,  WatchUi.loadResource(Rez.Drawables.Sunrise)); 		
        dc.drawText(138, 220, Gfx.FONT_SYSTEM_XTINY, sunText, Gfx.TEXT_JUSTIFY_CENTER);                        		
                
        // last 4 hours
        var colorHeartRate = getColor(isDayTime, 0);
        plotHeartrateGraph(dc, 160, 145, 70, 80, 4*3600, colorHeartRate);        
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
