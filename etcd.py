# (c) 2013, Jan-Piet Mens <jpmens(at)gmail.com>
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

from ansible import utils
import os
import collections

try:
    import json
except ImportError:
    import simplejson as json

from ansible.module_utils.urls import open_url

# this can be made configurable, not should not use ansible.cfg
ANSIBLE_ETCD_URL = 'http://127.0.0.1:4001'
if os.getenv('ANSIBLE_ETCD_URL') is not None:
    ANSIBLE_ETCD_URL = os.environ['ANSIBLE_ETCD_URL']
# this can be made configurable, not should not use ansible.cfg
ANSIBLE_ETCD_API = 'v2'
if os.getenv('ANSIBLE_ETCD_API') is not None:
    ANSIBLE_ETCD_API = os.environ['ANSIBLE_ETCD_API']

class Etcd(object):
    def __init__(self, url=ANSIBLE_ETCD_URL, validate_certs=True, api=ANSIBLE_ETCD_API):
        self.url = url
        self.baseurl = ('%s/' + api + '/keys') % (self.url)
        self.validate_certs = validate_certs

    def get(self, key):
        url = "%s/%s" % (self.baseurl, key)
        data = None
        try:
            r = open_url(url, validate_certs=self.validate_certs)
            data = r.read()
        except:
            return data

        try:
            # {"action":"get","key":"/name","value":"Jane Jolie","index":5}
            value=[]
            nodes = json.loads(data)['node']
            if 'nodes' in nodes:
                nodes=nodes['nodes']
                for node in nodes:
                    if 'key' in node:
                        value.append(node['key'])
                    elif 'value' in node:
                        value.append(node['value'])
                    elif 'errorCode' in node:
                        value.append("ENOENT")
                        break
            else:
               if 'value' in nodes:
                   value = nodes['value']
               elif 'key' in nodes:
                   value = nodes['key']
               elif 'errorCode' in nodes:
                   value = "ENOENT"
        except:
            raise
            pass

        return value

class LookupModule(object):

    def __init__(self, basedir=None, **kwargs):
        self.basedir = basedir

    def run(self, terms, inject=None, **kwargs):

        terms = utils.listify_lookup_plugin_terms(terms, self.basedir, inject)

        if isinstance(terms, basestring):
            terms = [ terms ]

        validate_certs = kwargs.get('validate_certs', True)

        etcd = Etcd(validate_certs=validate_certs)
        ret = []
        for term in terms:
            key = term.split()[0]
            value = etcd.get(key)
            if isinstance( value, list ):
                ret.extend(value)
            elif isinstance( value, basestring ):
                ret.append(value)
        print "Returning : " + str(ret)
        return ret

