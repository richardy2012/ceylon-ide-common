import java.lang {
    RuntimeException
}
import com.redhat.ceylon.common.log {
    Logger
}
shared class Status of _OK | _INFO| _DEBUG  | _WARNING | _ERROR {
    String _string;
    shared new _OK { _string = "OK"; }
    shared new _INFO  { _string = "INFO"; }
    shared new _DEBUG  { _string = "DEBUG"; }
    shared new _WARNING  { _string = "WARNING"; }
    shared new _ERROR  { _string = "ERROR"; }
    string => _string;
}

shared interface IdeUtils {
    shared formal void log(Status status, String message, Exception? e=null);
    
    "Creates a [[RuntimeException|java.lang::RuntimeException]]
     with the exception type typically used in an IDE platform in case of 
     operation cancellation."
    shared formal RuntimeException newOperationCanceledException(String message="");
    
    "returns [[true]] if [[exception]] is of the exception type typically used
     in an IDE platform in case of operation cancellation."
    shared formal Boolean isOperationCanceledException(Exception exception);

    shared default Logger cmrLogger => object satisfies Logger {
        error(String str) => process.writeErrorLine("Error: ``str``");
        warning(String str) => process.writeErrorLine("Warning: ``str``");        
        info(String str) => process.writeErrorLine("Note: ``str``");
        debug(String str) => noop();
    };
}

shared class DefaultIdeUtils() satisfies IdeUtils {
    shared actual void log(Status status, String message, Exception? e) {
        value printFunction 
                = switch (status) 
                case (Status._WARNING | Status._ERROR) 
                    process.writeErrorLine 
                case (Status._INFO | Status._OK | Status._DEBUG) 
                    process.writeLine;
        
        printFunction("``status``: ``message``");
    }
    
    class OperationCancelledException(String? description=null, Throwable? cause=null) 
            extends RuntimeException(description, cause) {}
    
    newOperationCanceledException(String message) 
            => OperationCancelledException("Operation Cancelled : ``message``");
    
    isOperationCanceledException(Exception exception) 
            => exception is OperationCancelledException;
}
