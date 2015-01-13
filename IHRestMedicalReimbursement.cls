/******************************************************************************
 * Author: Mark Carlo Mempin @ Cloudsherpas
 * Date: January 6, 2015
 * Descpription: This web service method will be called get Dashboard (Medical Expenses)
Below set of input parameters can be passed in request to create user successfully.
 ******************************************************************************/

@RestResource(urlMapping='/IHRestMedicalReimbursement/v1/*')
global class IHRestMedicalReimbursement {
	
	public String AppId;
	public String Token;
	public String UserOverNight;
	public String UserTransport;
	public String UserChildCare;
	public String UserMedEval;
	public String UserDentEval;
	public String UserReimbursent;
	public String UserThreeMonthCover;
	public String UserOther;
	public String UserOtherText;
	public String DiagPhyName;
	public String DiagPhyPhone;
	public String DiagHTCName;
	public String DiagHTCContact;
	public String DiagHTCAdd1;
	public String DiagHTCAdd2;
	public String DiagHTCCity;
	public String DiagHTCState;
	public String DiagHTCZipCode;
	public String InsName;
	public String InsPhone;
	public String InsSubName;
	public String InsGroupNum;
	public String InsSubNum;
	public String InsBirthYear;
	public List<SupportDocuments> SupportDocuments;
	public String ESingature;
	
	class SupportDocuments {
		public String SupportDocument;
	}
	
	public static IHRestMedicalReimbursement parse(String json) {
		return (IHRestMedicalReimbursement) System.JSON.deserialize(json, IHRestMedicalReimbursement.class);
	}
	
	/******************************************************************************
	 * Author: Mark Carlo Mempin @ Cloudsherpas
	 * Date: January 6, 2015
	 * Descpription: POST method for IHRestMedicalReimbursement
	 ******************************************************************************/
	 @HttpPost
	 global static void createMedicalReimbursementApplication(){
	 	
	 	RestRequest req = RestContext.request;
		system.debug('***POST Request = ' + req);
		
        String reqBody = req.requestBody.toString();
        system.debug('***POST reqBody = ' + reqBody);
        
	    RestResponse res = RestContext.response;
	    system.debug('***POST Response = ' + res);
	    
	    try{
	    	IHRestMedicalReimbursement medicalReimbursementParse = IHRestMedicalReimbursement.parse(reqBody);
	    	system.debug('*** POST medicalReimbursementParse = ' + medicalReimbursementParse);
	    	
	    	String pToken = medicalReimbursementParse.Token;
		    system.debug('*** POST pToken = ' + pToken);
		    
		    String PappId = medicalReimbursementParse.AppId;
		    system.debug('***PappId = ' + PappId);
		    
		    //Check if theres an Application GUID passed in the parameter, if there's any then update
		    list<Application__c> existingApplicationListForUpdate = new list<Application__c>();
		    Application__c app = new Application__c();
	    	
	    	if(PappId!=null || PappId!=''){
		    	//Some of the fields for Medical Reimbursement Application are not availble on the object
		    	existingApplicationListForUpdate = [Select Id,
																Application_GUID__c,
																MR_Child_Care_Expenses__c,
																MR_Dental_Evaluation_Reimbursement__c,
																MR_Medical_Aid_Reimbursement__c,
																MR_Medical_Evaluation_Reimbursement__c,
																MR_Meetings_Reimbursement__c,
																MR_Other_Reimbursement__c,
																MR_Other_Text__c,
																MR_Overnight_Accomodations_Reimbursement__c,
																MR_Prescription_Coverage_Reimbursement__c,
																MR_Transportation_Reimbursement__c
																
														 From Application__c
														 Where Application_GUID__c =: PappId];
		    }
		    system.debug('***existingApplicationListForUpdate = ' + existingApplicationListForUpdate);
		    
		    list<Application__c> tempAppListForUpdate = new list<Application__c>();
		    //Check if there's an existing Application record for update
		    if(existingApplicationListForUpdate.size()>0){
		    	for(Application__c appToUpdate: existingApplicationListForUpdate){
		    		
		    		appToUpdate.MR_Overnight_Accomodations_Reimbursement__c = boolean.valueOf(medicalReimbursementParse.UserOverNight); //- field is a boolean. I check the value that is on the request body but it's a number.
		    		appToUpdate.MR_Transportation_Reimbursement__c = boolean.valueOf(medicalReimbursementParse.UserTransport); //- field is a boolean. I check the value that is on the request body but it's a number.
		    		appToUpdate.MR_Child_Care_Expenses__c = boolean.valueOf(medicalReimbursementParse.UserChildCare); //- field is a boolean. I check the value that is on the request body but it's a number.
		    		appToUpdate.MR_Dental_Evaluation_Reimbursement__c = boolean.valueOf(medicalReimbursementParse.UserDentEval); //- field is a boolean. I check the value that is on the request body but it's a number.
		    		appToUpdate.MR_Medical_Evaluation_Reimbursement__c = boolean.valueOf(medicalReimbursementParse.UserMedEval); //- field is a boolean. I check the value that is on the request body but it's a number.
		    		appToUpdate.MR_Other_Reimbursement__c = boolean.valueOf(medicalReimbursementParse.UserOther); //- field is a boolean. I check the value that is on the request body but it's a number.
		    		appToUpdate.MR_Other_Text__c = medicalReimbursementParse.UserOtherText;
		    		
		    		tempAppListForUpdate.add(appToUpdate);
		    	}
		    }else{
		    	//Create/Insert the application record based on the parameter passed
				app.MR_Overnight_Accomodations_Reimbursement__c = boolean.valueOf(medicalReimbursementParse.UserOverNight);
	    		app.MR_Transportation_Reimbursement__c = boolean.valueOf(medicalReimbursementParse.UserTransport);
	    		app.MR_Child_Care_Expenses__c = boolean.valueOf(medicalReimbursementParse.UserChildCare);
	    		app.MR_Dental_Evaluation_Reimbursement__c = boolean.valueOf(medicalReimbursementParse.UserDentEval);
	    		app.MR_Medical_Evaluation_Reimbursement__c = boolean.valueOf(medicalReimbursementParse.UserMedEval);
	    		app.MR_Other_Reimbursement__c = boolean.valueOf(medicalReimbursementParse.UserOther);
	    		app.MR_Other_Text__c = medicalReimbursementParse.UserOtherText;
				    
				insert app;
		    }
		    
		    system.debug('*** tempAppListForUpdate = ' + tempAppListForUpdate);
		    if(tempAppListForUpdate.size()>0){
		    	update tempAppListForUpdate;
		    }
		    
		    //Check on the list of Supporting Document passed on the parameter if it has values
		    list<Supporting_Document__c> tempSupDocList = new list<Supporting_Document__c>();
		    Supporting_Document__c supDocToInsert = new Supporting_Document__c();
		    
	    	if (medicalReimbursementParse.SupportDocuments.size()>0){
	   	    System.Debug('***applicationId = ' + app.Id);
	   	    
	   	    	for(IHRestMedicalReimbursement.SupportDocuments supDoc: medicalReimbursementParse.SupportDocuments){
	   	    		supDocToInsert.Application__c = app.Id;
	   	    		supDocToInsert.Document_Name__c = supDoc.SupportDocument;
	   	    		
	   	    		tempSupDocList.add(supDocToInsert);
	   	    	}
	   	    }
	   	    
	   	    system.debug('***tempSupDocList = ' + tempSupDocList);
	   	    if(tempSupDocList.size()>0){
	   	    	update tempSupDocList;
	   	    }
	    	
	    	//Call the success JSON
		    res.responseBody = blob.valueOf(successResponse(app.Id));
		    
	    }catch(Exception ex){
	    	//Call the ErrorGeneratorResponse class if it fails
	    	res.responseBody =  blob.valueOf(ErrorGeneratorResponse.errorResponse('0',ex.getMessage()));
	    }
	 }
	 
	 /******************************************************************************
	 * Author: Mark Carlo Mempin @ Cloudsherpas
	 * Date: January 5, 2015
	 * Descpription: GET method for Tutoring
	 ******************************************************************************/
	 @HttpGet
	 global static IHRestMedicalReimbursement getMedicalReimbursement(){
	 	
	 	string applicationID = RestContext.request.params.get('AppId');
		system.debug('***applicationID = ' + applicationID);
		
		list<Application__c> appExistingAppList = new list<Application__c>();
		list<Supporting_Document__c> existingSupDocumentList = new list<Supporting_Document__c>();
		
		if(applicationID!=null || applicationID!=''){
			//Will add some fields that are not yet available on the Application Object
			appExistingAppList = [Select Id,
										  Application_GUID__c,
										  MR_Child_Care_Expenses__c,
										  MR_Dental_Evaluation_Reimbursement__c,
										  MR_Medical_Aid_Reimbursement__c,
										  MR_Medical_Evaluation_Reimbursement__c,
										  MR_Meetings_Reimbursement__c,
										  MR_Other_Reimbursement__c,
										  MR_Other_Text__c,
										  MR_Overnight_Accomodations_Reimbursement__c,
										  MR_Prescription_Coverage_Reimbursement__c,
										  MR_Transportation_Reimbursement__c
						   
		                           From Application__c 
		                           WHERE Id =: applicationId];
		                           
		    existingSupDocumentList = [Select Id,
		    								  Name,
		    								  Application__c,
		    								  Document_Name__c
		    								  
    								  From Supporting_Document__c
    								  Where Application__c =: applicationId];
		    
		}
		system.debug('***appExistingAppList = ' + appExistingAppList);
		system.debug('***existingSupDocumentList = ' + existingSupDocumentList);
	 	
	 	IHRestMedicalReimbursement medicalReimbursementParse = new IHRestMedicalReimbursement();
	 	//Check if there's an existing Application for that applicationId passed in the requestURI
		//If it has then populate the return the params 
		if(appExistingAppList.size()>0){
			for (Application__c appToReturn : appExistingAppList){
				
				medicalReimbursementParse.UserOverNight = String.valueOf(appToReturn.MR_Overnight_Accomodations_Reimbursement__c);
	    		medicalReimbursementParse.UserTransport = String.valueOf(appToReturn.MR_Transportation_Reimbursement__c);
	    		medicalReimbursementParse.UserChildCare = String.valueOf(appToReturn.MR_Child_Care_Expenses__c);
	    		medicalReimbursementParse.UserDentEval = String.valueOf(appToReturn.MR_Dental_Evaluation_Reimbursement__c);
	    		medicalReimbursementParse.UserMedEval = String.valueOf(appToReturn.MR_Medical_Evaluation_Reimbursement__c);
	    		medicalReimbursementParse.UserOther = String.valueOf(appToReturn.MR_Other_Reimbursement__c);
	    		medicalReimbursementParse.UserOtherText = appToReturn.MR_Other_Text__c;
				
			}
		}
		
		IHRestMedicalReimbursement.SupportDocuments iRestSupDoc = new IHRestMedicalReimbursement.SupportDocuments();
		if(existingSupDocumentList.size()>0){
			for(Supporting_Document__c supDocToAsso: existingSupDocumentList){
				iRestSupDoc.SupportDocument = supDocToAsso.Name;
				
				medicalReimbursementParse.SupportDocuments.add(iRestSupDoc);
			}
		}
		
	 	return medicalReimbursementParse;
	 }
	 
	 /******************************************************************************
	 * Author: Mark Carlo Mempin @ Cloudsherpas
	 * Date: January 6, 2015
	 * Descpription: This method will serve as the SuccessResponse JSON
	 ******************************************************************************/
	public static string successResponse(string message){
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeFieldName('reply');
			gen.writeStartObject();
				gen.writeStringField('status' , '1');
				gen.writeStringField('AppID' ,   message);
				gen.writeFieldName('Errors');
					gen.writeStartArray() ;
					gen.writeStartObject();
					gen.writeStringField('error' , '');
					gen.writeStringField('value' , '');
					gen.writeEndObject();
					gen.writeEndArray();
			gen.writeEndObject();
		gen.writeEndObject();
		return gen.getAsString();
    }
	 
}