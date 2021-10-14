if( typeof 'module' !== undefined )
require( 'wrepobasic' );

let _ = wTools;

let localPath = _.path.join( __dirname, '..' );
var isRepository =  _.git.isRepository({ localPath });

console.log( `Current directory ${ localPath } is a Git repository : ${ isRepository }` );
