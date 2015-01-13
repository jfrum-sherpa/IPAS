@RestResource(urlMapping='/IHRestDocumentController/*')

global class IHRestDocumentController {
	
	public static string CreateException(string documentURL, string documentSource, string reviewType, string caseID){
		 string returnJSON;
		 
		 Schema.DescribeSObjectResult des = Schema.SObjectType.Case;
         Map<String,Schema.RecordTypeInfo> rtMapByName = des.getRecordTypeInfosByName();
		 
		 Case caseToBeInserted = new Case();
		 
		 	caseToBeInserted.RecordTypeId = rtMapByName.get('Adverse Event').getRecordTypeId();
		 	caseToBeInserted.Status = 'New';
		 	caseToBeInserted.Origin = 'Web';
		 	caseToBeInserted.Priority = 'Medium';
		 	caseToBeInserted.Date_Received__c = dateTime.now();
		 	caseToBeInserted.Type = reviewType;
		 	
		 insert caseToBeInserted;
		 
		 Supporting_Document__c supDocToInsert = new Supporting_Document__c();
		 	supDocToInsert.Case__c = caseToBeInserted.id;
		 	supDocToInsert.Document_URL__c = documentURL;
		 	supDocToInsert.Document_Name__c = documentSource;
		 	supDocToInsert.Name = documentSource;
		 insert supDocToInsert;
		 
		 returnJSON = '{"reply": {"status": "Success", "Case Info":[{"CaseID" : "' + caseToBeInserted.Id + '", "Case Details" : ""}]}}';
	     return returnJSON;
	}
	
	private static string addPractitioner(string appGUID,
	                                      string pracFirstName,
	                                      string pracLastName,
	                                      string pracLicenseNumber,
	                                      string isFailure)
  {
  	string returnJSON;
	Schema.DescribeSObjectResult des = Schema.SObjectType.Account;
	Map<String,Schema.RecordTypeInfo> rtMapByName = des.getRecordTypeInfosByName();
    System.Debug('-------------------->in Create Practitioner');     
    Account accToBeCreated = new Account();
    Supporting_Document__c supDoc;
	list<Supporting_Document__c> practitioner = new list<Supporting_Document__c>();
    accToBeCreated.RecordTypeId = rtMapByName.get('Practitioner').getRecordTypeId();
    if(pracFirstName!=null)
    {
       	accToBeCreated.FirstName = pracFirstName;
    }
    if(pracLastName!=null){
       	accToBeCreated.LastName = pracLastName;
    }     
  	
  	//do a check to see if this practitioner alrady exists in our system
  	//check with Ben and Lauresa if a specific field iss being used for this
  	//NOTE: THIS FIELD DOES NOT YET EXIST ON THE ACCOUNT
  	//Account existingPrac = [select Id FROM Account WHERE Practitioner_pracLicenseNumber =:pracLicenseNumber LIMIT 1];
  	
  	insert accToBeCreated;
  	
	return accToBeCreated.Id;                                   	
	                                      	
  }
	                                   
	                                   
   /*
    appGUID, 
	  	                                                   documentURL, 
	  	                                                   program, 
	  	                                                   documentSource, 
	  	                                                   timeStamp, 
	  	                                                   reviewType,
	  	                                                   originalFileName, 
	  	                                                   isFailure);
 */   
	
	
	private static string addDocumentToExistingApplication(
	                                                      
	                                                       string appGUID,
	                                                       string documentURL,
	                                                       string program,
	                                                       string documentSource,
	                                                       string timeStamp,
	                                                       string reviewType,
	                                                       string originalFileName,
	                                                       string isFailure){
	  string returnJSON;
	  
	  list<Application__c> appList = new list<Application__c>();
	  Supporting_Document__c supDoc;
	  list<Supporting_Document__c> supDocListForInsert = new list<Supporting_Document__c>();
	  
	  if(appGUID!=null){
	      appList = [select Id,
	  					Name,
	  					Application_GUID__c
	  				    From Application__c Where Application_GUID__c =: appGUID];
	  }
	  system.debug('***appList = ' + appList);
	  
	  if(appList.size()>0){
	  	  for(Application__c apToRelate: appList){
	  	  	
	  	  	  supDoc = new Supporting_Document__c();
	  	  	
	  	      supDoc.Application__c = apToRelate.Id;
	  	      
	  	      if(documentURL!=null){
	  	      	  supDoc.Document_URL__c = documentURL;
	  	      }
	  	      if(originalFileName!=null){
	  	      	  supDoc.Document_Name__c = originalFileName;
	  	      }
	  	      
	  	      supDocListForInsert.add(supDoc);
	  	  }
	  }
	  system.debug('***supDocListForInsert = ' + supDocListForInsert);
	  
	  if(supDocListForInsert.size()>0){
	  	insert supDocListForInsert;
	  }
	  
	  if (isFailure=='1')	
	   returnJSON = '{"reply": {"status": "Failure", "Error":[{"Error Code" : "EC-009", "Error Description" : "Document Exception"}]}}';
	  else
	   returnJSON = '{"reply": {"status": "Success", "Error":[{"Error Code" : "0", "Error Details" : ""}]}}';
	 
	 return returnJSON;
	}
	
	public static String CreateApplication(string patFirstName,
  	                                string patLastName,
  	                                string patDOB,
  	                                string patSSN,
  	                                string patGender,
  	                                string patZip,
  	                                string patPhone,
                                    string documentURL,
                                    string program,
                                    string documentSource,
                                    string reviewType,
                                    string caseID,
                                    string timeStamp,
                                    string originalFileName,
                                    string pracFirstName,
                                    string pracLastName,
                                    string pracNumber,
                                    string isFailure){
                                    	
         string returnJSON;
         System.Debug('-----------------------------> In Create Application');
         
         //Account RecordType schema to get recordTypeId
	     Schema.DescribeSObjectResult des = Schema.SObjectType.Account;
	     Map<String,Schema.RecordTypeInfo> rtMapByName = des.getRecordTypeInfosByName();
         
         Account accToBeCreated = new Account();
         Supporting_Document__c supDoc;
	  	 list<Supporting_Document__c> supDocListForInsert = new list<Supporting_Document__c>();
         
         accToBeCreated.RecordTypeId = rtMapByName.get('Patient').getRecordTypeId();
         if (pracFirstName!=null && pracFirstName!='')
         {
           string pracId = addPractitioner(accToBeCreated.Id, pracFirstName, pracLastName, pracNumber, isFailure );
           accToBeCreated.Practioner__c = pracId;
         }
        
         	
        
         if(patFirstName!=null){
         	accToBeCreated.FirstName = patFirstName;
         }
         if(patLastName!=null){
         	accToBeCreated.LastName = patLastName;
         }
         if(patDOB!=null){
         	
         	date mydate = date.parse(patDOB);
           	accToBeCreated.Date_of_Birth__c = mydate;
         }
         if(patSSN!=null){
         	accToBeCreated.SSN__c = patSSN;
         }
         if(patGender!=null){
         	accToBeCreated.Gender__c = patGender;
         }
         if(patZip!=null){
         	accToBeCreated.BillingPostalCode = patZip;
         }
         if(patPhone!=null){
         	accToBeCreated.Phone = patPhone;
         }
         
         
         
         if (isFailure=='1'){
		 	returnJSON = '{"reply": {"status": "Failure", "Error":[{"Error Code" : "EC-009", "Error Description" : "Application is not valid"}]}}';
         }else{
         	
         	insert accToBeCreated;
         	
         	system.debug('***accToBeCreated = ' + accToBeCreated);
         	
         	if(accToBeCreated!=null){
         		supDoc = new Supporting_Document__c();
         		supDoc.Account__c = accToBeCreated.Id;
         		if(documentURL!=null){
		  	      	supDoc.Document_URL__c = documentURL;
		  	    }
		  	    if(originalFileName!=null){
		  	      	supDoc.Document_Name__c = originalFileName;
		  	    }
	  	      
	  	      supDocListForInsert.add(supDoc);
         	}
         	
         	if(supDocListForInsert.size()>0){
         		insert supDocListForInsert;
         		
         	}
         	
         	
		 	returnJSON = '{"reply": {"status": "Success", "AppID": "' + accToBeCreated.Id  +'", "Error":[{"Error Code" : "0", "Error Details" : ""}]}}';
         }
	 
	 return returnJSON;
	}
	
	@HttpPost
	global static void handleDocument(){
		RestRequest req = RestContext.request;
        String reqBody = req.requestBody.toString();
       
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        String jsonResponse = '';
        
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(reqBody);
	  	string appGUID = (String)m.get('AppID');
	  	string documentURL = (String)m.get('DocumentURL');
	  	string program = (string)m.get('Program');
	  	string documentSource = (string)m.get('DocumentSource');
	  	string timeStamp = (string)m.get('TimeStamp');
	  	string originalFileName = (string)m.get('OriginalFileName');
	  	string isFailure = (string)m.get('IsFailure');
	  	string ReviewType = (string)m.get('ReviewType');
	  	string caseID = (string)m.get('Case_ID');
	  	
      
        String method = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        System.Debug('---------------------------->Method Name:' + method);
        
        if (method=='CreateException'){
        	
	  	    jsonResponse = CreateException(documentURL,  documentSource,  reviewType, caseID);
	  	   
        }
        
        
        
        if (method=='AddDocumentToExistingApplication'){
            jsonResponse = addDocumentToExistingApplication(
	  	                                                   appGUID, 
	  	                                                   documentURL, 
	  	                                                   program, 
	  	                                                   documentSource, 
	  	                                                   timeStamp, 
	  	                                                   reviewType,
	  	                                                   originalFileName, 
	  	                                                   isFailure);
	  	    
        }
        
        if (method=='createApplication'){
        	System.Debug('----------------->in create application method');
        	string patFirstName = (string)m.get('PatFirstName');
        	string patLastName = (string)m.get('PatLastName');
        	string patDOB = (string)m.get('PatDOB');
        	string patSSN = (string)m.get('PatSSN');
        	string patGender = (string)m.get('PatGender');
        	string patZip = (string)m.get('PatZip');
        	string patPhone = (string)m.get('PatPhone');
        	string pracFirstName = (string)m.get('PracFirstName');
        	string pracLastName = (string)m.get('PracLastName');
        	string pracNumber = (string)m.get('PracNumber');
        	
	  	    jsonResponse = CreateApplication(patFirstName,
  	                                         patLastName,
  	                                         patDOB,
  	                                         patSSN,
  	                                         patGender,
  	                                         patZip,
  	                                         patPhone,
  	                                         documentURL, 
  	                                         program, 
  	                                         documentSource, 
  	                                         reviewType,
  	                                         caseID,
  	                                         timeStamp, 
  	                                         originalFileName, 
  	                                         pracFirstName,
  	                                         pracLastName,
  	                                         pracNumber,
  	                                         isFailure);
	  	    
        }
        
        res.responseBody = blob.valueOf(jsonResponse);
        return ;
        
	}

}