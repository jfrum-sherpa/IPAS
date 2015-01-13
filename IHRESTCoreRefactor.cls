@RestResource(urlMapping='/IHRestCORERefactor/*')
global class IHRESTCoreRefactor {
	public static string applicationID=null;
         private static string getUser(string token){
		 List<Account> userInfo = [ Select ID, Name, Type, 
	                               FirstName, LastName,
		                           User_Token__c, Phone, PersonEmail 
		                           from Account 
		                           where User_Token__c = :token ];
		return userInfo[0].Id;
	    }
	
	      private static string getEnrollment(string userID){
	      	Enrollments__c enrollment = new Enrollments__c();
	      	enrollment.Program__c = 'a0Ag00000077a6kEAA';
	      	enrollment.Patient__c = userID;
	      	insert enrollment;
	      	return enrollment.Id;
	      	
	      }
	      
	private static void createEnrollment(){
		
	}
	
	private static string decryptGUID(string encryptedData, string vector)
    {
         
        Blob IV = EncodingUtil.base64Decode(vector);
        blob cryptoKey = EncodingUtil.base64Decode('wokV/OTxoERJvqu2uakU9Q54slMJ2DabMj6fDGf7BAQ=');
        blob data = EncodingUtil.base64Decode(encryptedData);
       
        Blob decrypted = Crypto.decrypt('AES256', cryptoKey, IV, data);
        String decryptedString = decrypted.toString();
   
        return decryptedString;
    }
    

	
	
	private static sObject processPayload (string JSONRequest, 
	                                       string programService, 
	                                       List<IH_Fields__c> csFields,
	                                       string objectName,
	                                       Boolean isObject)
	     {
	      Schema.DescribeSObjectResult des = Schema.SObjectType.Application__c;
          Map<String,Schema.RecordTypeInfo> rtMapByName = des.getRecordTypeInfosByName();
		  string recordTypeID = rtMapByName.get(programService).getRecordTypeId();
		  
		  Service_Offering__c serviceObj = new Service_Offering__c();
	      Schema.sObjectType o = serviceObj.getSObjectType();
	      Schema.sObjectType objectDef = Schema.getGlobalDescribe().get(objectName).getDescribe().getSObjectType();
	      sObject sObj = Schema.getGlobalDescribe().get(objectname).newSObject() ;
	      sObject relatedObject;
	      string fieldType;
	       Map<String, Schema.SobjectField> ObjectFieldsMap = objectDef.getDescribe().fields.getMap();
	       Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(JSONRequest);
           //string service =  (String)m.get('service');
           string token='';
		   for (IH_Fields__c f: csFields)
		   {
		      object paramValue;
	  	     	
	  	       	 System.Debug('---------------------> Service matches');
	  	    	  for (String s : m.Keyset())
	  	    	   {
	  	    		 paramValue = m.get(s);
	  			     System.Debug('-------------------> Response Body Values' + s);
	  			     System.Debug('-------------------> f.Parameter_Name__c:' + f.Parameter_Name__c + ':' + 'keyset value:' + s);
	  			     if (f.Parameter_Name__c==s && f.is_Object__c==false )
	  			       {	  		
	  			       	 sObj.put('RecordTypeId', recordTypeID );	     
	  			       	 System.debug('----------------------------------> field Name:' + f.Name + ':' + s);
	  			         token = decryptGUID((String)m.get('Token'), (String)m.get('IV')) ;
	  			         if (ObjectFieldsMap.get(f.Name) != null)
	  			  	       fieldType = ObjectFieldsMap.get(f.Name).getDescribe().getType().name().ToLowerCase();
	  			  	   	 try{
	  			  	   	   if (fieldType=='boolean')
	  			  	         sObj.put(f.Name, Boolean.Valueof(paramvalue));
	  			  	        else if (fieldType=='decimal' || fieldType=='currency'){
	  			  	          String paramString = (String)paramValue;
	  			  	          sObj.put(f.Name, decimal.valueof(paramString.trim()));
	  			  	        }else{
	  			  	       
	  			  	        sObj.put(f.Name, paramvalue);
	  			  	        }
	  			  	   	  }
	  			  	      catch(Exception e){
	  			  	      	System.Debug('-------------------------->Exception on' +  paramValue);
	  			  	      }
	  			  	    
	  			  	    
	  			    	 
	  			    	 
	  			       }	
	  		       }	
	  	       }
		   	
	  	
		return sObj; 
		
	}
	
	private static sObject processJSONCollection(List<string> jsonFields, Map<string, string> jsonMAP, string objectName, List<IH_Fields__c> csFields){
		 string fieldType;
		  Schema.sObjectType objectDef = Schema.getGlobalDescribe().get(objectName).getDescribe().getSObjectType();
	      sObject sObj = Schema.getGlobalDescribe().get(objectname).newSObject() ;
	     
	      Map<String, Schema.SobjectField> ObjectFieldsMap = objectDef.getDescribe().fields.getMap();
		  for (IH_Fields__c f: csFields){
		 	for (string stringFieldName : jsonFields){
		 		try{
		 	     if (stringFieldName==f.Parameter_Name__c){
		 	      string paramValue = jsonMap.get(f.Parameter_Name__c);
		 		  fieldType = ObjectFieldsMap.get(f.Name).getDescribe().getType().name().ToLowerCase();
		 		  //**now we have to handle of the field types
		 		  if (fieldType=='boolean')
	  			    sObj.put(f.Name, Boolean.Valueof(paramvalue));
		 		   else if (fieldType=='decimal' || fieldType=='currency'){
	  			  	String paramString = (String)paramValue;
	  			  	sObj.put(f.Name, decimal.valueof(paramString.trim()));
	  			  	}else{
	  			  	          sObj.put(f.Name, paramvalue);
	  			  }
		 	     }
		 		}
		 		catch(Exception e){
		 			System.Debug('!!!!!!!!!!!!!!!!! Exception' + e.getMessage());
		 	  }
		 	}
		 	
		 }
		 
		 return sObj;
	}
	
	
	
	@HttpPost
	global static sObject createService() {
	  //*** recieve the request JSON from the body of the service
	  RestRequest req = RestContext.request;
	  String reqBody = req.requestBody.toString();
	  String dynamicSOQL='id,' ;
	  String paramName;
	  String token = '';
	  System.Debug(reqBody);
	  Boolean isCollection=false;
	  JSONParser parser = JSON.createParser(reqBody);
	  string objectName='Application__c';
	  sObject sObj;
	  sObject relatedObject;
	  Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(reqBody);
      string service =  (String)m.get('service');
	  //List<Services__c> desRequest = (List<Services__c>)JSON.deserialize(reqBody, List<Services__c>.class);
	  
	 System.debug('----------------------->Service:' + service);
	
	  List<IH_Fields__c> csFields = [SELECT 
	                                 Name, Service__c, Is_Collection__c, Collection_Name__c, Parameter_Name__c,
	                                 is_Object__c
	                                 FROM  IH_Fields__c 
	                                 WHERE Service__c=: service ];
	 
	  sObj = processPayload(reqBody, service, csFields,  objectName, false  );                              
	  token = decryptGUID((string) m.get('Token'), (string) m.get('IV'));
	  
	  if (token != null){ sObj.put('Enrollment__c', getEnrollment(getUser(token))); }      
	 
	  for (IH_Fields__c f: csFields){
	  	    object paramValue;
	  	    if (service==f.Service__c){
	  			System.Debug('---------------------> Service matches');
	  			for (String s : m.Keyset()){
	  			  paramValue = m.get(s);
	  			  System.Debug('-------------------> Response Body Values' + s);
	  			  if (f.Parameter_Name__c==s )
	  			  {
	  		   
	  			 	//*****handle the collection type
	  			  	JSONGenerator gen = JSON.createGenerator(true);
	  			  	
	  			  	string collectionName='';
	  			  	if (f.is_Collection__c==true){
	  			  		 objectName=f.Name;
	  			  		 isCollection=true;
	  			  		 System.Debug('------------------------>IS Collection and name matches collection name');
	  			  		 List<string> arrayFields = new List<string>();
	  			  		 Map<string, string> mapArrayFields = new Map<string, string>();
	  			  		 
	  			  		 while (parser.nextToken() != null) {
	  			  		 	
	  			  		 	if (parser.getCurrentToken() == JSONToken.START_ARRAY){
	  			  		 		System.Debug('------------------------------>Start Object' + JSONToken.Start_Object);
	  			  		 		System.Debug('-------------------------> Start Array');
	  			  		 		gen.writeStartObject();
	  			  		 		parser.nextToken();
	  			  		 		while(parser.nextToken() != null && parser.getCurrentToken() != JSONToken.END_ARRAY)
	  			  		 		{
	  			  		 		   System.Debug('---------------------------->JSON Parser Name' + parser.getCurrentName() + ':value' + parser.getText()  );
	  			  		 		   arrayFields.add(parser.getCurrentName());
	  			  		 		   mapArrayFields.put(parser.getCurrentName(), parser.getText());
	  			  		 		   
	  			  		 		   if (parser.getCurrentName()!=null && parser.getCurrentName() != parser.getText() )
	  			  		 		     gen.writeStringField(parser.getCurrentName(), parser.getText()); 
	  			  		 	    }
	  			  		 	}
	  			  		 	
	  			  		 	
	  			  		 	if (parser.getCurrentToken() == JSONToken.END_ARRAY){
	  			  		 		gen.writeEndObject();
	  			  		 		relatedObject = processJSONCollection(arrayFields, mapArrayFields, objectName, csFields); 
	  			  		 		break;
	  			  		 	}
	  			  		 		
	  			  		 }
	  			     	}
	  			  }
	  			}
	  		}
	  	}
	  
	  
	  	
	  
	  insert sObj;  
	  if (isCollection==true){
	    
	  	  relatedObject.put('Application__c', sObj.Id);
	  	  
	   
	      insert relatedObject;     
	  }                       
	  return sObj;
	  }
	  
	  
	@HttpGet
	global static List<Account> getService(){
	  RestResponse res = RestContext.response;
	  String token = RestContext.request.params.get('token');
	  String service = RestContext.request.params.get('service');
	  Map<String, String > params = RestContext.request.params;
	  String dynamicSOQL='id,' ;
	  String dynamicSOQLArray='id,' ;
	  Boolean isCollection=false;	  
	  String JsonResp='';
	 
	  String collectionName='';
	  String serviceName='';
	  string objectName='Application__c';
	  List<sObject> acc = new List<sObject>();
	 
	  
	  List<IH_Fields__c> csFields = [SELECT 
	                                 Name, Service__c,
	                                 is_Collection__c,
	                                 Collection_Name__c,
	                                 Parameter_Name__c 
	                                 FROM IH_Fields__c 
	                                 WHERE Service__c=: service ];
	                                 
	  system.debug('***csFields = ' + csFields);
	                                 
	  
	  List<string> arrayCollections = new List<string>();
	  integer loopCount=0;
  
	  for (string key : RestContext.request.params.keyset()){
	  	loopCount +=1;
	  	if (key!='id')
	  	
	  	system.debug('***key = ' + key);
	  	 
	  	for (IH_Fields__c f: csFields){
	  		if (service==f.Service__c && loopCount==1 ){
	  			if (f.Collection_Name__c==null || f.Collection_Name__c==''){
	  			  dynamicSOQL += f.Name +  ',';
	  			 }
	  			  serviceName= f.Service__c;
	  			 
	  			 system.debug('***serviceName = ' + serviceName);
	  			 system.debug('***dynamicSOQL = ' + dynamicSOQL);
	  			 
	  			if (f.is_Collection__c==true && f.Collection_Name__c!=null){
	  				//now we have the table name, go return the values in the collection
	  				//string objectNameArray = f.Name;
	  				//string collectionName = f.Collection_Name__c;
	  				//now call a function that collects all of those fields and return a JSON
	  				//string populated with the values
	  				isCollection=true;
	  				
	  				arrayCollections.add(getCollectionValues(f.Name, f.Collection_Name__c, csFields));
  					dynamicSOQLArray += f.Name +  ',';
	  			}
	  		}
	  		
	  	System.Debug('key:' + key + ' value: ' + params.get(key));
	    }
	  }
	  
	  integer lastIndexofComma = dynamicSOQL.lastIndexOf(',');
      string dynamicSOQL2 = dynamicSOQL.SubString(0,lastIndexOfComma);
      if(serviceName!=null){
      		acc = Database.Query('SELECT ' + dynamicSOQL2 + ' FROM Application__c ');
      
      	
     }
     
      JSONGenerator gen = JSON.createGenerator(true);
	  gen.writeStartObject();
	  for (sObject sOuter : acc)
	  {
	  	for (IH_Fields__c f: csFields)
	  	{ 
	      try{
	        gen.writeObjectField(f.Parameter_Name__c,sOuter.get(f.Name));
	      }
	      catch(Exception e){
	      	
	      }
	  	}
	  }
	  gen.writeEndObject();
      System.Debug('-----------------------------> JSON output:' + gen.getAsString());
        
	  return acc;
	}
	
	
	public static string getCollectionValues(string objectName, string collectionName, List<IH_Fields__c> csFields)
	{
		string dynamicSOQL='id,' ;
		
		List<sObject> sObj = new List<sObject>();
		for (IH_Fields__c f: csFields)
		{
			if (collectionName==f.Collection_Name__c && f.Is_Collection__c==false )
			{
				dynamicSOQL += f.Name +  ',';
			}
		
    	}
      System.Debug('---------------------------->Array Select:' + dynamicSOQL);
      integer lastIndexofComma = dynamicSOQL.lastIndexOf(',');
      string dynamicSOQL2 = dynamicSOQL.SubString(0,lastIndexOfComma);
	  //sObj = Database.Query('SELECT ' + dynamicSOQL2 + ' FROM  ' + objectName);	
	  return dynamicSOQL;
	}
}