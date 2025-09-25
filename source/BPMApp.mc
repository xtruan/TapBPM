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
        
        // -- configure ui scaling variables
        // half display width
        var uiX = dc.getWidth() / 2;
        // half display height
        var uiY = dc.getHeight() / 2;
        // medium font height
        var uiH = Gfx.getFontHeight(Gfx.FONT_MEDIUM);
        // smaller of uiX or uiY
        var uiR = uiX;
        if (uiX >= uiY) {
            uiR = uiY;
        }
        // scale factor
        var uiS = uiR / 7;
        if (m_isMono == true) {
            uiS = uiR / 10;
        }
        // pen width
        var uiP = 2;
            
        // clear display
        dc.setColor( Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK );
        dc.clear();
        dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
        
        // draw dots to advertise menu
        dc.fillCircle((2* uiP), uiY + (4 * uiP), uiP);
        dc.fillCircle((2* uiP), uiY, uiP);
        dc.fillCircle((2* uiP), uiY - (4 * uiP), uiP);
    
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
            dc.drawText( uiX - posShift, uiH, Gfx.FONT_MEDIUM, timerString, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
            
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
            
            // calculate confidence bar position and size
            var uiBarX = uiX - (uiS * validThreshold / 2) - posShift;
            var uiBarY = (2.0 * uiH) - (uiH / 2) + uiP;
            var uiBarMax = uiS * validThreshold;
            var uiBarFill = uiS * valid;
            var uiBarH = (uiH / 2) + uiP;
            
            // if valid, draw check mark
            if (valid == validThreshold) {
                // shift X position to account for check
                uiBarX = uiBarX - (uiBarH / 2);
                // draw check
                dc.setPenWidth(uiP * 1.5);
                dc.drawLine(uiBarX + uiBarMax + (uiP * 2), 
                            uiBarY + (uiBarH / 2) - uiP, 
                            uiBarX + uiBarMax + (uiBarH / 2), 
                            uiBarY + uiBarH - uiP);
                dc.drawLine(uiBarX + uiBarMax + (uiBarH / 2), 
                            uiBarY + uiBarH - uiP, 
                            uiBarX + uiBarMax + uiBarH, 
                            uiBarY);
            }
            
            // draw confidence bar
            dc.setPenWidth(uiP);
            dc.drawRectangle(uiBarX, uiBarY, uiBarMax, uiBarH);
            dc.fillRectangle(uiBarX, uiBarY, uiBarFill, uiBarH);
            //dc.drawRoundedRectangle(uiBarX, uiBarY, uiBarMax, uiBarH, uiR);
            //dc.fillRoundedRectangle(uiBarX, uiBarY, uiBarFill, uiBarH, uiR);
            //Sys.println("draw: " + [uiBarX, uiBarY, uiBarMax, uiBarH]);
            //Sys.println("fill: " + [uiBarX, uiBarY, uiBarFill, uiBarH]);
             
            // -- display BPM
            // format and draw BPM
            dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
            var bpm = g_bpmCalculator.getBPM();
            var bpmString = "---";
            if (bpm > 0) {
               bpmString = "" + bpm.format("%.1f");
            }
            dc.drawText( uiX, uiY, Gfx.FONT_NUMBER_THAI_HOT, bpmString, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
            
            // -- display irregular warning or validity
            if (consistency[3] == true) {
                // format and draw irregular warning
                dc.setColor( Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT );
                var bpmIrregularString = "IRREGULAR";
                dc.drawText( uiX, (uiY * 2) - (1.9 * uiH) + (2 * uiP), Gfx.FONT_SMALL, bpmIrregularString, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
                dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
            } 
            //else if (valid == validThreshold) {
            //    // if not irregular, and valid, display valid
            //    dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
            //    var bpmValidString = "VALID";
            //    dc.drawText( uiX, (uiY * 2) - (1.9 * uiH) + (2 * uiP), Gfx.FONT_SMALL, bpmValidString, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
            //    dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
            //}
            
            
        } else {
            // -- display startup info
            var tapMsg = "Tap for rate/min";
            dc.drawText( uiX, uiY - uiH, Gfx.FONT_MEDIUM, tapMsg, Gfx.TEXT_JUSTIFY_CENTER );
            var holdMsg = "Hold to reset";
            dc.drawText( uiX, uiY, Gfx.FONT_MEDIUM, holdMsg, Gfx.TEXT_JUSTIFY_CENTER );
        }
        
        // -- display num samples
        // format and draw num samples
        var numSamplesString = "" + consistency[0].format("%d") + " taps";
        dc.drawText( uiX, (uiY * 2) - uiH, Gfx.FONT_MEDIUM, numSamplesString, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
    }
}