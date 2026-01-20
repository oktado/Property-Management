# Salesforce Property Management Project

property management app built on Salesforce to track property inspections, manage inspection schedules through a modern Lightning Web Component dashboard.

# Custom Object 

Property_Inspection__c: Tracks all property inspections with relationship to Account (Property)

# Apex Classes

PropertyInspectionHandler: Core business logic handler
PropertyInspectionController: LWC data controller
PropertyInspectionHandlerTest:  test class coverage (90%+)

# Lightning Web Components
propertyInspectionDashboard: Interactive dashboard for Account record pages

# Flows 

Schedule_Property_Inspection: Screen flow for scheduling new inspections


# Approach 

* UI Layer: Create a Lightning Web Component dashboard to display inspection records and embed it on the Account Record Page
* User Interaction: Integrate the Screen Flow within the LWC to enable users to schedule new inspections
* Business Logic: Develop an Apex Controller to manage server-side operations and data retrieval
* Automation: Implement an Apex Trigger Handler to:
Validate and prevent duplicate inspections on the same date
Automatically update the Account description with the most recent inspection details

# Assumption
* Account Object represents Properties: The standard Account object is used to represent properties, eliminating the need for a separate custom Property object
* Schedule Inspection Record Statusses: All Inspection Record Status Created from Screen Flow will be "Scheduled". with validation Date must be in the future or today (current date)
* Date-based duplicate validation: Duplicate prevention is based on the combination of Property, Inspection Type, and Inspection Date (same-day duplicates only)

# Known Limitation & Performance Scalability

Pagination not implemented: The LWC dashboard displays a maximum of 200 inspection records per property. Properties with more than 200 inspections will not show all records in the component

Recommendation: Implement pagination or infinite scrolling for properties with high inspection volumes (>200 records)
Workaround: Users can access all inspections via the standard Related List on the Account page

No bulk operations: The Screen Flow creates one inspection at a time; bulk import or creation of multiple inspections is not supported
Workaround: Use Data Loader or Salesforce Import Wizard for bulk inspection imports

# Screenshot UI & Flow
LWC dashboard display on Account Record Page with button to create inspection record and refresh page
<img width="938" height="439" alt="ss_schedule_inspection_page" src="https://github.com/user-attachments/assets/c0d7ec91-695a-44fc-b9f9-e5690561bf81" />

Schedule Inspection Screen Flow
<img width="959" height="416" alt="ss_schedule_inspection_screen_flow" src="https://github.com/user-attachments/assets/d9b42846-d6fa-49b4-a21c-a5db1c2668e0" />

Schedule Inspection Screen Flow (Validation Date)
<img width="928" height="450" alt="ss_date_inspection_cannot_past" src="https://github.com/user-attachments/assets/fb213b92-28e6-4fb4-8f85-f2f8d04150ec" />

Schedule Inspection Screen Flow (Success), Showing Detailed Inspection
<img width="950" height="406" alt="ss_schedule_inspection_screen_flow_success" src="https://github.com/user-attachments/assets/860411ee-cfb6-4c99-af27-583fc55a2015" />

Schedule Inspection Record Created
<img width="947" height="442" alt="ss_schedule_inspection_screen_flow_success_2" src="https://github.com/user-attachments/assets/24d60a61-148b-41ca-9162-9e4b0c8cb6a6" />

Flow Builder
<img width="959" height="397" alt="ss_flow_builder" src="https://github.com/user-attachments/assets/7f1cb3b7-e088-4bd9-9df5-7d2526776187" />

Test Class Coverage
<img width="939" height="455" alt="ss_test_class_coverage" src="https://github.com/user-attachments/assets/fa104a03-ddf9-47bc-8191-7f515a3f6cca" />













