package com.ticketlegacy.util;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

public class DateUtil {

    public static String fmt(Object date, String pattern) {
        if (date == null) return "";
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern(pattern, Locale.KOREAN);
        if (date instanceof LocalDateTime) {
            return ((LocalDateTime) date).format(formatter);
        }
        if (date instanceof LocalDate) {
            return ((LocalDate) date).format(formatter);
        }
        return date.toString();
    }
}
