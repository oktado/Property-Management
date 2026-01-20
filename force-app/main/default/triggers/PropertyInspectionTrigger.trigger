trigger PropertyInspectionTrigger on Property_Inspection__c (before insert, before update, after insert, after update) {
  if(Trigger.isBefore){
    PropertyInspectionHandler.handleDuplicateInspectionSameDate(Trigger.new, Trigger.oldMap);
  }
  
  else if(Trigger.isAfter){
    PropertyInspectionHandler.updateAccountWithLatestInspection(Trigger.new);
  }
}