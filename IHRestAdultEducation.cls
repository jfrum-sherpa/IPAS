/******************************************************************************
 * Author: Mark Carlo Mempin @ Cloudsherpas
 * Date: January 6, 2015
 * Descpription: This web service method will be called get Dashboard (Medical Expenses)
Below set of input parameters can be passed in request to create user successfully.
 ******************************************************************************/

@RestResource(urlMapping='/IHRestAdultEducation/v1/*')
global class IHRestAdultEducation {
	
	public String AppId;
	public String Token;
	public String SchName;
	public String SchCity;
	public String SchZip;
	public String SchGradDate;
	public String DegreeAA;
	public String DegreeAS;
	public String DegreeBA;
	public String DegreeBS;
	public String DegreeOther;
	public String DegreeCosts;
	public String ESingature;
	
	public static IHRestAdultEducation parse(String json) {
		return (IHRestAdultEducation) System.JSON.deserialize(json, IHRestAdultEducation.class);
	}

	/******************************************************************************
	 * Author: Mark Carlo Mempin @ Cloudsherpas
	 * Date: January 6, 2015
	 * Descpription: POST method for IHRestAdultEducation
	 * Comment: Some of the field where not yet available on Application Object
	 ******************************************************************************/
	 @HttpPost
	 global static void createAdultEducationApplication(){
	 	
	 	RestRequest req = RestContext.request;
		system.debug('***POST Request = ' + req);
		
        String reqBody = req.requestBody.toString();
        system.debug('***POST reqBody = ' + reqBody);
        
	    RestResponse res = RestContext.response;
	    system.debug('***POST Response = ' + res);
	    
	    try{
	    	IHRestAdultEducation adultEducationParse = IHRestAdultEducation.parse(reqBody);
	    	system.debug('*** POST adultEducationParse = ' + adultEducationParse);
	    	
	    	String pToken = adultEducationParse.Token;
		    system.debug('*** POST pToken = ' + pToken);
		    
		    String PappId = adultEducationParse.AppId;
		    system.debug('***PappId = ' + PappId);
		    
		    //Check if theres an Application GUID passed in the parameter, if there's any then update
		    list<Application__c> existingApplicationListForUpdate = new list<Application__c>();
		    Application__c app = new Application__c();
		    
		    if(PappId!=null || PappId!=''){
		    	//Some of the fields where not yet available in the Application Object
		    	existingApplicationListForUpdate = [Select Id,
																Application_GUID__c,
																High_School_Name__c,
																SS_Graduation_Date__c,
																SS_Degree_or_Certificate_being_Pursued__c,
																Other_Education_Cost__c
																
														 From Application__c
														 Where Application_GUID__c =: PappId];
		    }
		    system.debug('***existingApplicationListForUpdate = ' + existingApplicationListForUpdate);
		    
		    list<Application__c> tempAppListForUpdate = new list<Application__c>();
		    //Check if there's an existing Application record for update
		    if(existingApplicationListForUpdate.size()>0){
		    	for(Application__c appToUpdate: existingApplicationListForUpdate){
		    		
		    		appToUpdate.High_School_Name__c = adultEducationParse.SchName;
		    		appToUpdate.SS_Graduation_Date__c = adultEducationParse.SchGradDate;
		    		appToUpdate.Other_Education_Cost__c = Decimal.valueOf(adultEducationParse.DegreeCosts);
		    		appToUpdate.SS_Degree_or_Certificate_being_Pursued__c = adultEducationParse.DegreeAA;
		    		
		    		tempAppListForUpdate.add(appToUpdate);
		    	}
		    }else{
		    	//Create/Insert the application record based on the parameter passed
				app.High_School_Name__c = adultEducationParse.SchName;
	    		app.SS_Graduation_Date__c = adultEducationParse.SchGradDate;
	    		app.Other_Education_Cost__c = Decimal.valueOf(adultEducationParse.DegreeCosts);
	    		app.SS_Degree_or_Certificate_being_Pursued__c = adultEducationParse.DegreeAA;
				    
				insert app;
		    }
		    
		    system.debug('*** tempAppListForUpdate = ' + tempAppListForUpdate);
		    if(tempAppListForUpdate.size()>0){
		    	update tempAppListForUpdate;
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
	 * Date: January 6, 2015
	 * Descpription: GET method for Adult Education
	 ******************************************************************************/
	 @HttpGet
	 global static IHRestAdultEducation getAdultEducation(){
	 	
	 	string applicationID = RestContext.request.params.get('AppId');
		system.debug('***applicationID = ' + applicationID);
		
		list<Application__c> appExistingAppList = new list<Application__c>();
		if(applicationID!=null || applicationID!=''){
			//Will add some fields that are not yet available on the Application Object
			appExistingAppList = [Select Id,
										  Application_GUID__c,
										  High_School_Name__c,
										  SS_Graduation_Date__c,
										  SS_Degree_or_Certificate_being_Pursued__c,
										  Other_Education_Cost__c
						   
		                           From Application__c 
		                           WHERE Id =: applicationId];
		}
		system.debug('***appExistingAppList = ' + appExistingAppList);
	 	
	 	IHRestAdultEducation adultEducationParse = new IHRestAdultEducation();
		//Check if there's an existing Application for that applicationId passed in the requestURI
		//If it has then populate the return the params
		if(appExistingAppList.size()>0){
			for (Application__c appToReturn : appExistingAppList){
				
				adultEducationParse.DegreeAA = appToReturn.SS_Degree_or_Certificate_being_Pursued__c;
			    adultEducationParse.SchName = appToReturn.High_School_Name__c;
			    adultEducationParse.SchGradDate = appToReturn.SS_Graduation_Date__c;
			    adultEducationParse.DegreeCosts =  String.valueOf(appToReturn.Other_Education_Cost__c);
			}
		}
		
		return adultEducationParse;
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