using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application.Storage as Stor;
using Toybox.Math as Math;

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

    function onUpdate(dc)
    {   
        var posShift = 0;
        if (m_isMono) {
            posShift = 30;
        }
            
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
            dc.drawText( (dc.getWidth() / 2) - posShift, Gfx.getFontHeight(Gfx.FONT_MEDIUM), Gfx.FONT_MEDIUM, timerString, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
            
            // -- display confidence info
            var validThreshold = g_bpmCalculator.getValidThreshold();
            
            // configure confidence colors
            if (m_isMono == true) {
                dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
            } else if (consistency[1] < 3) {
                dc.setColor( Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT );
            } else if (consistency[1] >= 3 && consistency[1] < validThreshold) {
                dc.setColor( Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT );
            } else {
                dc.setColor( Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT );
            }
            // build confidence string
            var bpmConfidenceString = "|";
            for (var i = 0; i < validThreshold; i++) {
                if (i < consistency[1]) {
                    bpmConfidenceString = bpmConfidenceString + "|";
                } else {
                    bpmConfidenceString = bpmConfidenceString + "-";
                }
            }
            if (consistency[1] >= validThreshold) {
                bpmConfidenceString = bpmConfidenceString + " VALID";
            }
            // draw confidence string
            dc.drawText( (dc.getWidth() / 2) - posShift, 1.9 * Gfx.getFontHeight(Gfx.FONT_MEDIUM), Gfx.FONT_MEDIUM, bpmConfidenceString, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
            
            // -- display BPM
            // format and draw BPM
            dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
            var bpm = g_bpmCalculator.getBPM();
            var bpmString = "---";
            if (bpm > 0) {
               bpmString = "" + bpm.format("%.1f");
            }
            dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2), Gfx.FONT_NUMBER_THAI_HOT, bpmString, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
            
            // -- display irregular warning
            if (consistency[3] == true) {
                // format and draw irregular warning
                dc.setColor( Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT );
                var bpmIrregularString = "IRREGULAR";
                dc.drawText( (dc.getWidth() / 2), dc.getHeight() - (1.9 * Gfx.getFontHeight(Gfx.FONT_MEDIUM)), Gfx.FONT_MEDIUM, bpmIrregularString, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
                dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
            }
            
            
        } else {
            // -- display startup info
            var tapMsg = "Tap for rate/min";
            dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2) - Gfx.getFontHeight(Gfx.FONT_MEDIUM), Gfx.FONT_MEDIUM, tapMsg, Gfx.TEXT_JUSTIFY_CENTER );
            var holdMsg = "Hold to reset";
            dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2), Gfx.FONT_MEDIUM, holdMsg, Gfx.TEXT_JUSTIFY_CENTER );
        }
        
        // -- display num samples
        // format and draw num samples
        var numSamplesString = "" + consistency[0].format("%d") + " taps";
        dc.drawText( (dc.getWidth() / 2), dc.getHeight() - Gfx.getFontHeight(Gfx.FONT_MEDIUM), Gfx.FONT_MEDIUM, numSamplesString, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
    }
}