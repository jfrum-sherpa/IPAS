/******************************************************************************
             moved the encrypt and decrypt method into IHRestUtilities
             and changed the way it is called into the encryption and decryption on the token.
 ******************************************************************************/

@RestResource(urlMapping='/IHRestUserCore/*')

global  class IHRESTUserCore {
    
    /*
    * Created by john.frum@cloudsherpas.com 12/23/2014
    * Decrypts the guid for the user that Byrd Alley is passing in
    * Modified: markcarlo.mempin@cloudsherpas.com - Moved this method to a new class named IHRestUtilities - 1/7/2015
    */
    /*
    private static string decryptGUID(string encryptedData, string vector)
    {
    	
        
        Blob IV = EncodingUtil.base64Decode(vector);
        blob cryptoKey = EncodingUtil.base64Decode('wokV/OTxoERJvqu2uakU9Q54slMJ2DabMj6fDGf7BAQ=');
        blob data = EncodingUtil.base64Decode(encryptedData);
        //blob encrypted = Crypto.encrypt('AES256', cryto, exampleIv, data);
        Blob decrypted = Crypto.decrypt('AES256', cryptoKey, IV, data);
        String decryptedString = decrypted.toString();
       
        return decryptedString;
    }
    */
    
    /*
     * Author: MMempin@Cloudsherpas.com
     * Date  : 11/29/2014
     * modified: markcarlo.mempin@cloudsherpas.com - Moved this method to a new class named IHRestUtilities - 1/7/2015
     * Description: This encyrpt the user token
     * updated by jfrum - we aren't passing in the vector, please see the decrypt method above
     */
     /*
    public static string encryptGUID(String Token){
    	
    	
		blob key = EncodingUtil.base64Decode('wokV/OTxoERJvqu2uakU9Q54slMJ2DabMj6fDGf7BAQ=');
		Blob data = Blob.valueOf(Token);
        Blob encryptedData = Crypto.encryptWithManagedIV('AES256', key, data);
       
    
        
        System.Debug('----------------------->Encrypted String:' + EncodingUtil.base64Encode(encryptedData) );
		return  EncodingUtil.base64Encode(encryptedData);
    }
    */
    
     /*
     * Author: mark.casanas@cloudsherpas.com
     * Date  : 1/05/2015
     * modified: 
     * Description: This method returns a collection of Application Record Types
     */
    
    public static string returnAppRecordType(){
    	string returnJSON='';
        string JSONRecordType = '';
        
        Schema.DescribeSObjectResult R = Application__c.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> recType = R.getRecordTypeInfos();
        
        system.debug('******' + recType);
        for(Schema.RecordTypeInfo rType : recType){
            JSONRecordType += '"ApplicationName":"' + rType.getName() + '",';
        }
        
        returnJSON = '{' + JSONRecordType.removeEnd(',') +'}';
        system.debug('******' + returnJSON);
        return returnJSON;
    }
    
    
    /*
    * Created by john.frum@cloudsherpas.com 12/23/2014
    * This method returns the patient or caregiver and related patient applications
    * The way the queries need to work to return the collection differ from caregiver
    * and patient. NOTE: look at refactoring the queries to be more effecient
    * Primarily the Patient_Caregiver__c query
    */
    
    public static string getRegistration(string userToken, string patToken, string userType)
    {
    
         List<Patient_Caregiver__c> patientCaregivers = new List<Patient_CareGiver__c>();
         List<Application__c> applications = new List<Application__c>();
         List<Account> userInfo = new List<Account>();
         List<Account> userList = new List<Account>();
        
        if (userType=='C')
        {
            
             Map<String,Patient_CareGiver__c> mapAccountPatients = new Map<string, Patient_CareGiver__c>([SELECT Patient__c FROM Patient_Caregiver__c WHERE CareGiver__r.User_Token__c =:userToken]);
             List<Patient_CareGiver__c> lst = [SELECT Patient__c, CareGiver__r.User_Token__c FROM Patient_Caregiver__c WHERE CareGiver__r.User_Token__c =:userToken];
             Map<String, String> acctMap = new Map<String, String>();
             
             for (Patient_CareGiver__c pc : lst){
                acctMap.put(pc.Patient__c, pc.CareGiver__r.User_Token__c);
             }
                          
             applications =  [SELECT  ID, Application_Status__c,
                              RecordType.Name, CreatedDate, Enrollment__r.Patient__c
                              FROM Application__c 
                              ];
                             
             
             userInfo =      [Select ID, Name, Type, 
                                    FirstName, LastName,
                                    BillingPostalCode, Phone, PersonEmail,
                                    Diagnosis__c, RecordType.Name, Patient_Token__c
                                    from Account 
                                    
                               where  Patient_Age__c < 18 AND ID IN :acctMap.Keyset()  ];
            

            system.debug('\n\n##### patToken : '+ patToken);
            system.debug('\n\n##### userToken : '+ userToken);
            system.debug('\n\n##### lst : '+ lst);
            system.debug('\n\n##### acctMap : '+ acctMap);
            system.debug('\n\n##### userInfo : '+ userInfo);
        }
        if (userType=='P')
        {
              Map<Id,Patient_CareGiver__c> mapAccountPatients = new Map<Id, Patient_CareGiver__c>([SELECT Patient__c  FROM Patient_Caregiver__c WHERE ID =:userToken]);
               userInfo =       [Select ID, Name, Type, 
                                       FirstName, LastName,
                                       BillingPostalCode, Phone, PersonEmail,
                                       Diagnosis__c, RecordType.Name, Patient_Token__c
                                       from Account 
                                where User_Token__c=:userToken  ];
                                       
              applications =  [select  ID, Application_Status__c,
                                       RecordType.Name, CreatedDate,Enrollment__r.Patient__c
                                       FROM Application__c 
                               where Enrollment__r.Patient__c=:userInfo[0].Id ];
             
             
        }
           
       for(Account user : userInfo)     
       {
         userList.add(user);
       }                               
       
       JSONGenerator gen = JSON.createGenerator(true);
       gen.writeStartObject(); 
       gen.writeFieldName('user');
       gen.writeStartObject(); 
       gen.writeStringField('ZipCode', userInfo[0].BillingPostalCode);
       gen.writeFieldName('Patient');
       gen.writeStartArray();

       
       for (Account a : userList)   
       {
         gen.writeStartObject();
         if (a.Patient_Token__c!=null)
         	//Call the IHRestUtilities Class for decrypt and encrypt function.
             gen.writeStringField('PatGUID', IHRestUtilities.encryptGUID(a.Patient_Token__c));  
         else
             gen.writeStringField('PatGUID', IHRestUtilities.encryptGUID(a.Patient_Token__c)); 
             
         gen.writeStringField('PatFirstName', a.FirstName); 
         gen.writeStringField('PatLastName', a.LastName);    
         gen.writeStringField('PatDiagnosis', 'undefined');
         if (a.Diagnosis__c!=null)
           gen.writeStringField('PatDiagnosis', a.Diagnosis__c); 
           
         gen.writeFieldName('Applications');
         gen.writeStartArray();
         for (Application__c app : applications)
         {
            if (app.Enrollment__r.Patient__c==a.ID){
              gen.writeStartObject();
              gen.WriteStringField('AppName', app.RecordType.Name);
              gen.writeStringField('AppStatus', app.Application_Status__c);
              gen.writeStringField('AppDateSubmitted', '12/22/2014');
              gen.writeEndObject();
            }
            
         }
         gen.writeEndArray();
         gen.writeEndObject();
       }                                  
       
       gen.writeEndArray();      
       gen.writeEndObject();                                 
       return gen.getAsString();
    }
	
	
	//Modified: markcarlo.mempin@cloudsherpas.com - parsed the date to accept it right in SFDC - 1/13/2015
    public static string checkDuplicatePatient(String patFirstName, String patLastName, String zipCode, String patBirthDate){
    //**** note these do not contain all of the conditions yet
    //**** need to ensure they are in the data model and where
     string returnJSON='';
     
     date patBithParse = date.parse(patBirthDate);
     system.debug('***patBithParse = ' + patBithParse);
     
     
     List<Account> userInfo =    [ Select ID, Name, Type, 
                                   FirstName, LastName,
                                   BillingPostalCode, Phone, PersonEmail 
                                   from Account 
                                   where FirstName = :patFirstName AND LastName=:patLastName AND BillingPostalCode =: zipCode AND Date_Of_Birth__c=: patBithParse];
      /*
      List<Account> userInfo =    [ Select ID, Name, Type, 
                                   FirstName, LastName,
                                   BillingPostalCode, Phone, PersonEmail 
                                   from Account 
                                   where FirstName = :patFirstName AND LastName=:patLastName AND BillingPostalCode =: zipCode  ];
      */
     
     if (userInfo.Size() > 0){
         returnJSON = '{"reply": {"status": "0", "Errors":[{"ErrorCode" : "02", "ErrorMessage" : "Duplicate Patient"}]}}';
     }
     else{
        returnJSON = '{"reply": {"status": "1", "Errors":[{"ErrorCode" : "", "ErrorMessage" : ""}]}}';
     }
     
     return returnJSON;
}   


public static string checkDuplicateUserEmail(string email/*Commented MacMempin - 12/16/2014 -- , string token*/){
     string returnJSON='';
     
     List<Account> userInfo =     [Select ID, Name, Type, 
                                   FirstName, LastName,
                                   User_Token__c, Phone, PersonEmail 
                                   from Account 
                                   where PersonEmail = :email];
      /* Commented MacMempin - 12/16/2014 -- if (token != null){
        userInfo =   [ Select ID, Name, Type, 
                                   FirstName, LastName,
                                   User_Token__c, Phone, PersonEmail 
                                   from Account 
                                   where User_Token__c =:token];
      }*/
      
      if (userInfo.size() > 0){
         returnJSON = '{"reply": {"status": "0", "Errors":[{"ErrorCode" : "01", "ErrorMessage" : "Duplicate Email"}]}}';
      }
      else{
        returnJSON =  '{"reply": {"status": "1", "Errors":[{"ErrorCode" : "", "ErrorMessage" : ""}]}}';  
      }
      
      return returnJSON;
}

    /*
     * Author: MMempin@Cloudsherpas.com
     * Date  : 11/26/2014
     * modified: john.frum@cloudsherpas.com to account for Patients_Caregiver__c mapping
     * Description: This web service method will be called to create a new user in the Inventiv database.  
                    The below set of input parameters can be passed in request to Create User successfully.
     * Method: PUT
     */
    public static String createUser(string token,
                                    string recType,
                                    string fName,
                                    string lName,
                                    string midInitial,
                                    string email,
                                    string add1,
                                    string add2,
                                    string city,
                                    string state,
                                    string zip,
                                    string PatToken,
                                    string PatZipCode,
                                    string PatFirstName,
                                    string PatLastName,
                                    string PatMiddleInitial,
                                    string PatDiagnosis,
                                    string PatBirth){
                                        
        string returnJSON='';
        
       
        
        list<Account> accPatientList = new list<Account>();
        Account acc = new Account();
        Account accP = new Account();
        
        //Account RecordType schema to get recordTypeId
        Schema.DescribeSObjectResult des = Schema.SObjectType.Account;
        Map<String,Schema.RecordTypeInfo> rtMapByName = des.getRecordTypeInfosByName();
        
        system.debug('***recType = ' + recType);
        
        if(token!=null && recType!=null ){
           acc.RecordTypeId = rtMapByName.get('Caregiver').getRecordTypeId();
           acc.User_Token__c = token;   
           
            if(fName!=null ){
                acc.FirstName = fName;
            }
           
            if (fName!=null)
              acc.LastName = lName;
            
            if(midInitial!=null){
                acc.MiddleName = midInitial;
            }
          
            if(email!=null){
                acc.PersonEmail = email;
            }
            if(add1!=null){
                acc.BillingStreet = add1;
                acc.ShippingStreet = add1;
            }
            if(add2!=null){
                //acc.ShippingStreet = add2;
               
            }
            if(city!=null){
                acc.BillingCity = city;
                acc.ShippingCity = city;
            }
            if(state!=null){
                acc.BillingState = IHRestUtilities.stateCode(state);
                acc.ShippingState = IHRestUtilities.stateCode(state);
                //acc.BillingStateCode = state;
                //acc.ShippingStateCode = state;
            }
            if(zip!=null){
                acc.BillingPostalCode = zip;
                acc.ShippingPostalCode = zip;
            }
            
                     
           
            if(PatFirstName!=null){
                accP.FirstName = PatFirstName;
            }
            if(PatLastName!=null){
                accP.LastName = PatLastName;
            }
            accP.RecordTypeId = rtMapByName.get('Patient').getRecordTypeId();
           
            if (PatZipCode!=null ){
                accP.BillingPostalCode = PatZipCode;
                accP.ShippingPostalCode = PatZipCode;
              }
              
           
             
           if(PatToken!=null){
                accP.Patient_Token__c = PatToken;
                accP.User_Token__c=PatToken;
            }
            
            if (PatDiagnosis!=null)
              accP.Diagnosis__c = PatDiagnosis;
          
                 
            if (recType=='P' || recType=='p'){
              accP.User_Token__c=PatToken;
              accP.ShippingCity=city;
              accP.ShippingState=IHRestUtilities.stateCode(state);
              accP.BillingCity=city;
              accP.BillingState=IHRestUtilities.stateCode(state);
              accP.BillingStreet= add1;
              accP.ShippingStreet= add1;
              accP.PersonEmail = email;
              accP.BillingPostalCode = zip;
              accP.ShippingPostalCode = zip;
              if (PatZipCode!=null ){
                accP.BillingPostalCode = PatZipCode;
                accP.ShippingPostalCode = PatZipCode;
              }
            }
            
            
            if(PatDiagnosis!=null){
                accP.Diagnosis__c = PatDiagnosis;
            }
            if(PatBirth!=null){
            	
            	date mydate = date.parse(PatBirth);
            	
                acc.PersonBirthdate = mydate;
            }
            accPatientList.add(accP);
        }
        
        
        system.debug('*** Account to be Inserted = ' + acc);
        system.debug('*** Account Patient to be Inserted = ' + accPatientList);
        system.debug('*** accPatientList = ' + accPatientList);
        
        List<Patient_Caregiver__c> patCareGiverList = new List<Patient_Caregiver__c>();
        
        if (acc==null && accPatientList.size()==0){
            returnJSON = '{"reply": {"status": "0", "Errors":[{"ErrorCode" : "03", "ErrorMessage" : "Data Error"}]}}';
        }
        else{
            system.debug('***acc to be inserted = ' + acc);
            if (recType=='C')
              insert acc;
            system.debug('***INserted Acc = ' + acc);
            
            if(accPatientList.size()>0 ){
                insert accPatientList;
            }
            system.debug('***INserted Acc Patient = ' + accPatientList);
            
            //Loop through the list of paients and create the insert into the patient caregiver list
            
            for(Account acPatient: accPatientList){
                Patient_Caregiver__c patCareGiver = new Patient_Caregiver__c();
                patCareGiver.Patient__c = acPatient.Id;
                patCareGiver.Caregiver__c = acc.Id;
                patCareGiver.Relationship_Type__c='Standard';
                
                patCareGiverList.add(patCareGiver);
            }
            
            if(patCareGiverList.size()>0 && recType=='C'){
                insert patCareGiverList;
            }
            
            returnJSON =  '{"reply": {"status": "1", "Errors":[{"ErrorCode" : "", "ErrorMessage" : ""}]}}';   
        }
          
        return returnJSON;
    }
    
    /*
     * Author: MMempin@Cloudsherpas.com
     * Date  : 11/26/2014
     * Description: This web service method will be called after the Get User method is called.
                    The information will be populated into the form from that method.
                    The user will update the information and it will post back to the system.
                    The below set of input parameters can be passed in request to edit a user successfully.
     * Method: PUT
     */
    public static String editUser(string token,
                                  string middleInitial,
                                  string add1,
                                  string add2,
                                  string city,
                                  string state,
                                  string zip,
                                  string patToken,
                                  string patMiddleInitial,
                                  string patDiagnosis,
                                  string physicianName,
                                  string physicianPhone,
                                  string htcInstContact,
                                  
                                  string htcInstAdd1,
                                  string htcInstAdd2,
                                  string htcInstCity,
                                  string htcInstState,
                                  string htcInstZipCode){
                                        
        string returnJSON='';
        
        system.debug('***token = ' + token);
        //Account acc = new Account();
        list<Account> accList = new list<Account>();
        list<Account> accListForUpdate = new list<Account>();
        
        list<Account> accListPatient = new list<Account>();
        list<Account> accListPatientForUpdate = new list<Account>();
        
        list<Enrollments__c> enrollmentList = new list<Enrollments__c>();
        list<Enrollments__c> enrollmentListForUpdate = new list<Enrollments__c>();
        
        if(token!=null){
            
             accList = [Select Id,
                                Type, 
                                FirstName,
                                LastName,
                                BillingCity,
                                BillingStreet,
                                BillingState,
                                BillingCountry,
                                BillingPostalCode,
                                ShippingStreet,
                                Phone,
                                PersonEmail,
                                User_Token__c,
                                Diagnosis__c,
                                MiddleName,
                                Patient_Token__c
                                
                                From Account 
                                where User_Token__c =: token OR Patient_Token__c=:token];
        }
        system.debug('***accList = ' + accList);
        
        if(accList.size()>0){
            for(Account acToUpdate: accList){
                
                acToUpdate.MiddleName = middleInitial;
                acToUpdate.BillingStreet = add1;
                acToUpdate.ShippingStreet = add1;
                acToUpdate.BillingCity = city;
                acToUpdate.ShippingCity = city;
                acToUpdate.BillingState = IHRestUtilities.stateCode(state);
                acToUpdate.ShippingState = IHRestUtilities.stateCode(state);
                acToUpdate.BillingPostalCode = zip;
                acToUpdate.ShippingPostalCode = zip;
                
                accListForUpdate.add(acToUpdate);
            }
        }
        system.debug('***accListForUpdate = ' + accListForUpdate);
        
        /*if(accListForUpdate.size()>0){
            update accListForUpdate;
        }*/
        
        //For Patient Account Update
        if(patToken!=null){
            accListPatient = [Select Id,
                                Diagnosis__c,
                                MiddleName,
                                Patient_Token__c
                                
                                From Account 
                                Where Patient_Token__c =:patToken];
        }
        
        if(accListPatient.size()>0){
            for(Account accPatientToUpdate: accListPatient){
                accPatientToUpdate.MiddleName = patMiddleInitial;
                accPatientToUpdate.Diagnosis__c = patDiagnosis;
                
                accListPatientForUpdate.add(accPatientToUpdate);
            }
        }
        system.debug('***accListPatientForUpdate = ' + accListPatientForUpdate);
        
        /*if(accListPatientForUpdate.size()>0){
            update accListPatientForUpdate;
        }*/
        
        set<Id> patientIdSet = new set<Id>();
        if(accListPatient.size()>0){
            for(Account ac: accListPatient){
                patientIdSet.add(ac.Id);
            }
        }
        system.debug('***patientIdSet = ' + patientIdSet);
        
        if(patientIdSet.size()>0){
            enrollmentList = [Select Id,
                                     Name,
                                     HTC_Address_1__c,
                                     HTC_Address_2__c,
                                     HTC_Contact__c,
                                     HTC_State__c,
                                     HTC_Zip_Code__c,
                                     HTC_City__c,
                                     Patient__c,
                                     Practioner__c,
                                     Physician_name__c,
                                     Physician_phone__c
                                     
                                     
                                     From Enrollments__c
                                     Where Patient__c IN: patientIdSet];
        }
        system.debug('***enrollmentList = ' + enrollmentList);
        
        if(enrollmentList.size()>0){
            for(Enrollments__c en: enrollmentList){
                
                en.Physician_name__c = physicianName;
                en.Physician_phone__c = physicianPhone;
                en.Hemophilia_Treatment_Center_Name__c = 'Hemo Test Treatment Center';
                en.HTC_Contact__c = htcInstContact;
                en.HTC_Address_1__c = htcInstAdd1;
                en.HTC_Address_2__c = htcInstAdd2;
                en.HTC_City__c = htcInstCity;
                en.HTC_State__c = htcInstState;
                en.HTC_Zip_Code__c = htcInstZipCode;
                
                enrollmentListForUpdate.add(en);
            }
        }
        system.debug('***enrollmentListForUpdate = ' + enrollmentListForUpdate);
        
        /*
        if(accListForUpdate.size()>0){
            for(Account acc: accListForUpdate){
                
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                    gen.writeFieldName('user');
                        gen.writeStartObject();
                            gen.writeObjectField('Token', acc.User_Token__c);
                            
                            if(acc.Diagnosis__c!=null){
                                gen.writeObjectField('Diagnosis', acc.Diagnosis__c);
                            }else{
                                gen.writeObjectField('Diagnosis', '');
                            }
                            
                            if(acc.MiddleName!=null){
                                gen.writeObjectField('MiddleInitial', acc.MiddleName);
                            }else{
                                gen.writeObjectField('MiddleInitial', '');
                            }
                            
                            if(acc.BillingStreet!=null){
                                gen.writeObjectField('Address1', acc.BillingStreet);
                            }else{
                                gen.writeObjectField('Address1', '');
                            }
                            
                            gen.writeObjectField('Address2', '');
                            
                            if(acc.BillingCity!=null){
                                gen.writeObjectField('City', acc.BillingCity);
                            }else{
                                gen.writeObjectField('City', '');
                            }
                            
                            if(acc.BillingState!=null){
                                gen.writeObjectField('State', acc.BillingState);
                            }else{
                                gen.writeObjectField('State', '');
                            }
                            
                            if(acc.BillingPostalCode!=null){
                                gen.writeObjectField('ZipCode', acc.BillingPostalCode);
                            }else{
                                gen.writeObjectField('ZipCode', '');
                            }
                            gen.writeObjectField('Password', '');
                                
                                //For Patients
                                //commented out by jfrum
                                gen.writeFieldName('Patients');
                                    gen.writeStartArray();
                                        gen.writeStartObject();
                                            for(Account accP: accListPatientForUpdate){
                                                
                                                gen.writeObjectField('PatToken', accP.Patient_Token__c);
                                                gen.writeObjectField('PatMiddleInitial', accP.MiddleName);
                                                gen.writeObjectField('PatDiagnosis', accP.Diagnosis__c);
                                                
                                                if(patientEnrollmentMap.size()>0 || patientEnrollmentMap!=null){
                                                    gen.writeObjectField('PhysicianName', patientEnrollmentMap.get(accP.Id).Physician_name__c);
                                                    gen.writeObjectField('PhysicianPhone', patientEnrollmentMap.get(accP.Id).Physician_phone__c);
                                                    gen.writeObjectField('HTCInstContact', patientEnrollmentMap.get(accP.Id).HTC_Contact__c);
                                                    gen.writeObjectField('HTCtInstAdd1', patientEnrollmentMap.get(accP.Id).HTC_Address_1__c);
                                                    gen.writeObjectField('HTCInstAdd2', patientEnrollmentMap.get(accP.Id).HTC_Address_2__c);
                                                    gen.writeObjectField('HTCInstCity', patientEnrollmentMap.get(accP.Id).HTC_City__c);
                                                    gen.writeObjectField('HTCInstState', patientEnrollmentMap.get(accP.Id).HTC_State__c);
                                                    gen.writeObjectField('HTCZIpCode', patientEnrollmentMap.get(accP.Id).HTC_Zip_Code__c);
                                                }
                                            }
                                        gen.writeEndObject();
                                    gen.writeEndArray();
                        gen.writeEndObject();
                            gen.writeFieldName('reply');
                                gen.writeStartObject();
                                    gen.writeObjectField('status', 'Success');
                                        gen.writeFieldName('Errors');
                                            gen.writeStartArray();
                                                gen.writeStartObject();
                                                    gen.writeObjectField('ErrorCode', '');
                                                    gen.writeObjectField('ErrorMessage', '');
                                                gen.writeEndObject();
                                            gen.writeEndArray();
                                gen.writeEndObject();
                gen.writeEndObject();
                
                returnJSON = gen.getAsString();
            }
        }*/
        
        if(accListForUpdate.size()>0 || accListPatientForUpdate.size()>0){
            update accListForUpdate;
            update accListPatientForUpdate;
            
            if(enrollmentListForUpdate.size()>0){
                update enrollmentListForUpdate;
            }
            
            returnJSON = '{"reply": {"status": "1", "Errors":[{"ErrorCode" : "", "ErrorMessage" : ""}]}}';
        }
        else
        {
             returnJSON = '{"reply": {"status": "0", "Errors":[{"ErrorCode" : "", "ErrorMessage" : "No records to update."}]}}';
        }
        
        return returnJSON;
    }

    /*
     * Author: MMempin@Cloudsherpas.com
     * Date  : 12/03/2014
     * Description: This web service method will be called after the Get User method is called.
                    The information will be populated into the form from that method.
                    The user will select a Patient they wish to delete from their profile.
                    The below set of input parameters can be passed in request to delete a user successfully.
     * NOTE: modified by john.frum@cloudsherpas.com to update and not delete. Requirements are to set to inactive and
     * not delete
     * Method: POST
     */
    public static String deletePatient(string patToken,
                                       string patFirstName,
                                       string patLastName,
                                       string patBirthDate,
                                       string patZipCode){
                                        
        string returnJSON='';
        
        list<Account> patientAccountList = new list<Account>();
        list<Account> patientAccountListForDelete = new list<Account>();
        
                
        //Check for the Patient Token that is being passed on the parameter
        //Query for all Patient Account the has that token
        if(patToken!=null){
            patientAccountList = [Select Id,
                                        Type, 
                                        FirstName,
                                        LastName,
                                        BillingCity,
                                        BillingStreet,
                                        BillingState,
                                        BillingCountry,
                                        BillingPostalCode,
                                        Phone,
                                        PersonEmail,
                                        User_Token__c,
                                        Diagnosis__c,
                                        MiddleName,
                                        Patient_Token__c,
                                        Inactive__c
                                      
                                        From Account 
                                        where Patient_Token__c =: patToken
                                        And FirstName =: patFirstName
                                        And LastName =: patLastName
                                        AND BillingPostalCode =: patZipCode];
        }
        system.debug('***patientAccountList = ' + patientAccountList);
        
        if(patientAccountList.size()>0){
            for(Account acDelete: patientAccountList){
                acDelete.Inactive__c='Y';
                patientAccountListForDelete.add(acDelete);
            }
        }
        system.debug('***patientAccountListForDelete = ' + patientAccountListForDelete);
        
        if(patientAccountListForDelete.size()>0){
            update patientAccountListForDelete;
            
            returnJSON = '{"reply": {"status": "1", "Errors":[{"ErrorCode" : "", "ErrorMessage" : ""}]}}';
        }
        else
        {
             returnJSON = '{"reply": {"status": "0", "Errors":[{"ErrorCode" : "", "ErrorMessage" : "Patient Does Not Exist"}]}}';
        }
        
        return returnJSON;
    }
    
    /*
     * Author: MMempin@Cloudsherpas.com
     * Date  : 12/11/2014
     * Description: This web service method will be called after the Get User method is called.
                    The information will be populated into the form from that method.
                    The user will add a patient to their profile.
                    The below set of input parameters can be passed in request to Add a patient user successfully.
     
     * Method: POST
     */
    public static String addPatient(string UserToken,
                                   string PatToken,
                                   string PatFirstName,
                                   string PatLastName,
                                   string PatMiddleInitial,
                                   string PatDiagnosis,
                                   string PatBirthDate,
                                   string PatZipCode){
                                        
        string returnJSON='';
        
               
        list<Account> patientAccountList = new list<Account>();
        Account accP = new Account();
        
        list<Patient_Caregiver__c> patientCareList = new list<Patient_Caregiver__c>();
        list<Account> caregiverAccountList = new list<Account>();
        
        //Account RecordType schema to get recordTypeId
        Schema.DescribeSObjectResult des = Schema.SObjectType.Account;
        Map<String,Schema.RecordTypeInfo> rtMapByName = des.getRecordTypeInfosByName();
        
        //Check for the UserToken Token that is being passed on the parameter
        //Query for all caregiver Account the has that token
        if(UserToken!=null){
            caregiverAccountList = [Select Id,
                                        Type,
                                        RecordTypeId,
                                        FirstName,
                                        LastName,
                                        BillingCity,
                                        BillingStreet,
                                        BillingState,
                                        BillingCountry,
                                        BillingPostalCode,
                                        ShippingPostalCode,
                                        Phone,
                                        PersonEmail,
                                        User_Token__c,
                                        Diagnosis__c,
                                        MiddleName,
                                        Patient_Token__c,
                                        Inactive__c
                                        From Account 
                                        where User_Token__c =: UserToken];
        }
        system.debug('***caregiverAccountList = ' + caregiverAccountList);
        
        
        system.debug('***patientCareList = ' + patientCareList);
        
        if(patFirstName!=null){
            accP.FirstName = patFirstName;
        }
        
        if(PatToken!=null){
            accP.Patient_Token__c = PatToken;
            accP.User_Token__c=PatToken;
        }
        
        
        if(patLastName!=null){
            accP.LastName = patLastName;
        }
        if(PatMiddleInitial!=null){
            accP.MiddleName = PatMiddleInitial;
        }
        if(PatDiagnosis!=null){
            accP.Diagnosis__c = PatDiagnosis;
        }
        if(PatBirthDate!=null){
            
            date mydate = date.parse(PatBirthDate);
            
            accP.PersonBirthdate = mydate;
        }
        if(patZipCode!=null){
            accP.BillingPostalCode = patZipCode;
            accP.ShippingPostalCode = patZipCode;
        }
        accP.RecordTypeId = rtMapByName.get('Patient').getRecordTypeId();
        //accP.Patient_Token__c = UserToken;
        
        patientAccountList.add(accP);
        
        if(patientAccountList.size()>0){
            
            
            insert patientAccountList;
            if(caregiverAccountList!=null && caregiverAccountList.size()>0){
            for(Account accC: caregiverAccountList){
                Patient_Caregiver__c pc = new Patient_Caregiver__c();
                    pc.Caregiver__c = accC.Id;
                    pc.Patient__c = patientAccountList[0].Id;
                patientCareList.add(pc);
            }
          }
            insert patientCareList;
            returnJSON = '{"reply": {"status": "1", "Errors":[{"ErrorCode" : "", "ErrorMessage" : ""}]}}';
        }
        
        if(caregiverAccountList.size()==0){
            returnJSON = '{"reply": {"status": "0", "Errors":[{"ErrorCode" : "03", "ErrorMessage" : "Record does not exist"}]}}';
        }
        
        return returnJSON;
    }

/*
 * Author: mark.casanas@cloudsherpas.com
 * Date  : 11/27/2014
 * Description: This web service method will be called when a user requests the edit user functionality.
                The get user method below requires a set of input parameters can be passed in  as a request.
*/
    public static String getUserToken(string token){
                                        
        string returnJSON='';
        
        list<Account> accList = new list<Account>();
        list<Account> accListPatient = new list<Account>();
        
        //Account RecordType schema to get recordTypeId
        Schema.DescribeSObjectResult des = Schema.SObjectType.Account;
        Map<String,Schema.RecordTypeInfo> rtMapByName = des.getRecordTypeInfosByName();
        
        System.Debug('-------------------------->TOKEN:' + token);
        if(token!=null){
             
             accList = [Select ID, 
                                Name, 
                                Type, 
                                RecordType.Name,
                                FirstName, 
                                LastName,
                                PersonEmail,
                                BillingStreet,
                                BillingCity,
                                BillingState,
                                BillingPostalCode,
                                User_Token__c,
                                Patient_Token__c 
                                from Account 
                                where (User_Token__c = :token OR Patient_Token__c =:token) AND Inactive__c<>'Y' ];
        }
            
        set<Id> accParentId = new set<Id>();
        if(accList.size()>0){
            for(Account acId: accList){
                
                accParentId.add(acId.Id);
            }
        }
        
        set<Id> patClientID = new set<Id>();
        List<Patient_Caregiver__c> patClientList = new List<Patient_Caregiver__c>();
        
        if (accParentID.size() > 0){
            patClientList = [Select Patient__c FROM Patient_Caregiver__c WHERE Caregiver__c =: accParentID];
            for (Patient_Caregiver__c p: patClientlist){
              patClientID.add(p.Patient__c);
            }
        }
     
        if(accParentId.size()>0){
            accListPatient = [Select Id,
                                    FirstName,
                                    LastName,
                                    MiddleName,
                                    User_Token__c,
                                    Diagnosis__c,
                                    PersonBirthdate,
                                    BillingPostalCode,
                                    RecordType.Name,
                                    Patient_Token__c
                                    From Account
                                    Where  ID IN : patClientID ];
        }
        
        
        if(accList.size()>0){
            for(Account acc: accList){
                
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                    gen.writeFieldName('user');
                        gen.writeStartObject();
                           if (acc.User_Token__c!=null)
                           //changed the way of calling the encryption method in to a new class
                            gen.writeObjectField('Token', IHRestUtilities.encryptGUID(acc.User_Token__c));
                           /*if (acc.Patient_Token__c != null)*///Comment: markcarlo.mempin@cloudsherpas.com 1/07/2015- this is the one that's causing the issue on the display of two Tokens in the return value
                            /*gen.writeObjectField('Token', IHRestUtilities.encryptGUID(acc.Patient_Token__c));*/
                            
                            if(acc.RecordType.Id!=null && acc.RecordType.Id == rtMapByName.get('Patient').getRecordTypeId()){
                                gen.writeObjectField('UserType', 'P');
                            }else if(acc.RecordType.Id!=null && acc.RecordType.Id == rtMapByName.get('Caregiver').getRecordTypeId()){
                            	gen.writeObjectField('UserType', 'C');
                            }else{
                                gen.writeObjectField('UserType', '');
                            }
                            
                            if(acc.FirstName!=null){
                                gen.writeObjectField('FirstName', acc.FirstName);
                            }else{
                                gen.writeObjectField('FirstName', '');
                            }
                            
                            if(acc.LastName!=null){
                                gen.writeObjectField('LastName', acc.LastName);
                            }else{
                                gen.writeObjectField('LastName', '');
                            }
                            
                            if(acc.PersonEmail!=null){
                                gen.writeObjectField('EmailAddress', acc.PersonEmail);
                            }else{
                                gen.writeObjectField('EmailAddress', '');
                            }
                            
                            if(acc.BillingStreet!=null){
                                gen.writeObjectField('Address1', acc.BillingStreet);
                            }else{
                                gen.writeObjectField('Address1', '');
                            }
                            
                            gen.writeObjectField('Address2', '');
                            
                            if(acc.BillingCity!=null){
                                gen.writeObjectField('City', acc.BillingCity);
                            }else{
                                gen.writeObjectField('City', '');
                            }
                            
                            if(acc.BillingState!=null){
                                gen.writeObjectField('State', acc.BillingState);
                            }else{
                                gen.writeObjectField('State', '');
                            }
                            
                            if(acc.BillingPostalCode!=null){
                                gen.writeObjectField('ZipCode', acc.BillingPostalCode);
                            }else{
                                gen.writeObjectField('ZipCode', '');
                            }
                            gen.writeObjectField('Password', '');
                                
                                gen.writeFieldName('Patients');
                                     gen.writeStartArray();
                                            for(Account accP: accListPatient){
                                                
                                                 gen.writeStartObject();
                                                System.Debug('-------------------------->' + accP.FirstName);
                                                gen.writeObjectField('PatToken', IHRestUtilities.encryptGUID(accP.Patient_Token__c));
                                                gen.writeObjectField('PatFirstName', accP.FirstName);
                                                gen.writeObjectField('PatLastName', accP.LastName);
                                                if (accP.MiddleName != null)
                                                  gen.writeObjectField('PatMiddleInitial', accP.MiddleName);
                                                if (accP.Diagnosis__c != null)
                                                  gen.writeObjectField('PatDiagnosis', accP.Diagnosis__c);
                                                if (accP.PersonBirthdate != null)
                                                  gen.writeObjectField('PatBirthDate', accP.PersonBirthdate);
                                                if (accP.BillingPostalCode != null)
                                                  gen.writeObjectField('PatZipCode', accP.BillingPostalCode);
                                                
                                                 gen.writeEndObject();
                                                 
                                             }
                                           gen.writeEndArray();
                                       
                        gen.writeEndObject();
                            gen.writeFieldName('reply');
                                gen.writeStartObject();
                                    gen.writeObjectField('status', '1');
                                        gen.writeFieldName('Errors');
                                            gen.writeStartArray();
                                                gen.writeStartObject();
                                                    gen.writeObjectField('ErrorCode', '');
                                                    gen.writeObjectField('ErrorMessage', '');
                                                gen.writeEndObject();
                                            gen.writeEndArray();
                                gen.writeEndObject();
                gen.writeEndObject();
                
                returnJSON = gen.getAsString();
            }
        }else{
            returnJSON = '{"user": { "UserType": "","FirstName": "","LastName": "","MiddleInitial": "","EmailAddress": "", "Address 1": "", "Address2": "","City": "","State": "","ZipCode": "","Password": "","Patient": [{"PatFirstName": "","PatLastName": "","PatMiddleInitial": "", "PatDiagnosis": " ","PatBirthDate": "",“PatZipCode” : “”}},"reply": {"status": "Failure","Errors": [ { "ErrorCode":"04", "ErrorMessage":"User Not Found" }]}}';
        }
        return returnJSON;
    }

    /*
     * Author: john.frum@cloudsherpas.com
     * Date  : 11/4/2014
     * Description: Gets a user from the database.  
                    Following the convention of setting  the content-type to application/json and 
                    building out the reponse as a string 
     * Method: POST
     */
    
 @HttpPost
    global static void getUser(){
        RestRequest req = RestContext.request;
        String reqBody = req.requestBody.toString();
       
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(reqBody);
        map<String, Object> finalObject = (map<String, Object>) m.get('user');
        RestResponse res = RestContext.response;
        string token = '';
        res.addHeader('Content-Type', 'application/json');
        String jsonResponse = '';
        
        String method = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        String dynamicSOQL='id,' ;
        String paramName;
      
        System.Debug(reqBody);
        
        system.debug('*** m post = ' + m);
              
        Integer counter=0;
        
        //list<Object> finalObjectPatient = (list<Object>) m.get('Patient');
        //system.debug('*** POST finalObject for Delete Patient = ' + finalObjectPatient);
         
         if (method=='decryptGUID')
         {
            
            jsonResponse =  IHRestUtilities.decryptGUID((String)finalObject.get('Token'), (String)finalObject.get('IV'));
         }
        
        
         if (method=='GetRegistration'){
            try{
             if ((String)finalObject.get('Token') != null)
             {
               token = IHRestUtilities.decryptGUID((String)finalObject.get('Token'), (String)finalObject.get('IV'));
        	
             }
             jsonResponse = getRegistration(token, token, (String)finalObject.get('UserType') );
            }
            catch(Exception e){
             jsonResponse = ErrorGeneratorResponse.errorResponse('0', e.getMessage());
            }
         }
        
      
          if (method=='dupCheckPatient'){
          	
          	system.debug('***Method in');
          	
             finalObject = (map<String, Object>) m.get('patient');
             system.debug('***finalObject = ' + finalObject);
             
             string patientFirstName =  (String)finalObject.get('PatFirstName');
             system.debug('***patientFirstName = ' + patientFirstName);
             
             string patientLastName = (String)finalObject.get('PatLastName');
             system.debug('***patientLastName = ' + patientLastName);
             
             string zipCode =  (String)finalObject.get('ZipCode');
             system.debug('***zipCode = ' + zipCode);
             
             string patBirth =  (String)finalObject.get('PatBirthDate');
             system.debug('***patBirth = ' + patBirth);
             
             try{
             	system.debug('***Try in');
               jsonResponse = checkDuplicatePatient(patientFirstName, patientLastName, zipCode, patBirth);
             }
             catch(Exception e){
             	system.debug('***Catch in');
              jsonResponse = ErrorGeneratorResponse.errorResponse('0', e.getMessage());
            }
            
            system.debug('***jsonResponse = ' + jsonResponse);
             
          }
         
          
          if (method=='dupCheckUserEmail'){
            
              //Commented MacMempin - 12/16/2014 -- String token = (String)finalObject.get('Token');
              String email = (String)finalObject.get('EmailAddress');
              
              //Commented MacMempin - 12/16/2014 -- system.debug('*** m token = ' + token);
              system.debug('*** m email = ' + email);
              try{
                jsonResponse = checkDuplicateUserEmail(email/*Commented MacMempin - 12/16/2014 -- , token*/);
              }
             catch(Exception e){
               jsonResponse = ErrorGeneratorResponse.errorResponse('-1', e.getMessage());
            }
              
         }
         
         /*
         * Author: MMempin@Cloudsherpas.com
         * Date  : 12/03/2014
         * Description: To Delete Patient Account based on the parameters passed
         * Method: POST
         */
         if(method=='deletePatient'){
         	
         	list<Object> finalObjectPatient = (list<Object>) m.get('Patient');
        	system.debug('*** POST finalObject for Delete Patient = ' + finalObjectPatient);
         	
             if(finalObjectPatient != null && counter<=finalObjectPatient.size()){
              counter++;
            }
       
            system.debug('***counter = ' + counter);
        
            map<String, Object> finalPatientval = (map<String, Object>) finalObjectPatient[counter-1];
            system.debug('*** finalPatientval = ' + finalPatientval);
            String patToken = (String)finalPatientval.get('PatToken');
            
            String patFirstName = (String)finalPatientval.get('PatFirstName');
            String patLastName = (String)finalPatientval.get('PatLastName');
            String patBirthDate = (String)finalPatientval.get('PatBirthDate');
            String patZipCode = (String)finalPatientval.get('PatZipCode');
            
            system.debug('*** finalObject patToken = ' + patToken);
            system.debug('*** finalObject patFirstName = ' + patFirstName);
            system.debug('*** finalObject patLastName = ' + patLastName);
            system.debug('*** finalObject patBirthDate = ' + patBirthDate);
            system.debug('*** finalObject patZipCode = ' + patZipCode);
            
            jsonResponse = deletePatient(patToken, patFirstName, patLastName, patBirthDate, patZipCode);
            
         }
         
         
        map<String, Object> finalPatientval;
        String UserToken = '';
        String patFirstName = '';
        String patLastName = '';
        String patMiddleInitial = '';
        String patDiagnosis = '';
        String patBirthDate = '';
        String patZipCode = '';
        String patToken = '';
         
         /*
         * Author: MMempin@Cloudsherpas.com
         * Date  : 12/11/2014
         * Description: To Add Patient Account based on the parameters passed
         * Method: POST
         */
         if(method=='addPatient'){
         	
         	list<Object> finalObjectPatient = (list<Object>) m.get('Patient');
        	system.debug('*** POST finalObject for Delete Patient = ' + finalObjectPatient);
         	
            if(finalObjectPatient != null && counter<=finalObjectPatient.size()){
                counter++;
            }
            system.debug('***counter = ' + counter);
            
            
            if(finalObjectPatient!=null){
                finalPatientval = (map<String, Object>) finalObjectPatient[counter-1];
            }
            system.debug('*** finalPatientval = ' + finalPatientval);
            
            if((String)finalPatientval.get('Token')!=null){
                UserToken = IHRestUtilities.decryptGUID((String)finalPatientval.get('Token'), (String)finalPatientval.get('IV')) ;
            }else{
                UserToken = '';
            }
            
            if((String)finalPatientval.get('PatFirstName')!=null){
                patFirstName = (String)finalPatientval.get('PatFirstName');
            }else{
                patFirstName = '';
            }
            
            if((String)finalPatientval.get('PatLastName')!=null){
                patLastName = (String)finalPatientval.get('PatLastName');
            }else{
                patLastName = '';
            }
            
            if((String)finalPatientval.get('PatToken')!=null){
                patToken = (String)finalPatientval.get('PatToken');
            }else{
                patToken = '';
            }
            
            
            if((String)finalPatientval.get('PatMiddleInitial')!=null){
                patMiddleInitial = (String)finalPatientval.get('PatMiddleInitial');
            }else{
                patMiddleInitial = '';
            }
            
            if((String)finalPatientval.get('PatDiagnosis')!=null){
                patDiagnosis = (String)finalPatientval.get('PatDiagnosis');
            }else{
                patDiagnosis = '';
            }
            
            if((String)finalPatientval.get('PatBirthDate')!=null){
                patBirthDate = (String)finalPatientval.get('PatBirthDate');
            }else{
                patBirthDate = '';
            }
            
            if((String)finalPatientval.get('PatZipCode')!=null){
                patZipCode = (String)finalPatientval.get('PatZipCode');
            }else{
                patZipCode = '';
            }
            
                        
            jsonResponse = addPatient(UserToken,
                                       patToken,
                                       patFirstName,
                                       patLastName,
                                       patMiddleInitial,
                                       patDiagnosis,
                                       patBirthDate,
                                       patZipCode);
            
         }
         
         
            res.responseBody = blob.valueOf(jsonResponse);
          return ;
    }
    
    
    /*
     * Author: MMempin@Cloudsherpas.com
     * Date  : 11/26/2014
     * Description: This web service method will be called to create a new user in the Inventiv database.  
                    The below set of input parameters can be passed in request to Create User successfully.
     * Method: PUT
     */
    @HttpPut
    global static void createUsers(){
        RestRequest req = RestContext.request;
        String reqBody = req.requestBody.toString();
        system.debug('***reqBody Create User = ' + reqBody);
             
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        String jsonResponse = '';
        
        //Look for the method that is indicated in the parameter
        String method = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        system.debug('*** method = ' + method);
        String dynamicSOQL='id,';
        String paramName;
        
        System.Debug(reqBody);
        //Look for the request body and cast it with it's string as key to get it's value
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(reqBody);
        system.debug('*** m = ' + m);
        
        map<String, Object> finalObject = (map<String, Object>) m.get('user');
        string token = IHRestUtilities.decryptGUID((String)finalObject.get('Token'), (String)finalObject.get('IV'));
        system.debug('*** finalObject = ' + finalObject);
        
        Integer counter=0;
        
       
        
        /*
         * Author: MMempin@Cloudsherpas.com
         * Date  : 11/26/2014
         * Description: This will create Account and a Patient id any and an Enrollment record for that Patient
         * Method: PUT
         */
        if (method=='CreateUser'){
             list<Object> finalObjectPatient = (list<Object>) finalObject.get('Patients');
             system.debug('*** P = ' + finalObjectPatient);
        
             if(finalObjectPatient!=null && counter<=finalObjectPatient.size()){
              counter++;
            }
             system.debug('***counter = ' + counter);
            
            map<String, Object> finalPatientval;
            if(finalObjectPatient!=null){
                finalPatientval = (map<String, Object>) finalObjectPatient[counter-1];
            }
            system.debug('*** finalPatientval = ' + finalPatientval);
            
           
            string recType = (String)finalObject.get('UserType');
            string fName = (String)finalObject.get('FirstName');
            string lName = (String)finalObject.get('LastName');
            
            string midInitial = (String)finalObject.get('MiddleInital');
            string email = (String)finalObject.get('EmailAddress');
            string add1 = (String)finalObject.get('Address1');
            string add2 = (String)finalObject.get('Address2');
            string city = (String)finalObject.get('City');
            string state = (String)finalObject.get('State');
            string zip = (String)finalObject.get('ZipCode');
            
            string PatToken = '';
            string PatZipCode = '';
            string PatFirstName = '';
            string PatLastName = '';
            string PatMiddleInital = '';
            string PatDiagnosis = '';
            string PatBirthDate ='';
            
            if(finalPatientval!=null){
                PatToken = IHRestUtilities.decryptGUID((String)finalPatientval.get('PatToken'), (String)finalPatientval.get('IV'));
                PatZipCode = (String)finalPatientval.get('PatZipCode');
                PatFirstName = (String)finalPatientval.get('PatFirstName');
                PatLastName = (String)finalPatientval.get('PatLastName');
                PatMiddleInital = (String)finalPatientval.get('PatMiddleInital');
                PatDiagnosis = (String)finalPatientval.get('PatDiagnosis');
                PatBirthDate = (String)finalPatientval.get('PatBirthDate');
            }
            
            system.debug('*** token = ' + token);
            system.debug('*** recType = ' + recType);
            system.debug('*** PatToken = ' + PatToken);
            system.debug('*** PatZipCode = ' + PatZipCode);
         
           try{
             jsonResponse = createUser(token, recType, fName, lName, midInitial, email, add1, add2, city, state, zip, PatToken, PatZipCode, PatFirstName, PatLastName, PatMiddleInital, PatDiagnosis, PatBirthDate);
          
            } 
            catch(Exception e){
             jsonResponse = ErrorGeneratorResponse.errorResponse('0', e.getMessage());
            }
         
        }
        
        if(method=='getUserToken' || method=='GetUser'){
           try{
              jsonResponse = getUserToken(token);
            }
            catch(Exception e){
             jsonResponse = ErrorGeneratorResponse.errorResponse('0', e.getMessage());
            }
        }
        
        /*
         * Author: MMempin@Cloudsherpas.com
         * Date  : 11/26/2014
         * Description: This will return the information of the Account
         * Method: PUT
         */
        if(method=='EditUser'){
            
            list<Object> finalObjectPatient = (list<Object>) finalObject.get('Patients');
            
            if(finalObjectPatient!=null && counter<=finalObjectPatient.size()){
                counter++;
            }
            system.debug('***counter edit user = ' + counter);
            
            map<String, Object> finalPatientval;
            if(finalObjectPatient!=null){
                finalPatientval = (map<String, Object>) finalObjectPatient[counter-1];
            }
            system.debug('*** finalPatientval edit user = ' + finalPatientval);
            
           
            string diagnosis = (String)finalObject.get('');
            string middleInitial = (String)finalObject.get('MiddleInitial');
            string add1 = (String)finalObject.get('Address 1');
            string add2 = (String)finalObject.get('Address2');
            string city = (String)finalObject.get('City');
            string state = (String)finalObject.get('State');
            string zip = (String)finalObject.get('ZipCode');
            
            string patToken = (String)finalPatientval.get('PatToken');
            string patMiddleInitial = (String)finalPatientval.get('PatMiddleInitial');
            string patDiagnosis = (String)finalPatientval.get('PatDiagnosis');
            string physicianName = (String)finalPatientval.get('PhysicianName');
            string physicianPhone = (String)finalPatientval.get('PhysicianPhone');
            string htcInstContact = (String)finalPatientval.get('HTCInstContact');
            string htcInstAdd1 = (String)finalPatientval.get('HTCtInstAdd1');
            string htcInstAdd2 = (String)finalPatientval.get('HTCInstAdd2');
            string htcInstCity = (String)finalPatientval.get('HTCInstCity');
            string htcInstState = (String)finalPatientval.get('HTCInstState');
            string htcInstZipCode = (String)finalPatientval.get('HTCZIpCode');
            
            
             jsonResponse = editUser(token,
                                      middleInitial,
                                      add1,
                                      add2,
                                      city,
                                      state,
                                      zip,
                                      patToken,
                                      patMiddleInitial,
                                      patDiagnosis,
                                      physicianName,
                                      physicianPhone,
                                      htcInstContact,
                                      htcInstAdd1,
                                      htcInstAdd2,
                                      htcInstCity,
                                      htcInstState,
                                      htcInstZipCode);
        }
        
        res.responseBody = blob.valueOf(jsonResponse);
        return ;
    }
    
}