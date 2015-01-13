@RestResource(urlMapping='/IHRestCORE/*')
global class IHRESTCore {
	
         private static string getUser(string token){
		 List<Account> userInfo = [ Select ID, Name, Type, 
	                               FirstName, LastName,
		                           User_Token__c, Phone, PersonEmail 
		                           from Account 
		                           where User_Token__c = :token];
		return userInfo[0].Id;
	    }
	
	      private static string getEnrollment(string userID){
	      	List<Enrollments__c> enrollment = [SELECT ID FROM Enrollments__c WHERE Patient__c =: userID];
	      	return enrollment[0].Id;
	      	
	      }

	
	
	private static void getArrayElements(string reqBody, List<IH_Fields__c> csFields){
	  Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(reqBody);
      string service =  (String)m.get('service');
      Service_Offering__c serviceObj = new Service_Offering__c();
	  Schema.sObjectType o = serviceObj.getSObjectType();
	  Schema.sObjectType objectDef = Schema.getGlobalDescribe().get('Application__c').getDescribe().getSObjectType();
	  
	  sObject sObj = Schema.getGlobalDescribe().get('Application__c').newSObject() ;
	  sObject relatedObject;
	  
	  Map<String, Schema.SobjectField> ObjectFieldsMap = objectDef.getDescribe().fields.getMap();
	  	
	}
	
	private static sObject processPayload (string JSONRequest, 
	                                       string programService, 
	                                       List<IH_Fields__c> csFields,
	                                       string objectName,
	                                       string collectionName,
	                                       Boolean isObject)
	    {
		  Service_Offering__c serviceObj = new Service_Offering__c();
	      Schema.sObjectType o = serviceObj.getSObjectType();
	      Schema.sObjectType objectDef = Schema.getGlobalDescribe().get(objectName).getDescribe().getSObjectType();
	      sObject sObj = Schema.getGlobalDescribe().get(objectname).newSObject() ;
	      sObject relatedObject;
	      string fieldType;
	       Map<String, Schema.SobjectField> ObjectFieldsMap = objectDef.getDescribe().fields.getMap();
	       Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(JSONRequest);
           string service =  (String)m.get('service');
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
	  			     if (f.Parameter_Name__c==s && isObject==false )
	  			       {	  			     
	  			       	 System.debug('----------------------------------> field Name:' + f.Name + ':' + s);
	  			         token = (String)m.get('token');
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
	  			  	    
	  			  	     if (token != null){ sObj.put('Enrollment__c', getEnrollment(getUser(token))); }  
	  			    	 
	  			    	 paramValue = m.get(s);
	  			     	 //System.Debug('---------------------> Param matches' + paramValue);
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
	 
	                                
	   
	 
	  for (IH_Fields__c f: csFields){
	  	    object paramValue;
	  	    if (service==f.Service__c){
	  			System.Debug('---------------------> Service matches');
	  			for (String s : m.Keyset()){
	  			  paramValue = m.get(s);
	  			  System.Debug('-------------------> Response Body Values' + s);
	  			  if (f.Parameter_Name__c==s  )
	  			  {
	  			   	try{
	  			  	  sObj = processPayload(reqBody, service, csFields,  objectName, 'DELETE',false  );
	  			    }
	  			  	catch(Exception e)
	  			  	{
	  			  	   System.Debug('-------------------> Exception on:' + f.Parameter_Name__c);
	  			  	}
	  			    
	  			 	//*****handle the collection type
	  			  	JSONGenerator gen = JSON.createGenerator(true);
	  			  	
	  			  	string collectionName='';
	  			  	if (f.is_Collection__c==true){
	  			  		 objectName=f.Name;
	  			  		 isCollection=true;
	  			  		 System.Debug('------------------------>IS Collection and name matches collection name');
	  			  		 
	  			  		 while (parser.nextToken() != null) {
	  			  		 	
	  			  		 	if (parser.getCurrentToken() == JSONToken.START_ARRAY){
	  			  		 		System.Debug('------------------------------>Start Object' + JSONToken.Start_Object);
	  			  		 		System.Debug('-------------------------> Start Array');
	  			  		 		gen.writeStartObject();
	  			  		 		parser.nextToken();
	  			  		 		while(parser.nextToken() != null && parser.getCurrentToken() != JSONToken.END_ARRAY)
	  			  		 		{
	  			  		 		   
	  			  		 		   if (parser.getCurrentName()!=null && parser.getCurrentName() != parser.getText() )
	  			  		 		     gen.writeStringField(parser.getCurrentName(), parser.getText()); 
	  			  		 	    }
	  			  		 	}
	  			  		 	
	  			  		 	if (parser.getCurrentToken() == JSONToken.END_ARRAY){
	  			  		 		gen.writeEndObject();
	  			  		 		System.Debug('--------------------->Array Value:' + gen.GetAsString());	
	  			  		 		System.Debug('--------------------->Object Name:' + objectName);
	  			  		 		relatedObject = processPayload(gen.GetAsString(), service, csFields,  objectName, collectionName, true); 	
	  			  		 		
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
	    
	  	  relatedObject.put('Application__c', sObj.ID);
	  	  //relatedObject.put('Document_Name__c', 'test_document');
	   
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
	  
	  List<IH_Fields__c> csFields = [SELECT 
	                                 Name, Service__c 
	                                 FROM IH_Fields__c 
	                                 WHERE Service__c=: service ];
	  
	  integer loopCount=0;
  
	  for (string key : RestContext.request.params.keyset()){
	  	loopCount +=1;
	  	if (key!='id')
	  	 
	  	for (IH_Fields__c f: csFields){
	  		if (service==f.Service__c && loopCount==1){
	  			 dynamicSOQL += f.Name +  ',';
	  		}
	  	}
	  	System.Debug('key:' + key + ' value: ' + params.get(key));
	  }
	  
	  integer lastIndexofComma = dynamicSOQL.lastIndexOf(',');
      string dynamicSOQL2 = dynamicSOQL.SubString(0,lastIndexOfComma);
      System.Debug('---------------------->' + 'SELECT ' + dynamicSOQL2 + ' FROM Application__c');
     // List<sObject> acc = Database.Query('SELECT ' + dynamicSOQL2 + ' FROM Services__c WHERE Account_Token__c= \'' + token + '\'');
      List<sObject> acc = Database.Query('SELECT ' + dynamicSOQL2 + ' FROM Services__c ');
	  return acc;
	}

}