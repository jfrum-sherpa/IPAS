/******************************************************************************
 * Author: Mark Carlo Mempin @ Cloudsherpas
 * Date: January 5, 2015
 * Descpription: This web service method will be called get Dashboard (HeroPath)
 * Below set of input parameters can be passed in request to create user successfully.
 ******************************************************************************/

@RestResource(urlMapping='/IHRestHeroPath/v1/*')
global class IHRestHeroPath {
	
	public String AppId;
	public String Token;
	public String HPGender;
	public String HPMPhone;
	public String HPHPhone;
	public String HPEmail;
	public String HPBirth;
	public String HPVocat; //Field not yet available on Application Object?
	public String HPHighSchool; //Is this the High_School_Name__c field in Application Object?
	public String HPVocatGrad; //Field not yet available on Application Object?
	public String HPHighSchoolGrad; //Field not yet available on Application Object?
	public String HPSomeCollege; //Field not yet available on Application Object?
	public String HPOther; 
	public String HpOtherText;
	public String HPEmployed;
	public String HPCareerNoPlan;
	public String HPCareerColledge;
	public String HPCareerThink;
	public String HPCareerIdea;
	public String HPCareerBegin;
	public String HPCareerHelp;
	public String HPCareerNoObstacle;
	public String HPCareerSoftware;
	public String HPCareer27;
	public String HPFriendNone;
	public String HPFriendAlone;
	public String HPFriendMore;
	public String HPFriendDeeper;
	public String HPFriendOpen;
	public String HPFriendConfid;
	public String HPFriendText;
	public String HPDatingMonk;
	public String HPDatingNotNow;
	public String HPDatingWorkOn;
	public String HPDatingBegin;
	public String HPDatingAdvice;
	public String HPDatingFine;
	public String HPDatingMarried;
	public String HPDatingText;
	public String HpGrowingStay;
	public String HPGrowingConcern;
	public String HPGrowingParent;
	public String HPGrowingThink;
	public String HPGrowingReady;
	public String HPGrowingText;
	public String HPTechNever;
	public String HPTechTool;
	public String HPTechSome;
	public String HPTechSig;
	public String HPTechText;
	public String HPEssayGuide;
	public String HPHeroText;
	public String HP18Years;
	public String HPIText;
	public String HPParent;
	public String HPReadHero;
	public String HPFuture;
	
	public static IHRestHeroPath parse(String json) {
		return (IHRestHeroPath) System.JSON.deserialize(json, IHRestHeroPath.class);
	}
	
	
	/******************************************************************************
	 * Author: Mark Carlo Mempin @ Cloudsherpas
	 * Date: January 5, 2015
	 * Descpription: POST method for creating Hero Path
	 ******************************************************************************/
	@HttpPost
	global static void createHeroPathApplication(){
		
		RestRequest req = RestContext.request;
		system.debug('***POST Request = ' + req);
		
        String reqBody = req.requestBody.toString();
        system.debug('***POST reqBody = ' + reqBody);
        
	    RestResponse res = RestContext.response;
	    system.debug('***POST Response = ' + res);
	    
	    try{
	    	IHRestHeroPath heroPathParse = IHRestHeroPath.parse(reqBody);
		    system.debug('*** POST heroPathParse = ' + heroPathParse);
		    
		    String pToken = heroPathParse.Token;
		    system.debug('*** POST pToken = ' + pToken);
		    
		    String PappId = heroPathParse.AppId;
		    system.debug('***PappId = ' + PappId);
		    
		    //Check if theres an Application GUID passed in the parameter, if there's any then update
		    list<Application__c> existingApplicationListForUpdate = new list<Application__c>();
		    Application__c app = new Application__c();
		    
		    if(PappId!=null || PappId!=''){
		    	existingApplicationListForUpdate = [Select Id,
																Application_GUID__c,
																HP_Gender__c,
																HP_Mobile_Phone__c,
																HP_Home_Phone__c,
																HP_Email__c,
																HP_Year_of_birth__c,
																High_School_Name__c,
																HP_18_or_older__c

														 From Application__c
														 Where Application_GUID__c =: PappId];
		    }
		    system.debug('***existingApplicationListForUpdate = ' + existingApplicationListForUpdate);
		    
		    list<Application__c> tempAppListForUpdate = new list<Application__c>();
		    //Check if there's an existing Application record for update
		    if(existingApplicationListForUpdate.size()>0){
		    	for(Application__c appToUpdate: existingApplicationListForUpdate){
		    		
		    		appToUpdate.HP_Gender__c = heroPathParse.HPGender;
				    appToUpdate.HP_Mobile_Phone__c = heroPathParse.HPMPhone;
				    appToUpdate.HP_Home_Phone__c = heroPathParse.HPHPhone;
				    appToUpdate.HP_Email__c = heroPathParse.HPEmail;
				    appToUpdate.HP_Year_of_birth__c = heroPathParse.HPBirth;
				    appToUpdate.High_School_Name__c = heroPathParse.HPHighSchool;
				    appToUpdate.HP_18_or_older__c = heroPathParse.HP18Years;
		    		
		    		tempAppListForUpdate.add(appToUpdate);
		    	}
		    }else{
		    	//Create/Insert the application record based on the parameter passed
				    app.HP_Gender__c = heroPathParse.HPGender;
				    app.HP_Mobile_Phone__c = heroPathParse.HPMPhone;
				    app.HP_Home_Phone__c = heroPathParse.HPHPhone;
				    app.HP_Email__c = heroPathParse.HPEmail;
				    app.HP_Year_of_birth__c = heroPathParse.HPBirth;
				    app.High_School_Name__c = heroPathParse.HPHighSchool;
				    app.HP_18_or_older__c = heroPathParse.HP18Years;
				    
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
	 * Date: January 5, 2015
	 * Descpription: GET method for Hero Path
	 ******************************************************************************/
	@HttpGet
	 global static IHRestHeroPath getHeroPath(){
	 	
		string applicationID = RestContext.request.params.get('AppId');
		system.debug('***applicationID = ' + applicationID);
		
		list<Application__c> appExistingAppList = new list<Application__c>();
		if(applicationID!=null || applicationID!=''){
			//Will add some fields that are not yet available on the Application Object
			appExistingAppList = [Select Id,
										  Application_GUID__c,
										  HP_Gender__c,
										  HP_Mobile_Phone__c,
										  HP_Home_Phone__c,
										  HP_Email__c,
										  HP_Year_of_birth__c,
										  High_School_Name__c,
										  HP_18_or_older__c
						   
		                           From Application__c 
		                           WHERE Id =: applicationId];
		}
		
		system.debug('***appExistingAppList = ' + appExistingAppList);
                             
		IHRestHeroPath heroPathParse = new IHRestHeroPath();
		//Check if there's an existing Application for that applicationId passed in the requestURI
		//If it has then populate the return the params 
		if(appExistingAppList.size()>0){
			for (Application__c appToReturn : appExistingAppList){
				
				//heroPathParse.Token = appToReturn.Id;
				
				heroPathParse.HPGender = appToReturn.HP_Gender__c;
			    heroPathParse.HPMPhone = appToReturn.HP_Mobile_Phone__c;
			    heroPathParse.HPHPhone = appToReturn.HP_Home_Phone__c;
			    heroPathParse.HPEmail = appToReturn.HP_Email__c;
			    heroPathParse.HPBirth = appToReturn.HP_Year_of_birth__c;
			    heroPathParse.HPHighSchool = appToReturn.High_School_Name__c;
			    heroPathParse.HP18Years = appToReturn.HP_18_or_older__c;
			}
		}
		
		return heroPathParse;
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