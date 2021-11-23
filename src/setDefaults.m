% Copyright (C) 2021, Jorge M. Perez Zerpa, J. Bruno Bazzano, Joaquin Viera,
%   Mauricio Vanzulli, Marcelo Forets, Jean-Marc Battini, Sebastian Toro
%
% This file is part of ONSAS.
%
% ONSAS is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% ONSAS is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with ONSAS.  If not, see <https://www.gnu.org/licenses/>.

%md set optional fields defaults
function [ materials, elements, boundaryConds, analysisSettings, otherParams ] = setDefaults( materials, elements, boundaryConds, analysisSettings, otherParams )

% materials
materials         = checkOrSetDefault ( materials        , 'density'       , 0   ) ;

% elements
elements          = checkOrSetDefault ( elements         , 'elemTypeParams'   , []   ) ;
elements          = checkOrSetDefault ( elements         , 'elemTypeGeometry' , []   ) ;
elements          = checkOrSetDefault ( elements         , 'elemTypeAero'     , []   ) ;
elements          = checkOrSetDefault ( elements         , 'userDragCoef'     , []   ) ;
elements          = checkOrSetDefault ( elements         , 'userLiftCoef'     , []   ) ;
elements          = checkOrSetDefault ( elements         , 'userMomentCoef'   , []   ) ;

% boundaryConds
boundaryConds    =  checkOrSetDefault ( boundaryConds    , 'loadsTimeFact' , [] ) ;

% analysis
analysisSettings  = checkOrSetDefault ( analysisSettings , 'booleanSelfWeight'  , false  )  ;
analysisSettings  = checkOrSetDefault ( analysisSettings , 'Utp10'              , [] )  ;
analysisSettings  = checkOrSetDefault ( analysisSettings , 'solverLang'         , 'Octave' ) ;
analysisSettings  = checkOrSetDefault ( analysisSettings , 'methodName'         , 'newtonRaphson' ) ;
analysisSettings  = checkOrSetDefault ( analysisSettings , 'deltaT'             , 1    ) ;
analysisSettings  = checkOrSetDefault ( analysisSettings , 'finalTime'          , 1    ) ;
analysisSettings  = checkOrSetDefault ( analysisSettings , 'stopTolDeltau'      , 1e-6 ) ;
analysisSettings  = checkOrSetDefault ( analysisSettings , 'stopTolForces'      , 1e-6 ) ;
analysisSettings  = checkOrSetDefault ( analysisSettings , 'stopTolIts'         , 10   ) ;


% otherParams
otherParams       = checkOrSetDefault ( otherParams      , 'screenOutputBool', 1  ) ;
otherParams       = checkOrSetDefault ( otherParams      , 'plotsFormat', []  ) ;
otherParams       = checkOrSetDefault ( otherParams      , 'nodalDispDamping', 0 ) ;




%md function that checks if a field is defined in a (scalar or array) struct
%md and sets a default value if it is not defined.

function structName = checkOrSetDefault( structName, fieldName, default )

if ~isfield( structName, fieldName )
  for i=1:length( structName )
    aux(i)  = setfield( structName(i), fieldName, default ) ;
  end
  structName = aux ;
end