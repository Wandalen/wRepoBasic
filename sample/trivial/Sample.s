
if( typeof 'module' !== undefined )
require( 'wrepobasic' );

/* */

const _ = wTools;

_.repo.issuesGet
({
  remotePath : 'https://github.com/Wandalen/wRepoBasic.git',
  state : 'open',
})
.then( ( issues ) =>
{
  console.log( `Repository has ${ issues.length } opened issues.` );
  return null;
});

