##########################################################
#
# Autogenerated by the KBase type compiler -
# any changes made here will be overwritten
#
# Passes on URLError and BadStatusLine exceptions, see 
#     http://docs.python.org/2/library/urllib2.html
#     http://docs.python.org/2/library/httplib.html
#
##########################################################

try:
    import json
except ImportError:
    import sys
    sys.path.append('simplejson-2.3.3')
    import simplejson as json
    
import urllib2, httplib
from urllib2 import URLError

class ServerError(Exception):

    def __init__(self, name, code, message):
        self.name = name
        self.code = code
        self.message = message

    def __str__(self):
        return self.name + ': ' + str(self.code) + '. ' + self.message

class ERDB_Service:

    def __init__(self, url, timeout = 30 * 60):
        if url != None:
            self.url = url
        self.timeout = int(timeout)
        if self.timeout < 1:
            raise ValueError('Timeout value must be at least 1 second')

    def GetAll(self, objectNames, filterClause, parameters, fields, count):

        arg_hash = { 'method': 'ERDB_Service.GetAll',
                     'params': [objectNames, filterClause, parameters, fields, count],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        ret = urllib2.urlopen(self.url, body, timeout = self.timeout)
        if ret.code != httplib.OK:
            raise URLError('Received bad response code from server:' + ret.code)
        resp = json.loads(ret.read())

        if 'result' in resp:
            return resp['result'][0]
        elif 'error' in resp:
            raise ServerError(**resp['error'])
        else:
            raise ServerError('Unknown', 0, 'An unknown server error occurred')




        