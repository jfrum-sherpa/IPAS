/******************************************************************************
 * Author: Mark Carlo Mempin @ Cloudsherpas
 * Date: January 6, 2015
 * Descpription: This web service method will be called get Dashboard (Medical Expenses)
Below set of input parameters can be passed in request to create user successfully.
 ******************************************************************************/

@RestResource(urlMapping='/IHRestPhysicalActivity/v1/*')
global class IHRestPhysicalActivity {
	
	public String AppId;
	public String Token;
	public String InstName;
	public String InstAdd1;
	public String InstCity;
	public String InstZip;
	public String PhysHealthClub;
	public String PhysYoga;
	public String PhysSwimming;
	public String PhysHomeTraining;
	public String PhysOther;
	public String PhysPhyName;
	public String PhysPhyPhone;
	public String PhysHTCName;
	public String PhysHTCContact;
	public String PhysHTCAdd1;
	public String PhysHTCAdd2;
	public String PhysHTCCity;
	public String PhysHTCState;
	public String PhysHTCZipCode;
	public List<SupportDocuments> SupportDocuments;
	public String ESingature;
	
	class SupportDocuments {
		public String SupportDocument;
	}
	
	public static IHRestPhysicalActivity parse(String json) {
		return (IHRestPhysicalActivity) System.JSON.deserialize(json, IHRestPhysicalActivity.class);
	}
	
	/******************************************************************************
	 * Author: Mark Carlo Mempin @ Cloudsherpas
	 * Date: January 6, 2015
	 * Descpription: POST method for IHRestPhysicalActivity
	 ******************************************************************************/
	 @HttpPost
	 global static void createPhysicalActivityApplication(){
	 	RestRequest req = RestContext.request;
		system.debug('***POST Request = ' + req);
		
        String reqBody = req.requestBody.toString();
        system.debug('***POST reqBody = ' + reqBody);
        
	    RestResponse res = RestContext.response;
	    system.debug('***POST Response = ' + res);
	    
	    try{
	    	IHRestPhysicalActivity physicalActivityParse = IHRestPhysicalActivity.parse(reqBody);
	    	system.debug('*** POST physicalActivityParse = ' + physicalActivityParse);
	    	
	    	String pToken = physicalActivityParse.Token;
		    system.debug('*** POST pToken = ' + pToken);
		    
		    String PappId = physicalActivityParse.AppId;
		    system.debug('***PappId = ' + PappId);
		    
		    //Check if theres an Application GUID passed in the parameter, if there's any then update
		    list<Application__c> existingApplicationListForUpdate = new list<Application__c>();
		    Application__c app = new Application__c();
		    
		    if(PappId!=null || PappId!=''){
		    	//Some of the fields for Physical Activity Application are not availble on the object
		    	existingApplicationListForUpdate = [Select Id,
																Application_GUID__c,
																Physical_Activity_Phys_Name__c,
																Physical_Activity_Phys_Phone__c,
																Physical_Activity_Other__c,
																Physical_Activity_Institution_Zip__c,
																Physical_Activity_Institution_State__c,
																Physical_Activity_Institution_Name__c,
																Physical_Activity_Institution_City__c,
																Physical_Activity_Institution_Address_2__c,
																Physical_Activity_Institution_Address_1__c,
																Physical_Activity_Cost__c,
																Physical_Activity__c
																
														 From Application__c
														 Where Application_GUID__c =: PappId];
		    }
		    system.debug('***existingApplicationListForUpdate = ' + existingApplicationListForUpdate);
		    
		    list<Application__c> tempAppListForUpdate = new list<Application__c>();
		    //Check if there's an existing Application record for update
		    if(existingApplicationListForUpdate.size()>0){
		    	for(Application__c appToUpdate: existingApplicationListForUpdate){
		    		
		    		appToUpdate.Physical_Activity_Institution_Name__c = physicalActivityParse.InstName;
		    		appToUpdate.Physical_Activity_Institution_Address_1__c = physicalActivityParse.InstAdd1;
		    		appToUpdate.Physical_Activity_Institution_Address_2__c = physicalActivityParse.PhysHTCAdd2;
		    		appToUpdate.Physical_Activity_Institution_City__c = physicalActivityParse.InstCity;
		    		appToUpdate.Physical_Activity_Institution_Zip__c = physicalActivityParse.InstZip;
		    		appToUpdate.Physical_Activity_Other__c = physicalActivityParse.PhysOther;
		    		appToUpdate.Physical_Activity_Phys_Name__c = physicalActivityParse.PhysPhyName;
		    		appToUpdate.Physical_Activity_Phys_Phone__c = physicalActivityParse.PhysPhyPhone;
		    		
		    		tempAppListForUpdate.add(appToUpdate);
		    	}
		    }else{
		    	//Create/Insert the application record based on the parameter passed
				app.Physical_Activity_Institution_Name__c = physicalActivityParse.InstName;
	    		app.Physical_Activity_Institution_Address_1__c = physicalActivityParse.InstAdd1;
	    		app.Physical_Activity_Institution_Address_2__c = physicalActivityParse.PhysHTCAdd2;
	    		app.Physical_Activity_Institution_City__c = physicalActivityParse.InstCity;
	    		app.Physical_Activity_Institution_Zip__c = physicalActivityParse.InstZip;
	    		app.Physical_Activity_Other__c = physicalActivityParse.PhysOther;
	    		app.Physical_Activity_Phys_Name__c = physicalActivityParse.PhysPhyName;
	    		app.Physical_Activity_Phys_Phone__c = physicalActivityParse.PhysPhyPhone;
				    
				insert app;
		    }
		    
		    system.debug('*** tempAppListForUpdate = ' + tempAppListForUpdate);
		    if(tempAppListForUpdate.size()>0){
		    	update tempAppListForUpdate;
		    }
		    
		    //Check on the list of Supporting Document passed on the parameter if it has values
		    list<Supporting_Document__c> tempSupDocList = new list<Supporting_Document__c>();
		    Supporting_Document__c supDocToInsert = new Supporting_Document__c();
		    if (physicalActivityParse.SupportDocuments.size()>0){
	   	    System.Debug('***applicationId = ' + app.Id);
	   	    
	   	    	for(IHRestPhysicalActivity.SupportDocuments supDoc: physicalActivityParse.SupportDocuments){
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
	 global static IHRestPhysicalActivity getPhysicalActivity(){
	 	
	 	string applicationID = RestContext.request.params.get('AppId');
		system.debug('***applicationID = ' + applicationID);
		
		list<Application__c> appExistingAppList = new list<Application__c>();
		list<Supporting_Document__c> existingSupDocumentList = new list<Supporting_Document__c>();
		
		if(applicationID!=null || applicationID!=''){
			//Will add some fields that are not yet available on the Application Object
			appExistingAppList = [Select Id,
										  Application_GUID__c,
										  Physical_Activity_Phys_Name__c,
										  Physical_Activity_Phys_Phone__c,
										  Physical_Activity_Other__c,
										  Physical_Activity_Institution_Zip__c,
										  Physical_Activity_Institution_State__c,
										  Physical_Activity_Institution_Name__c,
										  Physical_Activity_Institution_City__c,
										  Physical_Activity_Institution_Address_2__c,
										  Physical_Activity_Institution_Address_1__c,
										  Physical_Activity_Cost__c,
										  Physical_Activity__c
						   
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
	 	
	 	IHRestPhysicalActivity physicalActivityParse = new IHRestPhysicalActivity();
	 	//Check if there's an existing Application for that applicationId passed in the requestURI
		//If it has then populate the return the params 
		
		if(appExistingAppList.size()>0){
			for (Application__c appToReturn : appExistingAppList){
				
				physicalActivityParse.AppId = appToReturn.Id;
				physicalActivityParse.InstName = appToReturn.Physical_Activity_Institution_Name__c;
	    		physicalActivityParse.InstAdd1 = appToReturn.Physical_Activity_Institution_Address_1__c;
	    		physicalActivityParse.PhysHTCAdd2 = appToReturn.Physical_Activity_Institution_Address_2__c;
	    		physicalActivityParse.InstCity = appToReturn.Physical_Activity_Institution_City__c;
	    		physicalActivityParse.InstZip = appToReturn.Physical_Activity_Institution_Zip__c;
	    		physicalActivityParse.PhysOther = appToReturn.Physical_Activity_Other__c;
	    		physicalActivityParse.PhysPhyName = appToReturn.Physical_Activity_Phys_Name__c;
	    		physicalActivityParse.PhysPhyPhone = appToReturn.Physical_Activity_Phys_Phone__c;
			}
		}
		
		IHRestPhysicalActivity.SupportDocuments iRestSupDoc = new IHRestPhysicalActivity.SupportDocuments();
		if(existingSupDocumentList.size()>0){
			for(Supporting_Document__c supDocToAsso: existingSupDocumentList){
				iRestSupDoc.SupportDocument = supDocToAsso.Name;
				
				physicalActivityParse.SupportDocuments.add(iRestSupDoc);
			}
		}
	 	
	 	return physicalActivityParse;
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