package PicComunicator;

import com.SerialPort.SerialPort;
import java.util.concurrent.locks.ReentrantLock;

/**
 *
 * @author grodriguez
 */
public class PICcomunicator extends Thread {

    public static final byte FLAG_END_TRANSMISSION = 0x00;     // Flag que indica que se ha enviado el ultimo caracter de la string
    public static final byte FLAG_UPLOAD_STRING = 0x01;     // Flag que indica que iniciamos la transmission de la frase PC --> PIC || PIC <-- PC
    public static final byte FLAG_DOWNLOAD_STRING = 0x02;     // Flag PC --> PIC (Devuelveme lo cargado en la memoria ram interna) (just for testing)
    public static final byte FLAG_START_RFID_SEND = 0x03;     // Flag PC --> PIC || PIC <-- PC Comienza a enviar por RFID
    public static final byte FLAG_END_TASK = 0x04;          // Flag PIC --> PC , he finalizado la tarea (ya puedes reactivar los botones de la View)
    public static final byte FLAG_UNLOCK_THREAD = 0x0A;     // Flag que permite el desbloqueo del Thread de lectura de la app Java

    protected Handler handler;                                  // Para notificar al controller

    protected SerialPort serialPortConnection;                  // SerialPort Object
    protected byte byteReceived;                                // Byte recibido por SerialPort

    protected final Object objectForMutex = new Object();       // Para el synchronized necesitamos un objeto, mutex para evitar enviar si esta leyendo
    protected volatile boolean isRunning = false;
    protected volatile boolean stopReading = false;
    protected volatile boolean killThread = false;

    public PICcomunicator(SerialPort sp, Handler handler) {
        this.serialPortConnection = sp;
        this.handler = handler;
    }

    public void stopListenerThread() {
        this.killThread = true;
    }

    @Override
    public void run() {
        this.isRunning = true;
        System.out.println("Iniciando el Thread de escucha");
        while (killThread == false) {

            synchronized (objectForMutex) {
//                System.out.println("Iniciando la escucha del SerialPort");

                while (this.stopReading == false) {
                    try {
                        this.byteReceived = this.serialPortConnection.readByte();
//                        System.out.println("Byte recibido "+(int)byteReceived);
                        switch (this.byteReceived) {
                            case FLAG_UPLOAD_STRING:
                            case FLAG_DOWNLOAD_STRING:
                            case FLAG_START_RFID_SEND:
                            case FLAG_END_TASK:
                            case FLAG_END_TRANSMISSION:
                                this.stopReading = true;
                                this.handler.launchAction(new Byte(this.byteReceived));
                                break;
                            case FLAG_UNLOCK_THREAD:
                                
                                // No hacemos nada, pero lo ponemos para que sea visible que no hacemos nada
                                // porque no queremos que haga nada, solo desbloquee el readbyte

                                break;
                            default:
                                // Evitamos molestar al main Thread si no es un caracter que tengamos que manejar
                                break;
                        }
                    } catch (Exception ex) {
                        ex.printStackTrace();
                    }
                }
                this.isRunning = false;
            }
            //System.out.println("Parando la escucha del SerialPort");

            try {
                //System.out.println("Durmiendo el thread 10ms");
                Thread.sleep(10);
                //System.out.println("Despertando el thread");
            } catch (Exception e) {
            }
        }
        this.isRunning = false;
        System.out.println("El thread finalizo");
    }

    public void sendString(String message) throws Exception {

        this.stopReader();

        this.serialPortConnection.writeByte(FLAG_UPLOAD_STRING);
        if (message != null && message.length() > 0) {
            int size = message.length();
            System.out.print("Sending: [");
            for (int i = 0; i < size; i++) {
                byte byteToSend = (byte) message.charAt(i);
                this.serialPortConnection.writeByte(byteToSend);
                System.out.print((char) byteToSend);
            }
            System.out.println("]");
            this.serialPortConnection.writeByte(FLAG_END_TRANSMISSION);
        }
        this.startReader();
    }

    public String requestString() throws Exception {
        StringBuilder strBuilder = new StringBuilder("");
        byte byteOfString;

        this.stopReader();
        this.serialPortConnection.writeByte(FLAG_DOWNLOAD_STRING);
        for (int i = 0; i < 300; i++) {
            byteOfString = this.serialPortConnection.readByte();
            if (byteOfString == FLAG_END_TRANSMISSION) {
                break;
            }
            strBuilder.append((char) byteOfString);
        }
        this.startReader();

        // Antes eliminamos los caracteres que haya en el buffer que sean el FLAG_UNLOCK_THREAD
        return strBuilder.toString().replaceAll("" + (char) FLAG_UNLOCK_THREAD, "");
    }

    public void sendSignalRFID() throws Exception {
        this.stopReader();
        this.serialPortConnection.writeByte(FLAG_START_RFID_SEND);
        this.startReader();
    }

    public void startReader() {
        this.stopReading = false;
    }

    public void stopReader() {
        System.out.println("Solicitando stop thread");
        this.stopReading = true;
        synchronized (objectForMutex) {
            System.out.println("Thread parado");
            this.isRunning = false;
        }
    }

    public void attachSerialPort(SerialPort sp) {
        this.serialPortConnection = sp;
    }

}
