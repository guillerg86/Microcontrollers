package org.p2f1.models;

import PicComunicator.Handler;
import com.SerialPort.SerialPort;

public class MainWindowModel {

    private Handler handler;
    private SerialPort serialPortConnection;
    
    public void setSerialConection(SerialPort sp, Handler handler) {
        this.serialPortConnection = sp;
        this.handler = handler;
    }
    
    public boolean checkInputText(String sText) {
        if (sText.length() > 0) {
            return true;
        }
        return false;
    }

}
