package org.p2f1.controllers;

import PicComunicator.Handler;
import PicComunicator.PICcomunicator;
import Utilities.Strings;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import javax.swing.JButton;
import javax.swing.JOptionPane;

import org.p2f1.models.MainWindowModel;
import org.p2f1.views.MainWindowView;

import com.SerialPort.SerialPort;
import java.util.logging.Level;
import java.util.logging.Logger;

public class MainWindowController implements ActionListener, Handler {

    private MainWindowView view = null;
    private MainWindowModel model = null;
    private SerialPort sp = null;
    private PICcomunicator pic;
    private boolean firstTimeConnected = true;

    public MainWindowController(MainWindowView view, MainWindowModel model) {
        try {
            this.sp = new SerialPort();
            this.view = view;
            this.model = model;
            this.view.associateController(this);
            this.view.setBaudRateList(sp.getAvailableBaudRates());
            this.view.setPortsList(sp.getPortList());
            this.view.disableTXRXButtons();                 // Desactivamos los botones 
            this.view.enableTopPanelButtons();
            this.pic = new PICcomunicator(this.sp, this);
            //this.sp.openPort("COM4", 9600);
            //this.pic.attachSerialPort(sp);
            //this.pic.start();
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
    }

    @Override
    public void actionPerformed(ActionEvent e) {
        if (e.getSource() instanceof JButton) {
            JButton btn = (JButton) e.getSource();
            switch (btn.getName()) {
                case MainWindowView.BTN_CONNECT:
                    String baudRate = this.view.getBaudRateSelected();
                    String port = this.view.getSerialPortNumberSelected();
                    //System.out.println("Baudrate S ["+baudRate+"]");
                    //System.out.println("Puerto S: ["+port+"]");

                    if (baudRate.matches("^\\d+$") && port.trim().length() != 0) {
                        try {
                            
                            this.sp.openPort(port, Integer.parseInt(baudRate.trim()));                 // for testing
                            this.pic.attachSerialPort(this.sp);
                            if ( this.firstTimeConnected ) {
                                this.pic.start();
                            }
                            this.view.enableTXRXButtons();
                            this.view.disableTopPanelButtons();
                            this.firstTimeConnected = false; 
                            this.pic.startReader();
                            
                       } catch (Exception eCON) {
                            JOptionPane.showMessageDialog(null, "Error al iniciar conexion:\n" + eCON.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                            //eCON.printStackTrace();
                        }
                    } else {
                        JOptionPane.showMessageDialog(null, "Selecciona un BaudRate y Puerto correctos", "Error", JOptionPane.ERROR_MESSAGE);
                    }

                    break;
                case MainWindowView.BTN_DISCONNECT:
                    this.pic.stopReader();
                    try {this.sp.closePort();}catch(Exception edisc){JOptionPane.showMessageDialog(null, "Se ha producido un error al desconectar:\n"+edisc.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);}
                    this.view.enableTopPanelButtons();
                    this.view.disableTXRXButtons();
                    
                    break;
                case MainWindowView.BTN_REFRESH:
                    this.view.setBaudRateList(sp.getAvailableBaudRates());
                    this.view.setPortsList(sp.getPortList());
                    break;
                case MainWindowView.BTN_UART:
                    String text = Strings.cleanNullString(view.getText());      // Limpiamos los espacios
                    if (Strings.isEmpty(text)) {
                        JOptionPane.showMessageDialog(null, "Has de introducir una frase antes de enviar!", "Missatge", JOptionPane.ERROR_MESSAGE);
                    } else {
                        if (text.length() > 300) {
                            JOptionPane.showMessageDialog(null, "Has puesto mas de 300 caracteres!", "Missatge", JOptionPane.ERROR_MESSAGE);
                            return;
                        }

                        this.view.disableTXRXButtons();
                        try {
                            System.out.println("Enviando la cadena de texto");
                            this.pic.sendString(text);
                        } catch (Exception esp) {
                            esp.printStackTrace();
                            JOptionPane.showMessageDialog(null, esp.getMessage(), "Error enviado datos (SPort)", JOptionPane.ERROR_MESSAGE);
                        }
                        this.view.enableTXRXButtons();
                    }

                    break;
                case MainWindowView.BTN_UART_RCVD:
                    this.view.disableTXRXButtons();
                    try {
                        String rcvdMessage = this.pic.requestString();
                        JOptionPane.showMessageDialog(null, "Información en el micro (" + rcvdMessage.length() + "):\n [" + rcvdMessage + "]", "Info", JOptionPane.PLAIN_MESSAGE);
                    } catch (Exception eUARTRCVD) {
                        eUARTRCVD.printStackTrace();
                        JOptionPane.showMessageDialog(null, "Error recuperando informacion del micro:\n" + eUARTRCVD.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                    } finally {
                        this.view.enableTXRXButtons();
                    }
                    break;
                case MainWindowView.BTN_RF:
                    try {
                        this.view.disableTXRXButtons();
                        this.pic.sendSignalRFID();
                    } catch (Exception eRFID) {
                        this.view.enableTXRXButtons();           // Si falla habilitamos botones de la view
                        eRFID.printStackTrace();
                        JOptionPane.showMessageDialog(null, "Error comunicando con el micro:\n " + eRFID.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                    }
                    break;
            }
        }
    }

    public void showView() {
        view.setVisible(true);
    }

    private void gestionaPIC(byte byteReceived) {
        switch (byteReceived) {
            case PICcomunicator.FLAG_END_TRANSMISSION:
                /*  No lo gestionamos, cuando el pc o pic envien la frase, al ser en un mismo thread
                        ya se gestiona el envio de este flag, si lo recibieramos de nuevo, pasamos de el.
                 */

                break;
            case PICcomunicator.FLAG_UPLOAD_STRING:
                /*  La PIC nos ha solicitado que le enviemos la frase, pero no esperara a que 
                        le comencemos a enviar la información, seguira en el main, pero el PC al
                        recibir este flag, se comportará como si el usuario hubiera pulsado en el 
                        boton de cargue el texto que hay en el TextArea de la View. La diferencia
                        es que aquí no comprobaremos si hay texto ( si no hay texto, podremos ver 
                        el modo scanning funcionando), si hay texto pues se cargará la frase y
                        veremos el modo blinking asociado.
                 */
                this.view.disableTXRXButtons();
                try {
                    this.pic.sendString(this.view.getText());
                } catch (Exception e) {
                    JOptionPane.showMessageDialog(null, e.getMessage(), "Error enviant dades", JOptionPane.ERROR_MESSAGE);
                } finally {
                    this.view.enableTXRXButtons();
                }
                break;
            case PICcomunicator.FLAG_DOWNLOAD_STRING:
                /*  Este caso, seria por si la placa tuviera un boton que forzará a mostrar un mensaje
                        por la interfaz de la app, si la pic recibiera mensajes por RFID y una vez recibido
                        quisieramos mostrarlo en la app. Pero de momento no los gestionaremos, pasaremos
                 */
                break;
            case PICcomunicator.FLAG_START_RFID_SEND:
                /*  PIC nos informa que le han pulsado el boton y que comenzará a enviar la informacion
                        que tiene cargada en la memoria RAM por RFID. Desactivamos los botones de la view
                        para evitar que el usuario pueda pulsar (aunque lo hiciera, la pic mientras envia
                        mediante RFID no se comporta de forma cooperativa), asi que simplemente 
                        no escucharia el mensaje mientras ejecuta el proceso del envio. Gracias al buffer
                        que tiene la SIO, una vez finalizará la ejecucion del envio, leeria el byte recibido
                        Por ello apagamos los botones para evitar que el usuario pueda comunicar algo a la 
                        PIC mientras realiza tarea.
                 */
                this.view.disableTXRXButtons();
                this.pic.startReader();
                break;

            case PICcomunicator.FLAG_END_TASK:
                this.view.enableTXRXButtons();
                this.pic.startReader();
                break;

            case PICcomunicator.FLAG_UNLOCK_THREAD:
                /*  Nunca se dará el caso de que recibamos este flag, pero lo ponemos para
                        indicar precisamente que esta controlador. Es el thread quien hace caso a este
                        FLAG , ya que le permite desbloquear la lectura en el Thread.
                 */
                break;
            default:
                /*  Cualquier otro tipo de byte, pasaremos de el.
                        
                 */
                break;
        }
    }

    @Override
    public void launchAction(Object obj) {
        if (obj instanceof Byte) {
            Byte byteReceived = (Byte) obj;
            this.gestionaPIC(byteReceived.byteValue());
        }
    }

}
