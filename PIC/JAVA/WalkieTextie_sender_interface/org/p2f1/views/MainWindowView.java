package org.p2f1.views;

import org.p2f1.views.styles.JButtonFlat;
import java.awt.BorderLayout;
import java.awt.Component;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.Font;
import java.awt.Insets;
import java.awt.Toolkit;
import java.io.File;
import javax.swing.BorderFactory;
import javax.swing.Box;
import javax.swing.BoxLayout;
import javax.swing.ImageIcon;
import javax.swing.JComboBox;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.ScrollPaneConstants;
import javax.swing.SwingConstants;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;
import org.p2f1.controllers.MainWindowController;

public class MainWindowView extends JFrame {

    private static final long serialVersionUID = 8459978615692456891L;

    public static final String BTN_UART = "BTN_UART";
    public static final String BTN_RF = "BTN_RF";
    public static final String BTN_UART_RCVD = "BTN_UART_RCVD";
    public static final String TXA_MESSAGE = "TXA_MESSAGE";
    public static final String BTN_REFRESH = "BTN_REFRESH";
    public static final String BTN_DISCONNECT = "BTN_DISCONNECT";
    public static final String BTN_CONNECT = "BTN_CONNECT";

    //Constants que contenen la mida de la pantalla de l'usuari
    private static final int SCREEN_WIDTH = (int) Toolkit.getDefaultToolkit().getScreenSize().getWidth();
    private static final int SCREEN_HEIGHT = (int) Toolkit.getDefaultToolkit().getScreenSize().getHeight();

    //Constants que indiquen la mida de la finestra per defecte
    private static final int WINDOW_WIDTH = 600;
    private static final int WINDOW_HEIGHT = 600;

    private static final int MAX_TEXT = 300;

    //Declarem les variables dels elements de la finestra gràfica
    private JPanel topPanel = null;
    private JPanel centerPanel = null;
    private JPanel infoPanel = null;
    private JPanel portPanel = null;
    private JPanel filePanel = null;
    private JLabel lblPort = null;
    private JLabel lblBaudRate = null;
    private JLabel lblPath = null;
    private JButtonFlat btnRefresh = null;
    private JButtonFlat btnConnect = null;
    private JButtonFlat btnDisconnect = null;
    private JButtonFlat btnRF = null;
    private JButtonFlat btnUART = null;
    private JButtonFlat btnUARTRcvd = null;
    private JTextArea jtaText = null;
    private JScrollPane sp = null;
    private JLabel lblTextCounter = null;

    private JComboBox<Integer> comboBaud = new JComboBox<Integer>();
    private JComboBox<String> comboPort = new JComboBox<String>();

    //Constructor de la classe MainWindowView (finestra gràfica)
    public MainWindowView() {
        configureWindow();
        configureTopPanel();
        configureCenterPanel();
        configureBottomPanel();
        setStyle();
        setAppIcon();

    }

    public void setAppIcon() {
        try {
            String appIconPath = "./bin/appicon.png";
            File directory = new File(".");
            String path = directory.getCanonicalPath() + appIconPath;
            ImageIcon appIcon = new ImageIcon(path);
            this.setIconImage(appIcon.getImage());
        } catch (Exception e) {
        }
    }

    //Configurem els paràmetres de la finestra
    private void configureWindow() {
        setTitle("[SDM] Pràctica 2 - Fase 1 - LS26151 - LS27094");
        setSize(new Dimension(WINDOW_WIDTH, WINDOW_HEIGHT));
        setLocation(SCREEN_WIDTH / 2 - WINDOW_WIDTH / 2, SCREEN_HEIGHT / 2 - WINDOW_HEIGHT / 2);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setLayout(new BorderLayout());
    }

    //Configura el panell superior i els seus components
    private void configureTopPanel() {

        //Configurem els JPanels
        topPanel = new JPanel();
        infoPanel = new JPanel();
        portPanel = new JPanel();
        topPanel.setLayout(new BorderLayout());
        topPanel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
        infoPanel.setLayout(new BoxLayout(infoPanel, BoxLayout.Y_AXIS));
        portPanel.setLayout(new FlowLayout());

        //Configurem les labels
        lblBaudRate = new JLabel("BaudRate: ");
        lblPort = new JLabel("Port: ");
        this.btnRefresh = new JButtonFlat("RLD", JButtonFlat.SALLE);
        this.btnDisconnect = new JButtonFlat("Desconectar", JButtonFlat.BOOTSTRAP_WARNING);
        this.btnConnect = new JButtonFlat("Conectar", JButtonFlat.SALLE);

        //Afegim els components al port Panel
        portPanel.add(lblBaudRate);
        portPanel.add(comboBaud);
        portPanel.add(lblPort);
        portPanel.add(comboPort);
        portPanel.add(this.btnRefresh);
        portPanel.add(this.btnDisconnect);
        portPanel.add(this.btnConnect);

        //Afegim l'infoPanel al topPanel (alineat a l'esquerra)
        topPanel.add(infoPanel, BorderLayout.WEST);
        topPanel.add(portPanel, BorderLayout.EAST);

        //Afegim el topPanel a la finestra
        add(topPanel, BorderLayout.NORTH);

    }

    //Configura el panell central i els seus components
    private void configureCenterPanel() {

        //Creem els panells
        centerPanel = new JPanel();
        filePanel = new JPanel();
        centerPanel.setLayout(new BoxLayout(centerPanel, BoxLayout.Y_AXIS));
        filePanel.setLayout(new FlowLayout());
        filePanel.setMaximumSize(new Dimension(1000, 50));

        //Creem els TextFields
        jtaText = new JTextArea("Escribe el texto a enviar.");
        jtaText.setLineWrap(true);
        jtaText.setWrapStyleWord(true);
        

        sp = new JScrollPane(jtaText);
        sp.setVerticalScrollBarPolicy(ScrollPaneConstants.VERTICAL_SCROLLBAR_ALWAYS);
        sp.setBounds(3, 3, 400, 400);
        sp.setPreferredSize(new Dimension(500, 100));
        lblTextCounter = new JLabel(jtaText.getText().length() + "/" + MAX_TEXT);
        lblTextCounter.setHorizontalAlignment(SwingConstants.CENTER);

        //Creem els botons
        btnUART = new JButtonFlat("Carga mensaje", JButtonFlat.BOOTSTRAP_INFO);
        btnUARTRcvd = new JButtonFlat("Muestra mensaje cargado", JButtonFlat.SALLE);
        btnRF = new JButtonFlat("Envia mensaje via RF", JButtonFlat.BOOTSTRAP_SUCCESS);

        btnUART.setAlignmentX(Component.CENTER_ALIGNMENT);
        btnUARTRcvd.setAlignmentX(Component.CENTER_ALIGNMENT);
        btnRF.setAlignmentX(Component.CENTER_ALIGNMENT);
        lblTextCounter.setAlignmentX(Component.CENTER_ALIGNMENT);

        btnUART.setMaximumSize(new Dimension(200, 50));
        btnUART.setMinimumSize(new Dimension(200, 50));
        btnUARTRcvd.setMinimumSize(new Dimension(200, 50));
        btnUARTRcvd.setMaximumSize(new Dimension(200, 50));
        btnRF.setMaximumSize(new Dimension(200, 50));
        btnRF.setMinimumSize(new Dimension(200, 50));
        lblTextCounter.setMaximumSize(new Dimension(200, 50));
        lblTextCounter.setMinimumSize(new Dimension(200, 50));

        btnRF.setPreferredSize(new Dimension(200, 50));
        btnUART.setPreferredSize(new Dimension(200, 50));
        btnUARTRcvd.setPreferredSize(new Dimension(200, 50));

        //Agefim els controls al panell del fitxer
        lblPath = new JLabel("  ");
        filePanel.add(lblPath);
        filePanel.add(sp);

        //Afegim els controls al panell central
        centerPanel.add(Box.createVerticalGlue());
        centerPanel.add(filePanel);
        centerPanel.add(Box.createRigidArea(new Dimension(2, 2)));
        centerPanel.add(lblTextCounter);
        centerPanel.add(Box.createRigidArea(new Dimension(50, 50)));
        centerPanel.add(btnUART);
        centerPanel.add(Box.createRigidArea(new Dimension(8, 8)));
        centerPanel.add(btnUARTRcvd);
        centerPanel.add(Box.createRigidArea(new Dimension(50, 50)));
        centerPanel.add(btnRF);
        centerPanel.add(Box.createVerticalGlue());

        //Afegim el panell central a la finestra
        add(centerPanel, BorderLayout.CENTER);
    }

    //Configura el panell inferior i els seus components
    //Configura el panell inferior i els seus components. 
    //Actualment no hi ha cap component.
    private void configureBottomPanel() {

    }

    public void associateController(MainWindowController controller) {

        //Assignem el nom per distingir els botons
        btnUART.setName(BTN_UART);
        btnRF.setName(BTN_RF);
        btnUARTRcvd.setName(BTN_UART_RCVD);
        this.btnConnect.setName(BTN_CONNECT);
        this.btnDisconnect.setName(BTN_DISCONNECT);
        this.btnRefresh.setName(BTN_REFRESH);
        jtaText.setName(TXA_MESSAGE);

        //Assignem el controlador dels botons
        btnUART.addActionListener(controller);
        btnUARTRcvd.addActionListener(controller);
        btnRF.addActionListener(controller);
        this.btnConnect.addActionListener(controller);
        this.btnDisconnect.addActionListener(controller);
        this.btnRefresh.addActionListener(controller);
        jtaText.getDocument().addDocumentListener(new DocumentListener() {
            @Override
            public void insertUpdate(DocumentEvent e) {
                lblTextCounter.setText(jtaText.getText().length() + "/" + MAX_TEXT);
            }

            @Override
            public void removeUpdate(DocumentEvent e) {
                lblTextCounter.setText(jtaText.getText().length() + "/" + MAX_TEXT);
            }

            @Override
            public void changedUpdate(DocumentEvent e) {
                lblTextCounter.setText(jtaText.getText().length() + "/" + MAX_TEXT);
            }
        });

    }

    public void setPortsList(String[] lPorts) {
        comboPort.removeAllItems();
        for (String item : lPorts) {
            comboPort.addItem(item);
        }
    }

    public void setBaudRateList(int[] lBaudRates) {
        comboBaud.removeAllItems();
        for (int item : lBaudRates) {
            comboBaud.addItem(item);
        }
    }

    public String getSerialPortNumberSelected() {
        return String.valueOf(comboPort.getSelectedItem());
    }

    public String getBaudRateSelected() {
        return String.valueOf(comboBaud.getSelectedItem());
    }

    public String getText() {
        return jtaText.getText();
    }

    public void disableTXRXButtons() {
        this.btnUARTRcvd.setEnabled(false);
        this.btnRF.setEnabled(false);
        this.btnUART.setEnabled(false);
    }

    public void enableTXRXButtons() {
        this.btnUARTRcvd.setEnabled(true);
        this.btnRF.setEnabled(true);
        this.btnUART.setEnabled(true);
    }

    public void enableTopPanelButtons() {
        this.comboBaud.setEnabled(true);
        this.comboPort.setEnabled(true);
        this.btnRefresh.setEnabled(true);
        this.btnConnect.setEnabled(true);
        this.btnDisconnect.setEnabled(true);
        this.btnConnect.setStyle(JButtonFlat.SALLE);
        this.btnDisconnect.setStyle(JButtonFlat.SALLE);
    }

    public void disableTopPanelButtons() {
        this.comboBaud.setEnabled(false);
        this.comboPort.setEnabled(false);
        this.btnRefresh.setEnabled(false);
        this.btnConnect.setEnabled(false);
        this.btnDisconnect.setEnabled(true);        // El serial port estara activado, dejamos el boton de desactivar accesible

        this.btnConnect.setStyle(JButtonFlat.BOOTSTRAP_SUCCESS);
        this.btnDisconnect.setStyle(JButtonFlat.BOOTSTRAP_DANGER);
    }

    private void setStyle() {
        this.jtaText.setFont(new Font("Calibri", Font.PLAIN, 12));
        this.jtaText.setMargin(new Insets(8, 8, 8, 8));
        this.lblTextCounter.setFont(new Font("Calibri", Font.PLAIN, 12));
    }
}
