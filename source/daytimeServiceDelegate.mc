
using Toybox.Background;
using Toybox.System;
using Toybox.Application as App;
import Toybox.Communications;
import Toybox.Lang;


(:background)
class daytimeServiceDelegate extends System.ServiceDelegate {
    var apiKey = App.getApp().getProperty("WeatherAPIKey");
    var location = App.getApp().getProperty("Location");

    
    function initialize() {
        ServiceDelegate.initialize();        
    }
    
    function onTemporalEvent() as Void {

        if (System.getDeviceSettings().phoneConnected &&
            apiKey.length() > 0 &&
            (null != location)) {
            makeRequest(location);
        }
    }

    function makeRequest(location as String) as Void {        
        var url = "https://api.weatherapi.com/v1/current.json?key=" + apiKey + "&q=" + location + "&aqi=no";

        var params = null;

        var options = {
            :methods => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => { "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, params, options, method(:onReceive));
    }

    function onReceive(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200) {
            if (data instanceof Lang.String && data.equals("Forbidden")) {
                var dict = { "msg" => "WRONG KEY" };
                Background.exit(dict);
            } else if(data instanceof Lang.Dictionary) {
                var current = data["current"];

                if(current == null) {
                    var dict = { "msg" => "No current data found" };
                    Background.exit(dict);
                }

                var condition = current.get("condition");

                if(condition == null) {
                    var dict = { "msg" => "No condition data found" };
                    Background.exit(dict);
                }
                
                var dict = {
                    "condition_code" => condition.get("code"),
                    "condition_text" => condition.get("text"),
                    "temperature" => current.get("temp_c"),
                    "msg" => "CURRENT",
                }; 

                Background.exit(dict);          
            }
        } else {
            var dict = { 
                "msg" => "FAIL",
                "error" => responseCode.toString()
            };

            Background.exit(dict);
        } 
    } 
}