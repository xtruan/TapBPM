using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Attention as Attn;
using Toybox.Application.Storage as Stor;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Cal;
using Toybox.Lang as Lang;

class BPMDelegate extends Ui.BehaviorDelegate {

    // reset
    function reset() {
        var bpm = g_bpmCalculator.getBPM();
        if (bpm != 0) {
        
            // get time of this reset
            var now = Time.now();
            var info = Cal.info(now, Time.FORMAT_LONG);
            var timeStr = Lang.format(
                "$1$ $2$, $3$:$4$:$5$", 
                [info.month, info.day, info.hour.format("%02d"), info.min.format("%02d"), info.sec.format("%02d")]
            );
            // store BPM as raw float, store time and date as string
            var bpmEntry = [bpm, timeStr];
            g_bpmHistory.add(bpmEntry);
            
            // Limit history to prevent memory issues
            if (g_bpmHistory.size() > 10) {
                // Remove first element (oldest)
                var newBpmHistory = g_bpmHistory.slice(1, g_bpmHistory.size());
                g_bpmHistory = newBpmHistory;
            }
            
            Stor.setValue("bpmHistory", g_bpmHistory);
        }
    
        g_bpmCalculator.reset();

        Ui.requestUpdate();
    }

    // menu softkey resets
    function onMenu() {
        reset();
        
        // display history menu
        var menu = new Ui.Menu2({:title=>"BPM History"});
        var delegate;
        
        // iterate through list, format BPM from float display time and date as is
        for (var i = (g_bpmHistory.size() - 1); i >= 0; i--) {
            menu.addItem(
                new Ui.MenuItem(
                    "" + g_bpmHistory[i][0].format("%.1f") + " BPM",
                    "" + g_bpmHistory[i][1],
                    0,
                    {}
                )
            );
        }
       
        menu.addItem(
            new Ui.MenuItem(
                "Clear History",
                "",
                1,
                {}
            )
        );
        
        delegate = new BPMMenuDelegate(method(:onSelect)); // a WatchUi.Menu2InputDelegate
        Ui.pushView(menu, delegate, Ui.SLIDE_IMMEDIATE);
        
        return true;
    }
    
    // up/prev resets
    function onPreviousPage() {
        reset();
        return true;
    }
    
    // hold causes vibration and reset
    function onHold(evt) {
        var vibe = [new Attn.VibeProfile( 50, 100 )];
        Attn.vibrate(vibe);
        reset();
        return true;
    }
    
    // each tap recalculates BPM
    function onTap(evt) {
        onSelect();
        return true;
    }
    
    function onSelect() {
        g_bpmCalculator.onSample();
        
        Ui.requestUpdate();
        return true;
    }

}