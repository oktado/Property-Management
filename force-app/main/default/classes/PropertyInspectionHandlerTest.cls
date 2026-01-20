/**
 * @description Test class for PropertyInspectionHandler & PropertyInspectionController
 * @author Oktado
 * @date 2026
 */
@isTest
private class PropertyInspectionHandlerTest {
    
    /**
     * @description Setup test data
     */
    @TestSetup
    static void setupTestData() {
        // Create test accounts (properties)
        List<Account> properties = new List<Account>();
        for (Integer i = 0; i < 6; i++) {
            properties.add(new Account(
                Name = 'Test Property ' + i,
            Type = 'Customer'
                ));
        }
        insert properties;
        
        List<Property_Inspection__c> inspections = new List<Property_Inspection__c>();
        
        inspections.add(new Property_Inspection__c(
            Related_Property__c = properties[0].Id,
        Inspection_Date__c = Date.today().addDays(-30),
        Inspector_Name__c = 'John Doe',
        Inspection_Type__c = 'Initial',
        Inspection_Status__c = 'Completed',
        Overall_Rating__c = 5,
        Inspection_Cost__c = 500
            ));
        
        inspections.add(new Property_Inspection__c(
            Related_Property__c = properties[0].Id,
        Inspection_Date__c = Date.today().addDays(-10),
        Inspector_Name__c = 'Jane Smith',
        Inspection_Type__c = 'Annual',
        Inspection_Status__c = 'Completed',
        Overall_Rating__c = 3,
        Inspection_Cost__c = 300,
        Notes__c = 'Some minor issues found'
            ));
        
        inspections.add(new Property_Inspection__c(
            Related_Property__c = properties[1].Id,
        Inspection_Date__c = Date.today().addDays(-5),
        Inspector_Name__c = 'Bob Johnson',
        Inspection_Type__c = 'Maintenance',
        Inspection_Status__c = 'Scheduled',
        Inspection_Cost__c = 200
            ));
        
        inspections.add(new Property_Inspection__c(
            Related_Property__c = properties[2].Id,
        Inspection_Date__c = Date.today().addDays(-15),
        Inspector_Name__c = 'Alice Williams',
        Inspection_Type__c = 'Move-Out',
        Inspection_Status__c = 'In Progress',
        Inspection_Cost__c = 400
            ));
        
        inspections.add(new Property_Inspection__c(
            Related_Property__c = properties[3].Id,
        Inspection_Date__c = Date.today().addDays(10),
        Inspector_Name__c = 'Charlie Brown',
        Inspection_Type__c = 'Annual',
        Inspection_Status__c = 'Scheduled',
        Inspection_Cost__c = 350
            ));
        
        inspections.add(new Property_Inspection__c(
            Related_Property__c = properties[4].Id,
        Inspection_Date__c = Date.today().addDays(-20),
        Inspector_Name__c = 'David Lee',
        Inspection_Type__c = 'Initial',
        Inspection_Status__c = 'Failed',
        Inspection_Cost__c = 450
            ));
        
        insert inspections;
    }
    
    @isTest
    static void testCalculateAverageRatings_Success() {
        Account property = [SELECT Id FROM Account WHERE Name = 'Test Property 0' LIMIT 1];
        
        Test.startTest();
        Map<Id, Decimal> results = PropertyInspectionHandler.calculateAverageRatings(
        new Set<Id>{ property.Id }
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(4.00, results.get(property.Id), 'Average should be 4.00');
    }
    
    /**
     * @description Test calculate average ratings with multiple properties
     */
    @isTest
    static void testCalculateAverageRatings_MultipleProperties() {
        List<Account> properties = [SELECT Id FROM Account LIMIT 5];
        Set<Id> propertyIds = new Set<Id>();
        for (Account acc : properties) {
            propertyIds.add(acc.Id);
        }
        
        Test.startTest();
        Map<Id, Decimal> results = PropertyInspectionHandler.calculateAverageRatings(propertyIds);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return results only for properties with ratings');
    }
    
    /**
     * @description Test calculate average ratings with empty input
     */
    @isTest
    static void testCalculateAverageRatings_EmptyInput() {
        Test.startTest();
        Map<Id, Decimal> results = PropertyInspectionHandler.calculateAverageRatings(new Set<Id>());
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty map for empty input');
    }
    
    /**
     * @description Test get overdue inspections
     */
    @isTest
    static void testGetOverdueInspections_Success() {
        Test.startTest();
        List<Property_Inspection__c> overdueInspections =
            PropertyInspectionHandler.getOverdueInspections();
        Test.stopTest();
        
        System.assertEquals(2, overdueInspections.size(), 'Should return 2 overdue inspections');
        
        System.assert(
            overdueInspections[0].Inspection_Date__c <= overdueInspections[1].Inspection_Date__c,
        'Results should be ordered by date ascending'
            );
        
        for (Property_Inspection__c insp : overdueInspections) {
            System.assert(
                insp.Inspection_Status__c == 'Scheduled' ||
                insp.Inspection_Status__c == 'In Progress',
            'All returned inspections should be Scheduled or In Progress'
                );
        }
    }
    
    
    /**
     * @description Test exception handling in calculateAverageRatings
     */
    @isTest
    static void testCalculateAverageRatings_NullInput() {
        Test.startTest();
        Map<Id, Decimal> results = PropertyInspectionHandler.calculateAverageRatings(null);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty map for null input');
    }
    
    
    @isTest
    static void testBulkOperations() {
        List<Account> bulkProperties = new List<Account>();
        for (Integer i = 0; i < 100; i++) {
            bulkProperties.add(new Account(Name = 'Bulk Property ' + i));
        }
        insert bulkProperties;
        
        List<Property_Inspection__c> bulkInspections = new List<Property_Inspection__c>();
        for (Account acc : bulkProperties) {
            bulkInspections.add(new Property_Inspection__c(
                Related_Property__c = acc.Id,
            Inspection_Date__c = Date.today().addDays(-1),
            Inspector_Name__c = 'Bulk Inspector',
            Inspection_Type__c = 'Initial',
            Inspection_Status__c = 'Completed',
            Overall_Rating__c = 4,
            Inspection_Cost__c = 300
                ));
        }
        insert bulkInspections;
        
        Set<Id> bulkPropertyIds = new Set<Id>();
        for (Account acc : bulkProperties) {
            bulkPropertyIds.add(acc.Id);
        }
        
        Test.startTest();
        // Test all methods with bulk data
        Map<Id, Decimal> ratings = PropertyInspectionHandler.calculateAverageRatings(bulkPropertyIds);
        Map<Id, Integer> counts = PropertyInspectionHandler.getInspectionCounts(bulkPropertyIds);
        PropertyInspectionHandler.updateAccountWithLatestInspection(bulkInspections);
        Test.stopTest();
        
        System.assertEquals(100, ratings.size(), 'Should handle 100 properties');
        System.assertEquals(100, counts.size(), 'Should handle 100 properties');
    }
    
    /**
     * @description Test Duplicate Inspection in the same date
     */
    @isTest
    static void testDuplicateSameDate() {
        Account property = [SELECT Id FROM Account WHERE Name = 'Test Property 0' LIMIT 1];
        
        
        try {
            Property_Inspection__c inspection1 = new Property_Inspection__c(
                Related_Property__c = property.Id,
            Inspection_Date__c =  Date.today().addDays(-30),
            Inspector_Name__c = 'Test Inspector',
            Inspection_Type__c = 'Initial',
            Inspection_Status__c = 'Completed',
            Overall_Rating__c = 4,
            Inspection_Cost__c = 300
                );
            insert inspection1;
            System.assert(false, 'Exception should have been thrown');
            
        } catch (Exception ex) {
            System.assertEquals(
                'Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Duplicate inspection detected. An inspection already exists for this property on the selected date.: [Inspection_Date__c]',
            ex.getMessage()
                );
        }
        
    }
    
    
    @isTest
    static void testDuplicateSameDate2() {
        Account property = [SELECT Id,(Select Id From Property_Inspections__r) FROM Account WHERE Name = 'Test Property 0' LIMIT 1];
        
        List<Property_Inspection__c> propertyInspections = property.Property_Inspections__r;
        
        
        Property_Inspection__c inspection1 = new Property_Inspection__c(
            Id = propertyInspections[0].Id
            );
        Property_Inspection__c inspection2 = new Property_Inspection__c(
            Related_Property__c = property.Id,
        Inspection_Date__c =  Date.today().addDays(10),
        Inspector_Name__c = 'Test Inspector',
        Inspection_Type__c = 'Initial',
        Inspection_Status__c = 'Scheduled',
        Inspection_Cost__c = 300
            );
        PropertyInspectionController.getAverageRating(property.Id);
        PropertyInspectionController.getInspections(property.Id);
        PropertyInspectionController.createInspection(inspection2);
        update inspection1;
        
    }
    @isTest
    static void testGetNullRatingProperty() {
        Account property = [SELECT Id,(Select Id From Property_Inspections__r) FROM Account WHERE Name = 'Test Property 5' LIMIT 1];
        
        PropertyInspectionController.getAverageRating(property.Id);
        
    }
}