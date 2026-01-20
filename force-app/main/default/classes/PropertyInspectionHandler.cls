/**
 * @description Handler class for Property Inspection operations
 * @author Oktado
 * @date 2026
 */
public with sharing class PropertyInspectionHandler {
    
    /**
     * @description Calculates the average inspection rating for given properties
     * @param propertyIds Set of Account IDs to calculate ratings for
     * @return Map of Account ID to average rating
     */
    public static Map<Id, Decimal> calculateAverageRatings(Set<Id> propertyIds) {
        Map<Id, Decimal> avgRatings = new Map<Id, Decimal>();
        
        
        // Query inspections, grouped by property
        AggregateResult[] results = [
                SELECT Related_Property__c, AVG(Overall_Rating__c) avgRating
                FROM Property_Inspection__c
                WHERE Related_Property__c IN :propertyIds
                AND Overall_Rating__c != null
                GROUP BY Related_Property__c
            ];
        
        for (AggregateResult ar : results) {
            Id propertyId = (Id)ar.get('Related_Property__c');
            Decimal avgRating = (Decimal)ar.get('avgRating');
            avgRatings.put(propertyId, avgRating.setScale(2));
        }
        
        
        return avgRatings;
    }
    
    /**
     * @description Retrieves all overdue inspections
     * @return List of overdue Property Inspection records
     */
    public static List<Property_Inspection__c> getOverdueInspections() {
        List<Property_Inspection__c> overdueInspections = new List<Property_Inspection__c>();
        
        
        overdueInspections = [
                SELECT Id, Name, Related_Property__c, Related_Property__r.Name, 
                       Inspection_Date__c, Inspection_Status__c, 
                       Inspection_Type__c, Inspector_Name__c
                FROM Property_Inspection__c
                WHERE Inspection_Date__c < TODAY
                AND (Inspection_Status__c = 'Scheduled' 
                     OR Inspection_Status__c = 'In Progress')
                ORDER BY Inspection_Date__c ASC
            ];
        
        
        
        return overdueInspections;
    }
    
    /**
     * @description Updates Account descriptions with most recent inspection summary after inserting new inspections
     * @param propertyIds new List property inspection records
     * @return void
     */
    public static void updateAccountWithLatestInspection(List<Property_Inspection__c> newList
    ) {
        
        Set<Id> propertyIds  = new Set<Id>();
        
        for(Property_Inspection__c inspection : newList){
            propertyIds.add(inspection.Related_Property__c);
        }
        
        try {
            
            Map<Id, Property_Inspection__c> latestInspections = new Map<Id, Property_Inspection__c>();
            
            for (Property_Inspection__c inspection : [
                SELECT Id, Related_Property__c, Inspection_Date__c, Inspection_Type__c,
                       Inspection_Status__c, Overall_Rating__c, Inspector_Name__c, Notes__c
                FROM Property_Inspection__c
                WHERE Related_Property__c IN :propertyIds
                ORDER BY Inspection_Date__c DESC
            ]) {
                if (!latestInspections.containsKey(inspection.Related_Property__c)) {
                    latestInspections.put(inspection.Related_Property__c, inspection);
                }
            }
            
            // Update Accounts
            List<Account> accountsToUpdate = new List<Account>();
            
            for (Id propertyId : latestInspections.keySet()) {
                Property_Inspection__c inspection = latestInspections.get(propertyId);
                
                String summary = 'Latest Inspection Summary:\n';
                summary += 'Date: ' + inspection.Inspection_Date__c?.format() + '\n';
                summary += 'Type: ' + inspection.Inspection_Type__c + '\n';
                summary += 'Status: ' + inspection.Inspection_Status__c + '\n';
                summary += 'Inspector: ' + inspection.Inspector_Name__c + '\n';
                
                if (inspection.Overall_Rating__c != null) {
                    summary += 'Rating: ' + inspection.Overall_Rating__c + '/5\n';
                }
                
                if (String.isNotBlank(inspection.Notes__c)) {
                    summary += 'Notes: ' + inspection.Notes__c.abbreviate(200);
                }
                
                accountsToUpdate.add(new Account(
                    Id = propertyId,
                Description = summary
                    ));
            }
            
            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }
            
            
        }catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating accounts: ' + e.getMessage());
        }
    }
    
    
    /**
     * @description Prevent duplicate inspections on same date
     * @param newList List of new Property Inspection records
     * @param oldMap Map of old Property Inspection records
     */
    public static void handleDuplicateInspectionSameDate(
        List<Property_Inspection__c> newList,
    Map<Id, Property_Inspection__c> oldMap
    ) {
        Set<Id> propertyIds = new Set<Id>();
        Set<Date> inspectionDates = new Set<Date>();
        
        // Collect data
        for (Property_Inspection__c pi : newList) {
            // Skip update if date & property not changed
            if (oldMap != null) {
                Property_Inspection__c oldRec = oldMap.get(pi.Id);
                if (oldRec != null &&
                    oldRec.Related_Property__c == pi.Related_Property__c &&
                    oldRec.Inspection_Date__c == pi.Inspection_Date__c
                ) {
                    continue;
                }
            }
            
            propertyIds.add(pi.Related_Property__c);
            inspectionDates.add(pi.Inspection_Date__c);
        }
        
        if (propertyIds.isEmpty()) return;
        
        // Query existing inspections
        List<Property_Inspection__c> existing = [
            SELECT Id, Related_Property__c, Inspection_Date__c
            FROM Property_Inspection__c
            WHERE Related_Property__c IN :propertyIds
            AND Inspection_Date__c IN :inspectionDates
        ];
        
        // Build lookup map: PropertyId + Date
        Map<String, Id> existingMap = new Map<String, Id>();
        for (Property_Inspection__c pi : existing) {
            String key = pi.Related_Property__c + '_' + pi.Inspection_Date__c;
            existingMap.put(key, pi.Id);
        }
        
        // Validate duplicates
        Set<String> seenInTrigger = new Set<String>();
        
        for (Property_Inspection__c pi : newList) {
            
            String key = pi.Related_Property__c + '_' + pi.Inspection_Date__c;
            
            
            // Duplicate against database
            if (existingMap.containsKey(key) &&
                existingMap.get(key) != pi.Id
            ) {
                pi.Inspection_Date__c.addError(
                    PropertyInspectionException.duplicateSameDate()
                    );
            }
            seenInTrigger.add(key);
        }
    }
    
    /**
     * @description Helper method to get inspection count by property
     * @param propertyIds Set of Account IDs
     * @return Map of Account ID to inspection count
     */
    public static Map<Id, Integer> getInspectionCounts(Set<Id> propertyIds) {
        Map<Id, Integer> inspectionCounts = new Map<Id, Integer>();
        
        try {
            AggregateResult[] results = [
                SELECT Related_Property__c, COUNT(Id) inspectionCount
                FROM Property_Inspection__c
                WHERE Related_Property__c IN :propertyIds
                GROUP BY Related_Property__c
            ];
            
            for (AggregateResult ar : results) {
                inspectionCounts.put(
                    (Id)ar.get('Related_Property__c'),
                (Integer)ar.get('inspectionCount')
                    );
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error getting inspection counts: ' + e.getMessage());
        }
        
        return inspectionCounts;
    }
    
    
    
    
    
    
}