classdef EpochXMLPersistor < Symphony.Core.EpochPersistor
   
    properties (Access = private)
        Path
        DocNode
        ExperimentNode
        GroupNodes
    end
    
    methods
        
        function obj = EpochXMLPersistor(xmlPath)
            obj = obj@Symphony.Core.EpochPersistor();
            
            obj.Path = xmlPath;
            obj.DocNode = com.mathworks.xml.XMLUtils.createDocument('experiment');
            obj.ExperimentNode = obj.DocNode.getDocumentElement;
            obj.GroupNodes = {obj.ExperimentNode};
        end
        
        
        function BeginEpochGroup(obj, label, source, keywords, properties, identifier, startTime)
            [formattedTime, formattedZone] = formatXMLDate(startTime.DateTime);
            
            groupNode = obj.GroupNodes{end}.appendChild(obj.DocNode.createElement('epochGroup'));
            groupNode.setAttribute('label', label);
            groupNode.setAttribute('identifier', char(identifier.ToString()));
            groupNode.setAttribute('startTime', formattedTime);
            groupNode.setAttribute('timeZone', formattedZone);
            
            sourcesNode = groupNode.appendChild(obj.DocNode.createElement('sourceHierarchy'));
            sourceNode = sourcesNode.appendChild(obj.DocNode.createElement('source'));
            sourceNode.appendChild(obj.DocNode.createTextNode(source));
            
            keywordsNode = groupNode.appendChild(obj.DocNode.createElement('keywords'));
            for i = 1:numel(keywords)
                keywordNode = keywordsNode.appendChild(obj.DocNode.createElement('keyword'));
                keywordNode.appendChild(obj.DocNode.createTextNode(keywords(i)));
            end
            
            obj.serializeParameters(groupNode, properties, 'properties');
            
            obj.GroupNodes{end + 1} = groupNode;
        end
        
        
        function Serialize(obj, epoch)
            epochNode = obj.DocNode.createElement('epoch');
            epochNode.setAttribute('protocolID', epoch.ProtocolID);
            epochNode.setAttribute('UUID', epoch.Identifier);
            epochNode.setAttribute('startTime', formatXMLDate(epoch.StartTime));
            obj.GroupNodes{end}.appendChild(epochNode);
            
            % Serialize the device backgrounds.
            backgroundsNode = obj.DocNode.createElement('background');
            epochNode.appendChild(backgroundsNode);
            backgroundEnum = epoch.Backgrounds.GetEnumerator();
            while backgroundEnum.MoveNext()
                device = backgroundEnum.Current.Key;
                background = backgroundEnum.Current.Value;
                backgroundNode = obj.DocNode.createElement(device.Name);
                backgroundsNode.appendChild(backgroundNode);
                backgroundMeasurementNode = obj.DocNode.createElement('backgroundMeasurement');
                backgroundNode.appendChild(backgroundMeasurementNode);
                obj.addMeasurementNode(backgroundMeasurementNode, background.Value.Quantity, background.Value.DisplayUnit, 'measurement');
                sampleRateNode = obj.DocNode.createElement('sampleRate');
                backgroundNode.appendChild(sampleRateNode);
                obj.addMeasurementNode(sampleRateNode, background.SampleRate.Quantity, background.SampleRate.DisplayUnit, 'measurement');
            end
            
            % Serialize the protocol parameters.
            obj.serializeParameters(epochNode, epoch.ProtocolParameters, 'protocolParameters');
            
            % Serialize the stimuli.
            stimuliNode = obj.DocNode.createElement('stimuli');
            epochNode.appendChild(stimuliNode);
            stimulusEnum = epoch.Stimuli.GetEnumerator();
            while stimulusEnum.MoveNext()
                device = stimulusEnum.Current.Key;
                stimulus = stimulusEnum.Current.Value;
                stimulusNode = obj.DocNode.createElement('stimulus');
                stimulusNode.setAttribute('device', device.Name); 
                stimulusNode.setAttribute('stimulusID', stimulus.StimulusID); 
                stimuliNode.appendChild(stimulusNode);
                
                obj.serializeParameters(stimulusNode, stimulus.Parameters, 'parameters');
            end
            
            % Serialize the responses.
            responsesNode = obj.DocNode.createElement('responses');
            epochNode.appendChild(responsesNode);
            responseEnum = epoch.Responses.GetEnumerator();
            while responseEnum.MoveNext()
                device = responseEnum.Current.Key;
                response = responseEnum.Current.Value;
                responseNode = obj.DocNode.createElement('response');
                responseNode.setAttribute('device', device.Name); 
                responsesNode.appendChild(responseNode);
                
                inputTimeNode = obj.DocNode.createElement('inputTime');
                inputTimeNode.appendChild(obj.DocNode.createTextNode(formatXMLDate(response.InputTime)));
                responseNode.appendChild(inputTimeNode);
                sampleRateNode = obj.DocNode.createElement('sampleRate');
                responseNode.appendChild(sampleRateNode);
                obj.addMeasurementNode(sampleRateNode, response.SampleRate.Quantity, response.SampleRate.DisplayUnit, 'measurement');
                dataNode = obj.DocNode.createElement('data');
                responseNode.appendChild(dataNode);
                responseData = Symphony.Core.MeasurementList.ToQuantityArray(response.Data);
                responseUnits = Symphony.Core.MeasurementList.HomogenousDisplayUnits(response.Data);
                for i = 1:length(responseData)
                    obj.addMeasurementNode(dataNode, responseData(i), responseUnits, 'measurement');
                end
                % TODO: serialize data configurations
            end
            
            % Serialize the keywords
            keywordsNode = obj.DocNode.createElement('keywords');
            epochNode.appendChild(keywordsNode);
            for i = 1:epoch.Keywords.Count()
                keywordNode = keywordsNode.appendChild(obj.DocNode.createElement('keyword'));
                keywordNode.appendChild(obj.DocNode.createTextNode(epoch.Keywords.Item(i - 1)));
            end
        end
        
        
        function EndEpochGroup(obj)
            obj.GroupNodes(end) = [];
        end
        
        
        function CloseDocument(obj)
            xmlwrite(obj.Path, obj.DocNode);
        end
        
        
        function serializeParameters(obj, rootNode, parameters, nodeName)
            paramsNode = obj.DocNode.createElement(nodeName);
            rootNode.appendChild(paramsNode);
            
            paramEnum = parameters.GetEnumerator();
            while paramEnum.MoveNext()
                name = paramEnum.Current.Key;
                value = paramEnum.Current.Value;
                paramNode = obj.DocNode.createElement(name);
                if islogical(value)
                    if value
                        paramNode.appendChild(obj.DocNode.createTextNode('True'));
                    else
                        paramNode.appendChild(obj.DocNode.createTextNode('False'));
                    end
                elseif isnumeric(value)
                    paramNode.appendChild(obj.DocNode.createTextNode(num2str(value)));
                elseif ischar(value)
                    paramNode.appendChild(obj.DocNode.createTextNode(value));
                else
                    error('Don''t know how to serialize parameters of type ''%s''', class(value));
                end
                paramsNode.appendChild(paramNode);
            end
        end
        
        
        function addMeasurementNode(obj, rootNode, quantity, displayUnit, nodeName)
            measurementNode = obj.DocNode.createElement(nodeName);
            measurementNode.setAttribute('qty', num2str(quantity));
            measurementNode.setAttribute('unit', displayUnit);
            rootNode.appendChild(measurementNode);
        end
        
    end
    
end