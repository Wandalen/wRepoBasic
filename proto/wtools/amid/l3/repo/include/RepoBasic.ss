( function _Base_s_()
{

'use strict';

/* GitTools */

if( typeof module !== 'undefined' )
{
  const _ = require( '../../../../../node_modules/Tools' );

  _.include( 'wFilesBasic' );
  _.include( 'wGitTools' );

  module[ 'exports' ] = _global_.wTools;
}

})();
