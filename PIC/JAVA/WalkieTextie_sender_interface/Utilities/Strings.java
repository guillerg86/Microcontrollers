package Utilities;

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
/**
 *
 * @author grodriguez
 */
public class Strings {

    public static String cleanNullString(String str) {
        String retorno = str;
        if (retorno == null) {
            return "";
        }
        retorno = retorno.trim();
        return retorno;
    }

    public static boolean isEmpty(String str) {
        if ((cleanNullString(str)).length() == 0) {
            return true;
        }
        return false;
    }

}
