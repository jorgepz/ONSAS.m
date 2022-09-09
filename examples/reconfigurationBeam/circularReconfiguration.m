%% Add in assembler at 338

%  global FDrag
% FDrag(timeVar) = sum(Faero(1:6:end)) ;
% #md Reconfiguration problem validation (Drag reduction of flexible plates by reconfiguration, Gosselin, etAl 2010)
%----------------------------
close all, clear all ;
% add path
addpath( genpath( [ pwd '/../../src'] ) ); tic;
% General  problem parameters
%----------------------------
% according to the given parameters we obtain:
l = 1 ; d = l/100;%10 ; 
J = pi * d ^ 4 / 64 ; Iyy = J / 2 ; Izz = J / 2 ;  
E = 3e7 ;  nu = 0.3 ; rho = 700 ; G = E / (2 * (1+nu)) ; B = E*Izz; % I added
% fluid properties
rhoF = 1020 ; nuA = 1.6e-5 ; 

vwindMax = 16

q = 1/2 * rhoF* vwindMax^2 ;
c_d = 1.2;
CYCD = c_d*q*(l^3)*d/(2*B)

%
numElements = 10 ;
%
% materials
%----------------------------
% Since the example contains only one material and co-rotational strain element so then `materials` struct is:
materials.hyperElasModel  = '1DrotEngStrain' ;
materials.hyperElasParams = [ E nu ]        ;
materials.density         = rho              ;
%
% elements
%----------------------------
% Two different types of elements are considered, node and beam. The nodes will be assigned in the first entry (index $1$) and the beam at the index $2$. The elemType field is then:
elements(1).elemType = 'node'  ;
elements(2).elemType = 'frame' ;
% for the geometries, the node has not geometry to assign (empty array), and the truss elements will be set as a circular section with $d$ diameter
elements(2).elemCrossSecParams{1,1} = 'circle' ;
elements(2).elemCrossSecParams{2,1} = [ d ] ;% number of Gauass integration points and elemTypeAero field:
% elements(2).elemCrossSecParams{1,1} = 'circle' ;
% elements(2).elemCrossSecParams{2,1} = [ d ] ;% number of Gauass integration points and elemTypeAero field:
numGaussPoints = 4 ;
computeAeroTangentMatrix = true ;
elements(2).elemTypeAero   = [0 d 0 numGaussPoints computeAeroTangentMatrix ] ;
% The drag function name is:
elements(2).aeroCoefs = {'dragCircular'; []; [] } ;
%
% boundaryConds
%----------------------------
% The elements are submitted to only one different BC settings. The first BC corresponds to a welded condition (all 6 dofs set to zero)
boundaryConds(1).imposDispDofs = [ 1 2 3 4 5 6 ] ;
boundaryConds(1).imposDispVals = [ 0 0 0 0 0 0 ] ;
%
% initial Conditions
%----------------------------
% any non homogeneous initial conditions is considered, then an empty struct is set:
initialConds = struct() ;
%
% analysisSettings Static
%----------------------------
analysisSettings.fluidProps = {rhoF; nuA; 'windVelCircStatic'} ;
%md The geometrical non-linear effects are not considered in this case to compute the aerodynamic force. As consequence the wind load forces are computed on the reference configuration, and remains constant during the beam deformation. The field  _geometricNonLinearAero_ into  `analysisSettings` struct is then set to:
analysisSettings.geometricNonLinearAero = true;
%md since this problem is static, then a N-R method is employed. The convergence of the method is accomplish with ten equal load steps. The time variable for static cases is a load factor parameter that must be configured into the `windVel.m` function. A linear profile is considered for ten equal velocity load steps as:
analysisSettings.deltaT        =   1             ; % needs to be 1
analysisSettings.finalTime     =   100            ;
analysisSettings.methodName    = 'newtonRaphson' ;
%md Next the maximum number of iterations per load(time) step, the residual force and the displacements tolerances are set to: 
analysisSettings.stopTolDeltau =   0             ;
analysisSettings.stopTolForces =   1e-8          ;
analysisSettings.stopTolIts    =   50            ;
%
% otherParams
%----------------------------
otherParams.problemName = 'staticReconfigurationCircle';
otherParams.plots_format = 'vtk' ;
%md
%
% meshParams
%----------------------------
%mdThe coordinates of the mesh nodes are given by the matrix:
half_coords = [ (0:(numElements))' * l / numElements  zeros(numElements+1,2) ];
% mesh.nodesCoords = [ flip(-half_coords);...
                    %  half_coords(2:end,:) ] ;
mesh.nodesCoords = [ half_coords ] ;
%mdThe connectivity is introduced using the _conecCell_. Each entry of the cell contains a vector with the four indexes of the MEBI parameters, followed by the indexes of nodes that compose the element (node connectivity). For didactical purposes each element entry is commented. First the cell is initialized:
mesh.conecCell = { } ;
%md then the first welded node is defined with material (M) zero since nodes don't have material, the first element (E) type (the first entry of the `elements` struct), and (B) is the first entry of the the `boundaryConds` struct. For (I) no non-homogeneous initial condition is considered (then zero is used) and finally the node is assigned:
% mesh.conecCell{ 1, 1 } = [ 0 1 1 0  floor(numElements/2) + 1] ;
mesh.conecCell{ 1, 1 } = [ 0 1 1 0  1] ;
%md Next the frame elements MEBI parameters are set. The frame material is the first material of `materials` struct, then $1$ is assigned. The second entry of the `elements` struct correspond to the frame element employed, so $2$ is set. Finally no BC and no IC is required for this element, then $0$ is used.  Consecutive nodes build the element so then the `mesh.conecCell` is:
% for i=1:2*numElements,
  % mesh.conecCell{ i+1,1 } = [ 1 2 0 0  i i+1 ] ;
% end
for i=1:numElements,
  mesh.conecCell{ i+1,1 } = [ 1 2 0 0  i i+1 ] ;
end
%md
%md### Declare a global variable to store drag 
%md
global FDrag
FDrag = zeros(analysisSettings.finalTime, 1) ;
%md
%md### Run ONSAS 
%md
[matUsCase, loads, cellFint] = ONSAS( materials, elements, boundaryConds, initialConds, mesh, analysisSettings, otherParams ) ;
%md 
%md## Verification
%md---------------------
numLoadSteps = size(matUsCase, 2)
timeVec = linspace(0,analysisSettings.finalTime, numLoadSteps) ;
Cy = zeros(numLoadSteps-1, 1) ;
R  = zeros(numLoadSteps-1, 1) ;
C_d = feval( elements(2).aeroCoefs{1}, 0 , 0) ;
for windVelStep = 1:numLoadSteps - 1
    % Compute dimensionless magnitudes 
    windVel         = feval( analysisSettings.fluidProps{3,:}, 0, timeVec(windVelStep + 1 ) ) ;
    normWindVel     = norm( windVel )                                                         ;
    dirWindVel      = windVel / normWindVel                                                   ;
    Cy(windVelStep) =  1/2 * rhoF * normWindVel^2 * (l)^3 *d / (2 * B)                              ;

    % numeric drag 
    FDragi = FDrag(windVelStep) ;
    FDRef  = 1/2 * rhoF * normWindVel^2 * C_d * d * l    ;
    R(windVelStep) =  abs(FDragi)/(FDRef )               ;

end
%md Extract the Gosselin Results
resudrag = csvread('F_Gosselin2010.cvs');

%md The plot parameters are:
lw = 4 ; ms = 5 ;
axislw = 1 ; axisFontSize = 20 ; legendFontSize = 15 ; curveFontSize = 15 ;    
folderPathFigs = './output/figs/' ;
mkdir(folderPathFigs) ;
%md The R vs Cy* is: 
fig1 = figure(1) ;
hold on
loglog(C_d*Cy, R  , 'b-o' , 'linewidth', lw, 'markersize', ms   );
loglog(resudrag(:,1), resudrag(:,2)  , 'k-' , 'linewidth', lw, 'markersize', ms   );
legend('ONSAS', 'Gosselin')
labx=xlabel(' Cy* ');    laby=ylabel('R');
set(legend, 'linewidth', axislw, 'fontsize', legendFontSize, 'location','northEast' ) ;
set(gca, 'linewidth', axislw, 'fontsize', curveFontSize ) ;
set(labx, 'FontSize', axisFontSize); set(laby, 'FontSize', axisFontSize) ;
grid on
namefig1 = strcat(folderPathFigs, 'CyR.png') ;

