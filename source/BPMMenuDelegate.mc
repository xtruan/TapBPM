using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Application.Storage as Stor;

class BPMMenuDelegate extends Ui.Menu2InputDelegate {

    hidden var m_callback;
    
    function initialize(callback) {
        m_callback = callback;
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        // NOP
        
        if (item.getId() == 1) { // clear history
            g_bpmHistory = [];
            Stor.setValue("bpmHistory", g_bpmHistory);
        
            Ui.popView(Ui.SLIDE_IMMEDIATE); // dismiss menu
            //m_callback.invoke();
        }
        
    }
}