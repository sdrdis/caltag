function export_caltag( imagefilepattern, datafile )
%EXPORT_CALTAG Run Caltag on set of images and write results to HDF5 file
%	EXPORT_CALTAG(imagefilepattern,datafile,destfile)
%   args:
%   - imagefilepattern (eg. 'frame_*.png')
%   - datafile (eg. 'pattern_14x9.mat')
%
% Contributed by Felix Heide, 3 Oct 2011
% Modified by Brad Atcheson, 25 Oct 2011

debug = false;
[srcPath, ~] = fileparts( imagefilepattern );
originalDir = pwd;
cd( srcPath );
srcPath = pwd;
cd( originalDir );
imagefiles = dir( imagefilepattern );
destfile = fullfile( srcPath, 'cameracalib.h5' );
if exist( destfile, 'file' )
    ok = input( ['Overwrite ',destfile,'? Y/N [Y]: '], 's' );
    if isempty( ok )
        ok = 'Y';
    end
    if upper( ok ) == 'Y'
        delete( destfile );
    else
        return;
    end
end
        

for i = 1:length(imagefiles)     

    name = fullfile( srcPath, imagefiles(i).name );
    I = imread( name );
    try
        I = rgb2gray( I );
    catch
        % pass
    end
    
    disp( ['Running CALTag on ', name] );
    [wPt, iPt] = caltag( I, datafile, debug );
    nPoints = size( iPt, 1 );
    disp( [' found ', num2str(nPoints), ' points'] );
    
    % add third dimension to wPt (assumption of planar rig)
    wPt(:,3) = 0;

    % convert to C-style coordinates
    % that is [col,row] with (0,0) being the centre of the top left pixel
    iPt = fliplr( iPt ) - 1;
    
    % until we learn otherwise, all points are good
    inliers = ones( nPoints, 1, 'uint8' );
    
    [~,basename,ext] = fileparts( name );
    group = ['/images/',basename,ext];
    
    if nPoints > 0
        dest = fullfile( group, 'imagePoints' );
        write_data( dest, iPt' );
        %h5create( destfile, dest, size(iPt'), 'DataType',class(iPt) );
        %h5write( destfile, dest, iPt' );
        dest = fullfile( group, 'worldPoints' );
        write_data( dest, wPt' );
        %h5create( destfile, dest, size(wPt') );
        %h5write( destfile, dest, wPt' );
        dest = fullfile( group, 'inlierPoints' );
        write_data( dest, inliers' );
        %h5create( destfile, dest, nPoints );
        %h5write( destfile, dest, inliers' );
    
        h5writeatt( destfile, group, 'width', int32(size(I,2)) );
        h5writeatt( destfile, group, 'height', int32(size(I,1)) );
    end
           
end

disp( 'Done' );


function write_data(dest, data)
    if isvector( data )
        s = length( data );
    else
        s = size( data );
    end
    h5create( destfile, dest, s, 'DataType',class(data) );
    h5write( destfile, dest, data );
end

end
