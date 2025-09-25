using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application.Storage as Stor;
using Toybox.Math as Math;
using Toybox.System as Sys;

var g_bpmCalculator = null;
var g_bpmHistory = null;

class BPMApp extends App.AppBase {

    //! onStart() is called on application start up
    function onStart(state) {
    }

    //! onStop() is called when your application is exiting
    function onStop(state) {
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new BPMView(), new BPMDelegate() ];
    }

}

class BPMView extends Ui.View
{

    hidden var m_isMono = false;

    function onLayout(dc)
    {
        g_bpmCalculator = new BPMCalculator();
        g_bpmCalculator.initialize();
        
        g_bpmHistory = Stor.getValue("bpmHistory");
        if (g_bpmHistory == null) {
            g_bpmHistory = [];
        }
        
        var deviceId = Ui.loadResource(Rez.Strings.DeviceId);
        // only octo watches are mono... at least for now
        m_isMono = deviceId != null && deviceId.equals("octo");
    }

    function onUpdate(dc as Gfx.Dc)
    {   
        var posShift = 0;
        if (m_isMono == true) {
            posShift = 30;
        }
        
        var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;
        var h = Gfx.getFontHeight(Gfx.FONT_MEDIUM);
        var r = x;
        if (x >= y) {
            r = y;
        }
        var s = r / 7;
        var p = 2;
            
        // clear display
        dc.setColor( Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK );
        dc.clear();
        dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
    
        var consistency = g_bpmCalculator.getConsistencyInfo();
        if (consistency[0] > 0) {
            // -- display elapsed time
            // convert secs to mins and secs
            var min = 0;
            var sec = g_bpmCalculator.getSecsElapsed();
            while (sec > 59) {
                min += 1;
                sec -= 60;
            }
            // format and draw time
            var timerString = "" + min.format("%d") + ":" + sec.format("%02d");
            dc.drawText( x - posShift, h, Gfx.FONT_MEDIUM, timerString, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
            
            // -- display confidence info
            var validThreshold = g_bpmCalculator.getValidThreshold();
            var yellowThreshold = Math.floor(validThreshold / 2.0);
            
            // configure confidence colors
            if (m_isMono == true) {
                dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
            } else if (consistency[1] < yellowThreshold) {
                dc.setColor( Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT );
            } else if (consistency[1] >= yellowThreshold && consistency[1] < validThreshold) {
                dc.setColor( Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT );
            } else {
                dc.setColor( Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT );
            }
            // build confidence string
            //var bpmConfidenceString = "|";
            //for (var i = 0; i < validThreshold; i++) {
            //    if (i < consistency[1]) {
            //        bpmConfidenceString = bpmConfidenceString + "|";
            //    } else {
            //        bpmConfidenceString = bpmConfidenceString + "-";
            //    }
            //}
            //if (consistency[1] >= validThreshold) {
            //    bpmConfidenceString = bpmConfidenceString + " VALID";
            //}
            // draw confidence string
            var valid = consistency[1];
            if (valid > validThreshold) {
                valid = validThreshold;
            }
            
            dc.setPenWidth(p);
            dc.drawRectangle(x - (s * validThreshold / 2) - posShift, (2.0 * h) - (h / 2) + p, s * validThreshold, (h / 2) + p);
            //Sys.println("draw: " + [x - (s * validThreshold / 2) - posShift, (2.0 * h) - (h / 2), s * validThreshold, (h / 2) + p]);
            dc.fillRectangle(x - (s * valid / 2) - posShift, (2.0 * h) - (h / 2) + p, s * valid, (h / 2) + p);
            //Sys.println("fill: " + [x - (s * valid / 2) - posShift, (2.0 * h) - (h / 2), s * valid, (h / 2) + p]);
            
            //var bpmConfidenceString = "";
            //if (valid == validThreshold) {
            //    dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT );
            //    bpmConfidenceString = bpmConfidenceString + "VALID";
            //}
            //dc.drawText( x - posShift, (1.9 * h) - (h / 2), Gfx.FONT_TINY, bpmConfidenceString, Gfx.TEXT_JUSTIFY_CENTER );
            
            // -- display BPM
            // format and draw BPM
            dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
            var bpm = g_bpmCalculator.getBPM();
            var bpmString = "---";
            if (bpm > 0) {
               bpmString = "" + bpm.format("%.1f");
            }
            dc.drawText( x, y, Gfx.FONT_NUMBER_THAI_HOT, bpmString, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
            
            // -- display irregular warning
            if (consistency[3] == true) {
                // format and draw irregular warning
                dc.setColor( Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT );
                var bpmIrregularString = "IRREGULAR";
                dc.drawText( x, (y * 2) - (1.9 * h) + (2 * p), Gfx.FONT_SMALL, bpmIrregularString, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
                dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
            }
            
            
        } else {
            // -- display startup info
            var tapMsg = "Tap for rate/min";
            dc.drawText( x, y - h, Gfx.FONT_MEDIUM, tapMsg, Gfx.TEXT_JUSTIFY_CENTER );
            var holdMsg = "Hold to reset";
            dc.drawText( x, y, Gfx.FONT_MEDIUM, holdMsg, Gfx.TEXT_JUSTIFY_CENTER );
        }
        
        // -- display num samples
        // format and draw num samples
        var numSamplesString = "" + consistency[0].format("%d") + " taps";
        dc.drawText( x, (y * 2) - h, Gfx.FONT_MEDIUM, numSamplesString, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
    }
}