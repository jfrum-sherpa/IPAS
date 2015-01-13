/******************************************************************************
 * Author: Mark Carlo Mempin @ Cloudsherpas
 * Date: January 6, 2015
 * Descpription: This web service method will be called get Dashboard (Scholarship)
Below set of input parameters can be passed in request to create user successfully.
 ******************************************************************************/

@RestResource(urlMapping='/IHRestCounseling/v1/*')
global class IHRestCounseling {
	
	public String AppId;
	public String Token;
	public String CNSLBirth;
	public String CNSLJob;
	public String CNSLInterest;
	public String CNSLDrivers;
	public String CNSLObj;
	public String CNSLGoals;
	public String CNSLChall;
	public String CNSLContact;
	public String CNSLContactEntry;
	public String CNSLTime;
	public String CNSLConsider;
	
	public static IHRestCounseling parse(String json) {
		return (IHRestCounseling) System.JSON.deserialize(json, IHRestCounseling.class);
	}
	
	/******************************************************************************
	 * Author: Mark Carlo Mempin @ Cloudsherpas
	 * Date: January 6, 2015
	 * Descpription: POST method for IHRestCounseling
	 * Comment: Some of the field where not yet available on Application Object
	 ******************************************************************************/
	 @HttpPost
	 global static void createCounselingApplication(){
	 	
	 	RestRequest req = RestContext.request;
		system.debug('***POST Request = ' + req);
		
        String reqBody = req.requestBody.toString();
        system.debug('***POST reqBody = ' + reqBody);
        
	    RestResponse res = RestContext.response;
	    system.debug('***POST Response = ' + res);
	    
	    try{
	    	IHRestCounseling counselingParse = IHRestCounseling.parse(reqBody);
	    	system.debug('*** POST counselingParse = ' + counselingParse);
	    	
	    	String pToken = counselingParse.Token;
		    system.debug('*** POST pToken = ' + pToken);
		    
		    String PappId = counselingParse.AppId;
		    system.debug('***PappId = ' + PappId);
	    	
	    	//Check if theres an Application GUID passed in the parameter, if there's any then update
		    list<Application__c> existingApplicationListForUpdate = new list<Application__c>();
		    Application__c app = new Application__c();
		    
		    if(PappId!=null || PappId!=''){
		    	//Some of the fields where not yet available in the Application Object
		    	existingApplicationListForUpdate = [Select Id,
																Application_GUID__c
																//Fields are not yet available on Application object???
																
														 From Application__c
														 Where Application_GUID__c =: PappId];
		    }
		    system.debug('***existingApplicationListForUpdate = ' + existingApplicationListForUpdate);
		    
		    list<Application__c> tempAppListForUpdate = new list<Application__c>();
		    //Check if there's an existing Application record for update
		    if(existingApplicationListForUpdate.size()>0){
		    	for(Application__c appToUpdate: existingApplicationListForUpdate){
		    		
		    		//No fields yet for counseling?
		    		
		    		tempAppListForUpdate.add(appToUpdate);
		    	}
		    }else{
		    	//Create/Insert the application record based on the parameter passed
				    
				    //No fields yet for counseling?
				    
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
	 global static IHRestCounseling getCounseling(){
	 	
	 	string applicationID = RestContext.request.params.get('AppId');
		system.debug('***applicationID = ' + applicationID);
		
		list<Application__c> appExistingAppList = new list<Application__c>();
		if(applicationID!=null || applicationID!=''){
			//Will add some fields that are not yet available on the Application Object
			appExistingAppList = [Select Id,
										  Application_GUID__c
										  //Fields are not yet available on Application object???
						   
		                           From Application__c 
		                           WHERE Id =: applicationId];
		}
		system.debug('***appExistingAppList = ' + appExistingAppList);
		
		IHRestCounseling counselingParse = new IHRestCounseling();
		//Check if there's an existing Application for that applicationId passed in the requestURI
		//If it has then populate the return the params
		if(appExistingAppList.size()>0){
			for (Application__c appToReturn : appExistingAppList){
				
				//Fields are not yet available?
			}
		}
		
		return counselingParse;
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