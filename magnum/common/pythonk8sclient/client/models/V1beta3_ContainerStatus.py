#!/usr/bin/env python
"""
Copyright 2015 Reverb Technologies, Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
"""

class V1beta3_ContainerStatus(object):
    """NOTE: This class is auto generated by the swagger code generator program.
    Do not edit the class manually."""


    def __init__(self):
        """
        Attributes:
          swaggerTypes (dict): The key is attribute name and the value is attribute type.
          attributeMap (dict): The key is attribute name and the value is json key in definition.
        """
        self.swaggerTypes = {
            
            'containerID': 'str',
            
            
            'image': 'str',
            
            
            'imageID': 'str',
            
            
            'lastState': 'v1beta3_ContainerState',
            
            
            'name': 'str',
            
            
            'ready': 'bool',
            
            
            'restartCount': 'int',
            
            
            'state': 'v1beta3_ContainerState'
            
        }

        self.attributeMap = {
            
            'containerID': 'containerID',
            
            'image': 'image',
            
            'imageID': 'imageID',
            
            'lastState': 'lastState',
            
            'name': 'name',
            
            'ready': 'ready',
            
            'restartCount': 'restartCount',
            
            'state': 'state'
            
        }       

        
        #container&#39;s ID in the format &#39;docker://&lt;container_id&gt;&#39;
        
        self.containerID = None # str
        
        #image of the container
        
        self.image = None # str
        
        #ID of the container&#39;s image
        
        self.imageID = None # str
        
        #details about the container&#39;s last termination condition
        
        self.lastState = None # v1beta3_ContainerState
        
        #name of the container; must be a DNS_LABEL and unique within the pod; cannot be updated
        
        self.name = None # str
        
        #specifies whether the container has passed its readiness probe
        
        self.ready = None # bool
        
        #the number of times the container has been restarted, currently based on the number of dead containers that have not yet been removed
        
        self.restartCount = None # int
        
        #details about the container&#39;s current condition
        
        self.state = None # v1beta3_ContainerState
        
