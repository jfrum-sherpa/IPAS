@RestResource(urlMapping='/IHRestApplication/v1/*')

global class IHRestApplications {
@HttpGet
	global static void getApplicationTypes(){
		RestRequest req = RestContext.request;
        String reqBody = req.requestBody.toString();
	    RestResponse res = RestContext.response;
	   
	    /*
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
		*/
		
	    
		Schema.DescribeSObjectResult R = Application__c.SObjectType.getDescribe();
    	List<Schema.RecordTypeInfo> recType = R.getRecordTypeInfos();
    	
    	
        system.debug('******' + recType);
        
		
	}
	
}