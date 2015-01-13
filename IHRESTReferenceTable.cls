@RestResource(urlMapping='/IHRRESTReferenceTable/*')

global class IHRESTReferenceTable {
	
	 @HttpPost 
	 global static String GetReferenceTable(){
	 	
	 	string returnJSON='';
	 	
	 	RestRequest req = RestContext.request;
	  	String reqBody = req.requestBody.toString();
	  	
	  	RestResponse res = RestContext.response;
	  	res.addHeader('Content-Type', 'application/json');
	  	
	  	Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(reqBody);
	  	string tableName = (String)m.get('TableName');
	 	String theQuery = 'SELECT ';
      
	    Schema.sObjectType objectDef = Schema.getGlobalDescribe().get(tableName).getDescribe().getSObjectType();
	   
	    Map<String, Schema.SobjectField> ObjectFieldsMap = objectDef.getDescribe().fields.getMap();
	    List<Schema.SObjectField> fldObjMapValues = objectFieldsMap.values();
	   Integer fieldCount=0;
	   for(Schema.SObjectField s : fldObjMapValues)
       {
         String theLabel = s.getDescribe().getLabel(); // Perhaps store this in another map
         String theName = s.getDescribe().getName();
         fieldCount += 1;

       // Continue building your dynamic query string
         theQuery += theName + ',';
         
       }
        System.Debug(theQuery);
        
        if (fieldCount==0){
        	returnJSON = '{"reply": {"status": "Failure", "Table Name :" "' + tableName + '" "Errors":[{"ErrorCode" : "03", "ErrorMessage" : "No Such Table Exists"}]}}';
        }
        theQuery = theQuery.subString(0, theQuery.length() - 1);
 
        theQuery += ' FROM ' + tableName;
        
          //**************jfrum
         sObject sObj = Schema.getGlobalDescribe().get(tableName).newSObject() ;
	     list<sObject> queryObject = new list<sObject>();
		 queryObject = Database.query(theQuery);
	    //*****************
        
        getRecord(theQuery);
    	system.debug('*** getRecord(theQuery) = ' + getRecord(theQuery));
        list<Object> objectTempList = new list<Object>();
        objectTempList = (list<Object>) getRecord(theQuery);
        system.debug('*** objectTempList = ' + objectTempList);
        
    	JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
                gen.writeFieldName('reply');
                    gen.writeStartObject();
                        gen.writeObjectField('status', 'Success');
                        gen.writeObjectField('TableName', tableName);
                        
                        for(Object tmpObj: objectTempList){
                        	gen.writeFieldName(tableName);
                        		gen.writeStartArray();
                             		gen.writeStartObject();
                        				//*****jfrum
                        				for (sObject f: queryObject){
		  	                            	for (String s : ObjectFieldsMap.Keyset()){
		  		                            	try{
		  		                                 	//System.Debug('------------------>' + s + ' - ' + f.Get(s));
		  		                                	gen.writeObjectField(s, f.Get(s));
		  		                                }catch(Exception e){
		  		                                	returnJSON = '{"reply": {"status": "Failure", "Table Name :" "' + tableName + '" "Errors":[{"ErrorCode" : "03", "ErrorMessage" : "' + e +'"}]}}';
		  		                                }
		  	                                 }
		                                 }
                        				//**************
                             		gen.writeEndObject();
                             	gen.writeEndArray();	
                        }
                        
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
        system.debug('***returnJSON1 = ' + returnJSON);
        
        //JSON build response to the Blob value of json string
        res.responseBody = blob.valueOf(returnJSON);
        
	    return returnJSON;
	 }
	
	/*
	 * Author: MMempin @Clousherpas.com
	 * Description: returns the record of the query string built on the param
	 * Date: 12/03/2014
	 */
	public static list<Object> getRecord(string Query){
		
		list<Object> queryObject = new list<Object>();
		 queryObject = Database.query(Query);
		 
		 system.debug('***queryObject = ' + queryObject);
		
		return queryObject;
	}

}