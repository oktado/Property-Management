# Salesforce Property Management Project

A comprehensive property management system built on Salesforce to track property inspections, manage inspection schedules through a modern Lightning Web Component dashboard.

#Custom Objects

Property_Inspection__c: Tracks all property inspections with relationship to Account (Property)

#Apex Classes

PropertyInspectionHandler: Core business logic handler
PropertyInspectionController: LWC data controller
PropertyInspectionHandlerTest: Comprehensive test coverage (90%+)

#Lightning Web Components

propertyInspectionDashboard: Interactive dashboard for Account record pages

#Flows

Schedule_Property_Inspection: Screen flow for scheduling new inspections


#Approach to Requirements

* UI Layer: Create a Lightning Web Component dashboard to display inspection records and embed it on the Account Record Page
* User Interaction: Integrate the Screen Flow within the LWC to enable users to schedule new inspections
* Business Logic: Develop an Apex Controller to manage server-side operations and data retrieval
* Automation: Implement an Apex Trigger Handler to:
Validate and prevent duplicate inspections on the same date
Automatically update the Account description with the most recent inspection details



