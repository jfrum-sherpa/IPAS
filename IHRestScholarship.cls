@RestResource(urlMapping='/IHRestScholarship/v1/*')
global class IHRestScholarship{
	public String AppId;
	public String Token;	
	public String SLGPA;	
	public String SLGradDate;	
	public String SLSchName;	
	public String SLSchCity;	
	public String SLState;	
	public String SLZip;	
	public String SLPrinName;	
	public String SLEmail;	
	public String SLPostGPA;	
	public List<cls_SchoolsApplied> SchoolsApplied;
	public String SLDegreeAA;	
	public String SLDegreeAS;	
	public String SLDegreeBA;	
	public String SLDegreeBS;	
	public String SLDegreeOther;	
	public cls_Activities[] Activities;
	public cls_Jobs[] Jobs;
	public String SLPersonalState;	
	public cls_Files[] Files;
	public String ESignature;	
	class cls_SchoolsApplied {
		public String SLCSchName;	
		public String SLCAdd1;	
		public String SLCAdd2;	
		public String SLCCity;	
		public String SLCState;	
		public String SLCZip;	
		public String SCLCGradDate;	
	}
	class cls_Activities {
		public String SLActivityName;	
		public String SLActivityYears;	
		public String SLAcitvityHonros;	
	}
	class cls_Jobs {
		public String SLWorkPosition;	
		public String SLWorkFrom;	
		public String SLWorkTo;	
		public String SLWorkHours;	
	}
	class cls_Files {
		public String FileName;	
	}

	public static IHRestScholarShip parse(String json){
		return (IHRestScholarShip) System.JSON.deserialize(json, IHRestScholarShip.class);
	}
	
	 @HttpPost
	 global static void createScholarShip()
	 {
	 	//unrwrap into our class from the body params automatically
	 	//note the method does not need params explicitly as it will send them to the body
	 	//use PUT OR POST for updates here. 
	    RestRequest req = RestContext.request;
        String reqBody = req.requestBody.toString();
	    RestResponse res = RestContext.response;
	 	try{
	 	  IHRestScholarShip ss = IHRestScholarShip.parse(reqBody);
		  string p = ss.Token;
		  		 
          Application__c app = new Application__c();
          //example setting of a field fromt he input
          app.SS_Cumulative_College_GPA__c  = ss.SLGPA;
          insert app;
          //loop through our collections if we have any and call the appropriate updates on 
          //the target objects passing the new application id                          
	      if (ss.SchoolsApplied.size() > 0)
	      {
	   	    System.Debug('----------------------->Application ID:' + app.Id);
	   	    //create a method to take the params for the schools
	   	    //do the same for the letters but make that a utility method in another class as
	   	    //it is used on many child objects
	      }
	      //if we have a successful insert/update then build our success return
	      //might move this to another class
	      res.responseBody = blob.valueOf(successResponse(app.Id));
	 	}
	 	catch(Exception ex)
	 	{
	 	  res.responseBody =  blob.valueOf(ErrorGeneratorResponse.errorResponse('0',ex.getMessage()));
	 	}
	 }
	
	 @HttpGet
	 global static IHRestScholarShip  getScholarship()
	 {
	 	//Byrd Alley has stated they will send an application ID which will likely
	 	//be used as the param to pull up this record
	 	
		string applicationID = RestContext.request.params.get('AppId');
		
		List<Application__c> app = 
		                    [Select 
                             SS_Other_Equipment__c, 
                             (Select Name, Address_1__c, Address_2__c, City__c, Zip__c, Application__c From Schools__r),
                             (Select Name, LastReferencedDate, From_mo_yr__c, To_mo_yr__c, Hours_Week__c From Work_Experiences__r),
                             SS_Major__c, 
                             SS_Graduation_Date__c,
                             SS_Degree_or_Certificate_being_Pursued__c, 
                             SS_Cumulative_HS_GPA__c,
                             SS_Cumulative_College_GPA__c 
                             From Application__c 
                             WHERE ID =: applicationId ];
		IHRestScholarShip ss = new IHRestScholarShip();
		
		for (Application__c a : app)
		{
			ss.Token=a.Id;
			ss.SLGPA = a.SS_Cumulative_HS_GPA__c;
		}
		
		//process the child queries here. The two schools below are an example
		//use the API documentation for the payload
		cls_SchoolsApplied sa1 = new cls_SchoolsApplied();
		sa1.SLCSchName='test';
		ss.SchoolsApplied = new List<cls_SchoolsApplied>();
		ss.schoolsApplied.add(sa1);
		
		cls_SchoolsApplied sa2 = new cls_SchoolsApplied();
		sa2.SLCSchName='test2';
    	ss.schoolsApplied.add(sa2);
    	ss.Token = app[0].Id;
		return ss;
        
		
	 }	
	 
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