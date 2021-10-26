
if( typeof 'module' !== undefined )
require( 'wrepobasic' );

/* */

const _ = wTools;

const token = process.env.PRIVATE_WTOOLS_BOT_TOKEN;
if( !token )
{
  console.log( 'Please, export token "PRIVATE_WTOOLS_BOT_TOKEN" before sample run.' );
}

_.repo.issuesGet
({
  remotePath : 'https://github.com/Wandalen/wRepoBasic.git',
  state : 'open',
  token,
})
.then( ( issues ) =>
{
  console.log( `Repository has ${ issues.length } opened issues.` );
  return null;
});

