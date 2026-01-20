import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInspections from '@salesforce/apex/PropertyInspectionController.getInspections';
import getAverageRating from '@salesforce/apex/PropertyInspectionController.getAverageRating';

const ACCOUNT_FIELDS = ['Account.Name'];

export default class PropertyInspectionDashboard extends NavigationMixin(LightningElement) {
    @api recordId; // Account record Id
    @track inspections = [];
    @track filteredInspections = [];
    @track averageRating = 0;
    @track selectedStatus = 'All';
    @track selectedType = 'All';
    @track error;

    showFlow = false;

    channelName = '/data/Property_Inspection__ChangeEvent';
    subscription = null;

    
    wiredInspectionsResult;
    wiredRatingResult;
    
    // Status filter options
    statusOptions = [
        { label: 'All Statuses', value: 'All' },
        { label: 'Scheduled', value: 'Scheduled' },
        { label: 'In Progress', value: 'In Progress' },
        { label: 'Completed', value: 'Completed' },
        { label: 'Failed', value: 'Failed' }
    ];
    
    // Type filter options
    typeOptions = [
        { label: 'All Types', value: 'All' },
        { label: 'Initial', value: 'Initial' },
        { label: 'Annual', value: 'Annual' },
        { label: 'Move-Out', value: 'Move-Out' },
        { label: 'Maintenance', value: 'Maintenance' }
    ];
    

    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    account;
    
    @wire(getInspections, { accountId: '$recordId' })
    wiredInspections(result) {
        this.wiredInspectionsResult = result;
        if (result.data) {
            this.inspections = result.data.map(inspection => {
                return {
                    ...inspection,
                    statusClass: this.getStatusClass(inspection.Inspection_Status__c),
                    formattedDate: this.formatDate(inspection.Inspection_Date__c),
                    ratingStars: this.getRatingStars(inspection.Overall_Rating__c)
                };
            });
            this.applyFilters();
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.inspections = [];
            this.filteredInspections = [];
        }
    }
    
    @wire(getAverageRating, { accountId: '$recordId' })
    wiredRating(result) {
        this.wiredRatingResult = result;
        if (result.data !== undefined && result.data !== null) {
            this.averageRating = Number(result.data).toFixed(2);
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.averageRating = 0;
        }
    }

    connectedCallback() {
        this.registerErrorListener();
        this.subscribeToCDC();
    }

    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription, () => {
                this.subscription = null;
                console.log('Unsubscribed from CDC');
            });
        }
    }


    
    get hasInspections() {
        return this.filteredInspections && this.filteredInspections.length > 0;
    }
    
    get noInspectionsMessage() {
        if (this.selectedStatus !== 'All' || this.selectedType !== 'All') {
            return 'No inspections match the selected filters.';
        }
        return 'No inspections found for this property. Click "Schedule New Inspection" to get started.';
    }
    
    get propertyName() {
        return getFieldValue(this.account.data, ACCOUNT_FIELDS[0]);
    }
    
    get ratingStars() {
        return this.getRatingStars(this.averageRating);
    }
    
    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        this.applyFilters();
    }
    
    handleTypeChange(event) {
        this.selectedType = event.detail.value;
        this.applyFilters();
    }
    
    applyFilters() {
        this.filteredInspections = this.inspections.filter(inspection => {
            const statusMatch = this.selectedStatus === 'All' || 
                              inspection.Inspection_Status__c === this.selectedStatus;
            const typeMatch = this.selectedType === 'All' || 
                            inspection.Inspection_Type__c === this.selectedType;
            return statusMatch && typeMatch;
        });
    }
    
    get flowInputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    subscribeToCDC() {
        if (this.subscription) {
            return; // prevent double subscription
        }

        subscribe(this.channelName, -1, (event) => {
            this.handleInspectionChange(event);
        }).then(response => {
            this.subscription = response;
            console.log('Subscribed to CDC:', response.channel);
        });
    }


    handleInspectionChange(event) {
        const payload = event.data.payload;

        const relatedPropertyId = payload.Related_Property__c;

        if (relatedPropertyId === this.recordId) {
            this.handleRefresh();
        }
    }

    registerErrorListener() {
        onError(error => {
            console.error('CDC error: ', JSON.stringify(error));
        });
    }


    handleScheduleInspection() {
        this.showFlow = true;
    }

    closeFlow() {
        this.showFlow = false;
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.showFlow = false;

        }
    }
    
    handleRefresh() {
        return Promise.all([
            refreshApex(this.wiredInspectionsResult),
            refreshApex(this.wiredRatingResult)
        ]).then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Inspection data refreshed',
                    variant: 'success'
                })
            );
        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error refreshing data',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    }
    
    handleViewInspection(event) {
        const inspectionId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: inspectionId,
                actionName: 'view'
            }
        });
    }
    
    getStatusClass(status) {
        switch(status) {
            case 'Completed':
                return 'status-completed';
            case 'In Progress':
                return 'status-in-progress';
            case 'Failed':
                return 'status-failed';
            case 'Scheduled':
                return 'status-scheduled';
            default:
                return '';
        }
    }
    
    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric' 
        });
    }
    
    getRatingStars(rating) {
        if (!rating) return '☆☆☆☆☆';
        const fullStars = Math.floor(rating);
        const emptyStars = 5 - fullStars;
        return '★'.repeat(fullStars) + '☆'.repeat(emptyStars);
    }
}