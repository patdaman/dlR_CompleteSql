--      -- SQL Server Syntax  
--ALTER LOGIN login_name   
--    {   
--    <status_option>   
--    | WITH <set_option> [ ,... ]  
--    | <cryptographic_credential_option>  
--    }   
--[;]  
  
--<status_option> ::=  
--        ENABLE | DISABLE  
  
--<set_option> ::=              
--    PASSWORD = 'password' | hashed_password HASHED  
--    [   
--      OLD_PASSWORD = 'oldpassword'  
--      | <password_option> [<password_option> ]   
--    ]  
--    | DEFAULT_DATABASE = database  
--    | DEFAULT_LANGUAGE = language  
--    | NAME = login_name  
--    | CHECK_POLICY = { ON | OFF }  
--    | CHECK_EXPIRATION = { ON | OFF }  
--    | CREDENTIAL = credential_name  
--    | NO CREDENTIAL  
  
--<password_option> ::=   
--    MUST_CHANGE | UNLOCK  
  
--<cryptographic_credentials_option> ::=   
--    ADD CREDENTIAL credential_name  
--  | DROP CREDENTIAL credential_name  