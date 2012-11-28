/*
ERDB Service API specification

This service wraps the ERDB software and allows querying the CDS via the ERDB
using typecompiler generated clients rather than direct Perl imports of the ERDB
code.

The exposed functions behave, generally, identically to the ERDB functions documented
<a href='http://pubseed.theseed.org/sapling/server.cgi?pod=ERDB#Query_Methods'>here</a>.
It is expected that users of this service already understand how to query the CDS via
the ERDB.

*/

module ERDB_Service
{
	typedef string objectNames;
	typedef string filterClause;
	typedef string parameter;
	typedef list<parameter> parameters;
	typedef string fields;
	typedef int count;
	typedef string fieldValue;
	typedef list<fieldValue> fieldValues;
	typedef list<fieldValues> rowlist;
    
    /*
    Wrapper for the GetAll function documented <a href='http://pubseed.theseed.org/sapling/server.cgi?pod=ERDB#GetAll'>here</a>.
    Note that the objectNames and fields arguments must be strings; array references are not allowed.
    */
    funcdef GetAll(objectNames, filterClause, parameters, fields, count) returns(rowlist);
    
};
