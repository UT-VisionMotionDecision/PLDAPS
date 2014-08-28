classdef PlxConnection < handle
    %PLXCONNECTION a simple wrapper for a connection to a Plexon server 
    %that cleans itself up on destruction
    
    properties
        name
    end
    
    methods
        function [this] = PlxConnection
            this.name = PL_InitClient(0);
        end
        
        function delete(this)
            PL_Close(this.name);
        end
    end
    
end

