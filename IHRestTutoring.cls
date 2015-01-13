/******************************************************************************
 * Author: Mark Carlo Mempin @ Cloudsherpas
 * Date: January 5, 2015
 * Descpription: This web service method will be called get Dashboard (Medical Expenses)
Below set of input parameters can be passed in request to create user successfully.
 ******************************************************************************/

@RestResource(urlMapping='/IHRestTutoring/v1/*')
global class IHRestTutoring {
	
	public String AppId;
	public String Token;
	public String TLTutoring;
	public String TLLesson;
	public String TLName;
	public String TLAdd1;
	public String TLAdd2;
	public String TLCity;
	public String TLZip;
	public String TLGradDate;
	public String TLSchName;
	public String TLSchAdd1;
	public String TLSchAdd2;
	public String TLState;
	public String TLPrincipalName;
	public String TLEmail;
	public List<SupportDocuments> supportDocumentsList;
	public String ESingature;
	
	class SupportDocuments {
		public String SupportDocument;
	}
	
	public static IHRestTutoring parse(String json) {
		return (IHRestTutoring) System.JSON.deserialize(json, IHRestTutoring.class);
	}
	
	/******************************************************************************
	 * Author: Mark Carlo Mempin @ Cloudsherpas
	 * Date: January 5, 2015
	 * Descpription: POST method for IHRestTutoring
	 ******************************************************************************/
	 @HttpPost
	 global static void createTutoringApplication(){
	 	
	 	RestRequest req = RestContext.request;
		system.debug('***POST Request = ' + req);
		
        String reqBody = req.requestBody.toString();
        system.debug('***POST reqBody = ' + reqBody);
        
	    RestResponse res = RestContext.response;
	    system.debug('***POST Response = ' + res);
	    
	    try{
	    	IHRestTutoring tutoringParse = IHRestTutoring.parse(reqBody);
	    	system.debug('*** POST tutoringParse = ' + tutoringParse);
	    	
	    	String pToken = tutoringParse.Token;
		    system.debug('*** POST pToken = ' + pToken);
		    
		    String PappId = tutoringParse.AppId;
		    system.debug('***PappId = ' + PappId);
		    
		    //Check if theres an Application GUID passed in the parameter, if there's any then update
		    list<Application__c> existingApplicationListForUpdate = new list<Application__c>();
		    Application__c app = new Application__c();
		    
		    if(PappId!=null || PappId!=''){
		    	existingApplicationListForUpdate = [Select Id,
																Application_GUID__c,
																Tutoring_Center_Address_1__c,
																Tutoring_Center_Address_2__c,
																Tutoring_Center_City__c,
																Tutoring_Center_Name__c,
																Tutoring_Center_State__c,
																Tutoring_Center_Zip__c,
																Tutoring_Type__c
																
														 From Application__c
														 Where Application_GUID__c =: PappId];
		    }
		    system.debug('***existingApplicationListForUpdate = ' + existingApplicationListForUpdate);
		    
		    list<Application__c> tempAppListForUpdate = new list<Application__c>();
		    //Check if there's an existing Application record for update
		    if(existingApplicationListForUpdate.size()>0){
		    	for(Application__c appToUpdate: existingApplicationListForUpdate){
		    		
		    		appToUpdate.Tutoring_Center_Address_1__c = tutoringParse.TLAdd1;
		    		appToUpdate.Tutoring_Center_Address_2__c = tutoringParse.TLAdd2;
		    		appToUpdate.Tutoring_Center_City__c = tutoringParse.TLCity;
		    		appToUpdate.Tutoring_Center_Name__c = tutoringParse.TLName;
		    		appToUpdate.Tutoring_Center_State__c = tutoringParse.TLState;
		    		appToUpdate.Tutoring_Center_Zip__c = tutoringParse.TLZip;
		    		
		    		tempAppListForUpdate.add(appToUpdate);
		    	}
		    }else{
		    	//Create/Insert the application record based on the parameter passed
				app.Tutoring_Center_Address_1__c = tutoringParse.TLAdd1;
	    		app.Tutoring_Center_Address_2__c = tutoringParse.TLAdd2;
	    		app.Tutoring_Center_City__c = tutoringParse.TLCity;
	    		app.Tutoring_Center_Name__c = tutoringParse.TLName;
	    		app.Tutoring_Center_State__c = tutoringParse.TLState;
	    		app.Tutoring_Center_Zip__c = tutoringParse.TLZip;
				    
				insert app;
		    }
		    
		    system.debug('*** tempAppListForUpdate = ' + tempAppListForUpdate);
		    if(tempAppListForUpdate.size()>0){
		    	update tempAppListForUpdate;
		    }
		    
		    //Check on the list of Supporting Document passed on the parameter if it has values
		    list<Supporting_Document__c> tempSupDocList = new list<Supporting_Document__c>();
		    Supporting_Document__c supDocToInsert = new Supporting_Document__c();
		    if (tutoringParse.supportDocumentsList.size()>0){
	   	    System.Debug('***applicationId = ' + app.Id);
	   	    
	   	    	for(IHRestTutoring.SupportDocuments supDoc: tutoringParse.supportDocumentsList){
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
	global static IHRestTutoring getTutoring(){
		
		string applicationID = RestContext.request.params.get('AppId');
		system.debug('***applicationID = ' + applicationID);
		
		list<Application__c> appExistingAppList = new list<Application__c>();
		list<Supporting_Document__c> existingSupDocumentList = new list<Supporting_Document__c>();
		if(applicationID!=null || applicationID!=''){
			//Will add some fields that are not yet available on the Application Object
			appExistingAppList = [Select Id,
										  Application_GUID__c,
										  Tutoring_Center_Address_1__c,
										  Tutoring_Center_Address_2__c,
										  Tutoring_Center_City__c,
										  Tutoring_Center_Name__c,
										  Tutoring_Center_State__c,
										  Tutoring_Center_Zip__c,
										  Tutoring_Type__c
						   
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
		
		IHRestTutoring tutoringParse = new IHRestTutoring();
		//Check if there's an existing Application for that applicationId passed in the requestURI
		//If it has then populate the return the params 
		if(appExistingAppList.size()>0){
			for (Application__c appToReturn : appExistingAppList){
				
				tutoringParse.AppId = appToReturn.Id;
				tutoringParse.TLAdd1 = appToReturn.Tutoring_Center_Address_1__c;
				tutoringParse.TLAdd2 = appToReturn.Tutoring_Center_Address_2__c;
				tutoringParse.TLCity = appToReturn.Tutoring_Center_City__c;
				tutoringParse.TLName = appToReturn.Tutoring_Center_Name__c;
				tutoringParse.TLZip = appToReturn.Tutoring_Center_Zip__c;
				tutoringParse.TLState = appToReturn.Tutoring_Center_State__c;
			}
		}
		
		IHRestTutoring.SupportDocuments iRestSupDoc = new IHRestTutoring.SupportDocuments();
		if(existingSupDocumentList.size()>0){
			for(Supporting_Document__c supDocToAsso: existingSupDocumentList){
				iRestSupDoc.SupportDocument = supDocToAsso.Name;
				
				tutoringParse.supportDocumentsList.add(iRestSupDoc);
			}
		}
		
		return tutoringParse;
	}
	
	 
	 /******************************************************************************
	 * Author: Mark Carlo Mempin @ Cloudsherpas
	 * Date: January 5, 2015
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