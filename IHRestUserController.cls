@RestResource(urlMapping='/IHRestUserController/*')



global class IHRestUserController {
	@HttpGet
	global static List<Account> getUser(){
	  String token = RestContext.request.params.get('token');
	  List<Account> userInfo = [ Select ID, Name, Type, 
	                               First_Name__c, Last_Name__c,
		                           User_Token__c, Phone, email__c 
		                           from Account 
		                           where User_Token__c = :token];
      
	  return userInfo;
	}
	
	@HttpPost
	global static String createUser(String token, String userType, String firstName, 
	  string lastName, String emailAddress, String phone) {
      string response;
      Boolean userExists=false;
     
      List<Account> ihUser = [Select User_Token__c 
                             FROM Account 
                             WHERE User_Token__c = :token];
	 
	 if(ihUser.size() > 0) {
	 	userExists = true;
	 	response = 'user already exists';
	 }
    
      Account a = new Account();
      if (userExists==false){
        a.Name = firstName + ' ' + lastName;
        a.First_Name__c = firstName;
        a.Last_Name__c = lastName;
        a.User_Token__c=token;
        a.Phone = phone;
        a.Email__c = emailAddress;
        
        if (userType=='P')
          a.RecordTypeID = '012j0000000J1ozAAC';
        else
          a.RecordTypeID = '012j0000000YOdyAAG';
         response = 'Success';
         insert a;
     }
        
     return response;
  }

}