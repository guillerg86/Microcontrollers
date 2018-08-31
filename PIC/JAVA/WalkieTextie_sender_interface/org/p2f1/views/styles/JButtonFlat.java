/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package org.p2f1.views.styles;

import java.awt.Color;
import java.awt.Font;
import javax.swing.JButton;
import javax.swing.UIManager;

/**
 *
 * @author grodriguez
 */
public class JButtonFlat extends JButton {

    public final static int SALLE = 0;
    
    public final static int GRAY = 1;

    public final static int BOOTSTRAP_SUCCESS = 100;
    public final static int BOOTSTRAP_INFO = 101;
    public final static int BOOTSTRAP_DANGER = 103;
    public final static int BOOTSTRAP_WARNING = 104;

    public JButtonFlat(String text) {
        super(text);
    }

    public JButtonFlat(String text, int predefinedStyle) {
        super(text);
        this.setFont(new Font("Calibri", Font.BOLD, 14));
        this.setStyle(predefinedStyle);
        this.setOpaque(true);
    }

    public void setStyle(int predefinedStyle) {
        this.setOpaque(true);
        this.setBorderPainted(false);
        switch (predefinedStyle) {
            case SALLE:
                this.setForeground(Color.WHITE);
                this.setBackground(Color.decode("0x6BB1E2"));
                
                break;
            case BOOTSTRAP_SUCCESS:
                this.setForeground(Color.WHITE);
                this.setBackground(Color.decode("0x5CB85C"));
                break;
            case BOOTSTRAP_INFO:
                this.setForeground(Color.WHITE);
                this.setBackground(Color.decode("0x428BCA"));
                break;
            case BOOTSTRAP_WARNING:
                this.setForeground(Color.WHITE);
                this.setBackground(Color.decode("0xF0AD4E"));
                break;
            case BOOTSTRAP_DANGER:
                this.setForeground(Color.WHITE);
                this.setBackground(Color.decode("0xD9534F"));

            default:
                break;
        }
    }
}
