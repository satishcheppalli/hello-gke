package com.example.exception;

public class ApplicationException extends Exception {

    private String errorCode;
    private String errorMessage;

    public ApplicationException(String message) {
        super(message);
        this.errorMessage = message;
        this.errorCode = "APP_ERROR";
    }

    public ApplicationException(String errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
        this.errorMessage = message;
    }

    public ApplicationException(String message, Throwable cause) {
        super(message, cause);
        this.errorMessage = message;
        this.errorCode = "APP_ERROR";
    }

    public String getErrorCode() {
        return errorCode;
    }

    public String getErrorMessage() {
        return errorMessage;
    }
}
