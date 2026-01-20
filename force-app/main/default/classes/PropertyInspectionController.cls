/**
 * @description Apex controller for propertyInspectionDashboard LWC
 * @author Oktado
 * @date 2026
 */
public with sharing class PropertyInspectionController {
    
    /**
     * @description Retrieves all inspections for a given account
     * @param accountId The Account record ID
     * @return List of Property Inspection records
     */
    @AuraEnabled(cacheable=true)
    public static List<Property_Inspection__c> getInspections(Id accountId) {
        
        
        return [
                SELECT Id, Name, Inspection_Date__c, Inspector_Name__c,
                       Inspection_Type__c, Inspection_Status__c, 
                       Overall_Rating__c, Inspection_Cost__c, Notes__c
                FROM Property_Inspection__c
                WHERE Related_Property__c = :accountId
                ORDER BY Inspection_Date__c DESC
                LIMIT 200
            ];
        
        
    }
    
    /**
     * @description Calculates average rating for a property
     * @param accountId The Account record ID
     * @return Average rating as Decimal
     */
    @AuraEnabled(cacheable=true)
    public static Decimal getAverageRating(Id accountId) {
        
        AggregateResult[] results = [
                SELECT AVG(Overall_Rating__c) avgRating
                FROM Property_Inspection__c
                WHERE Related_Property__c = :accountId
                AND Overall_Rating__c != null
            ];
        
        Decimal avgRating = (Decimal)results[0].get('avgRating');
        return avgRating != null ? avgRating : 0;
        
    }
    
    /**
     * @description Creates a new inspection record
     * @param inspection Property Inspection record to create
     * @return Created Property Inspection record with ID
     */
    @AuraEnabled
    public static Property_Inspection__c createInspection(Property_Inspection__c inspection) {
        
        
        insert inspection;
        
        return [
                SELECT Id, Name, Inspection_Date__c, Inspector_Name__c,
                       Inspection_Type__c, Inspection_Status__c, Related_Property__c
                FROM Property_Inspection__c
                WHERE Id = :inspection.Id
            ];
        
        
    }
}