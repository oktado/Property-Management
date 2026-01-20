/**
 * @description Custom exception class for Property Inspection operations
 */
public class PropertyInspectionException extends Exception {
    
    public static String duplicateSameDate() {
        return 'Duplicate inspection detected. An inspection already exists for this property on the selected date.';
    }
}