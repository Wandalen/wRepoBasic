( function _Repo_s_()
{

'use strict';

const _ = _global_.wTools;
_.repo = _.repo || Object.create( null );
_.repo.provider = _.repo.provider || Object.create( null );

// --
// meta
// --

function _request_functor( fo )
{

  _.routine.options( _request_functor, fo );
  _.assert( _.strDefined( fo.description ) );
  _.assert( _.aux.is( fo.act ) );
  _.assert( _.strDefined( fo.act.name ) );

  const description = fo.description;
  const actName = fo.act.name;

  request_body.defaults =
  {
    logger : 0,
    throwing : 1,
    originalRemotePath : null,
    ... fo.act.defaults,
  }

  const request = _.routine.unite( request_head, request_body );
  return request;

  function request_head( routine, args )
  {
    let o = args[ 0 ];
    if( _.strIs( o ) )
    o = { remotePath : o };
    _.routine.options( request, o );
    _.assert( args.length === 1 );
    return o;
  }

  function request_body( o )
  {
    let ready = _.take( null );
    let path = _.git.path;

    _.map.assertHasAll( o, request.defaults );
    o.logger = _.logger.maybe( o.logger );

    o.originalRemotePath = o.originalRemotePath || o.remotePath;
    if( _.strIs( o.remotePath ) )
    o.remotePath = path.parse({ remotePath : o.remotePath, full : 0, atomic : 0, objects : 1 });

    ready
    .then( () =>
    {
      let provider = _.repo.providerForPath({ remotePath : o.remotePath, throwing : o.throwing });
      if( provider && !_.routineIs( provider[ actName ] ) )
      throw _.err( `Repo provider ${provider.name} does not support routine ${actName}` );
      return provider[ actName ]( o );
    })
    .then( ( op ) =>
    {
      if( !_.map.is( op ) )
      throw _.err( `Routine ${actName} should return options map. Got:${op}` );

      if( op.result === undefined )
      throw _.err( `Options map returned by routine ${actName} should have {result} field. Got:${op}` );

      return o;
    })
    .catch( ( err ) =>
    {
      if( o.throwing )
      throw _.err( err, `\nFailed to ${description} for ${path.str( o.originalRemotePath )}` );
      _.errAttend( err );
      return null;
    })

    if( o.sync )
    {
      ready.deasync();
      return ready.sync();
    }

    return ready;
  }

}

_request_functor.defaults =
{
  description : null,
  act : null,
}

//

function _collectionExportString_functor( fo )
{

  _.routine.options( _collectionExportString_functor, fo );
  _.assert( arguments.length === 1 );
  _.assert( _.routine.is( fo.elementExportRoutine ) );
  _.assert( _.routine.is( fo.elementExportRoutine.body ) );
  _.assert( _.aux.is( fo.elementExportRoutine.defaults ) );
  _.assert( _.routine.is( fo.formatHeadRoutine ) || _.strDefined( fo.elementsString ) );
  _.assert( _.routine.is( fo.formatHeadRoutine ) || fo.formatHeadRoutine === null );

  const elementsString = fo.elementsString;
  const elementExportRoutine = fo.elementExportRoutine;
  const formatHeadRoutine = fo.formatHeadRoutine ? fo.formatHeadRoutine : formatHeadRoutineDefault;

  elementArrayExportString_body.defaults =
  {
    ... fo.elementExportRoutine.defaults,
    withHead : 1,
    verbosity : 2,
  }

  elementArrayExportString_body.itDefaults =
  {
    tab : '',
    dtab : '  ',
  }

  const elementArrayExportString = _.routine.unite( elementArrayExportString_head, elementArrayExportString_body );
  return elementArrayExportString;

  function elementArrayExportString_head( routine, args )
  {
    _.assert( 1 <= args.length && args.length <= 2 );
    let o = args[ 1 ];
    _.routine.options( routine, o );
    o.it = o.it || _.props.extend( null, routine.itDefaults );
    return _.unroll.from([ args[ 0 ], o ]);
  }

  function elementArrayExportString_body( object, o )
  {

    o.verbosity = _.logger.verbosityFrom( o.verbosity );

    if( o.verbosity <= 0 )
    return '';

    if( o.verbosity === 1 )
    {
      if( !object.elements.length )
      return ``;
      return formatHeadRoutine( object, o );
    }

    let result = '';
    object.elements.forEach( ( element ) =>
    {
      if( result.length )
      result += '\n';
      /* xxx : use _.stringer.verbosityUp() */
      result += o.it.tab + o.it.dtab + elementExportRoutine.body.call( _.repo, element, o );
    });

    if( result.length && o.withHead )
    result = `${formatHeadRoutine( object, o )}\n${result}`;

    return result;

  }

  function formatHeadRoutineDefault( object, o )
  {
    let prefix = _.ct.format( elementsString, o.secondaryStyle );
    return `${o.it.tab}${object.elements.length} ${prefix}`;
  }

}

_collectionExportString_functor.defaults =
{
  elementExportRoutine : null,
  formatHeadRoutine : null,
  elementsString : null
}

// --
// provider
// --

function providerForPath( o )
{
  if( _.strIs( o ) )
  o = { remotePath : o };

  _.assert( arguments.length === 1 );
  _.routine.options( providerForPath, o );

  let parsed;
  o.originalRemotePath = o.originalRemotePath || o.remotePath;

  let providerKey = providerGetService( o.originalRemotePath );

  let provider = _.repo.provider[ providerKey ];

  if( !provider )
  {
    if( providerKey )
    {
      provider = _.repo.provider.git;
    }
    else
    {
      providerKey = providerGetProtocol();
      provider = _.repo.provider[ providerKey ];
    }

    if( !provider )
    throw _.err( `No repo provider for path::${ o.originalRemotePath }` );
  }

  return provider;

  /* */

  function providerGetService( remotePath )
  {
    if( _.strIs( o.remotePath ) )
    parsed = o.remotePath = _.git.path.parse({ remotePath, full : 1, atomic : 0, objects : 1 });
    else
    parsed = o.remotePath;

    if( parsed.service )
    {
      _.assert( _.map.assertHasAll( parsed, { user : null, repo : null } ) );
      _.assert( parsed.protocols === undefined || parsed.protocols.length <= 1 || parsed.protocols[ 0 ] === 'git' );
      return parsed.service;
    }
  }

  /* */

  function providerGetProtocol()
  {
    if( !parsed.protocol )
    return _.fileSystem.defaultProtocol;
    return parsed.protocol;
  }
}

// function providerForPath( o )
// {
//   _.routine.options( providerForPath, o );
//   o.originalRemotePath = o.originalRemotePath || o.remotePath;
//   if( _.strIs( o.remotePath ) )
//   o.remotePath = _.git.path.parse({ remotePath : o.remotePath, full : 0, atomic : 0, objects : 1 });
//   let provider = _.repo.provider[ o.remotePath.service ];
//   if( !provider )
//   throw _.err( `No repo provider for service::${o.remotePath.service}` );
//   return provider;
// }

providerForPath.defaults =
{
  originalRemotePath : null,
  remotePath : null,
  throwing : 0,
};

//

function providerAmend( o )
{
  _.routine.options( providerAmend, o );
  _.assert( _.mapIs( o.src ) );
  _.assert( _.strIs( o.src.name ) || _.strsAreAll( o.src.names ) );

  if( !o.src.name )
  o.src.name = o.src.names[ 0 ];
  if( !o.src.names )
  o.src.names = [ o.src.name ];

  _.assert( _.strIs( o.src.name ) );
  _.assert( _.strsAreAll( o.src.names ) );

  let was;
  o.src.names.forEach( ( name ) =>
  {
    _.assert( _.repo.provider[ name ] === was || _.repo.provider[ name ] === undefined );
    was = was || _.repo.provider[ name ];
  });

  o.src.names.forEach( ( name ) =>
  {
    let dst = _.repo.provider[ name ];
    if( !dst )
    dst = _.repo.provider[ name ] = Object.create( null );
    let name2 = dst.name || o.src.name;
    _.props.extend( dst, o.src );
    dst.name = name2;
  });

}

providerAmend.defaults =
{
  src : null,
}

//

const repositoryIssuesGetAct = Object.create( null );

repositoryIssuesGetAct.name = 'repositoryIssuesGetAct';
repositoryIssuesGetAct.defaults =
{
  token : null,
  remotePath : null,
  state : null,
};

//

function issuesGet( o )
{
  _.routine.options( issuesGet, o );
  _.assert( _.str.is( o.remotePath ) || _.aux.is( o.remotePath ) );

  o.state = o.state || 'all';
  o.remotePath = _.git.path.normalize( o.remotePath );
  const parsed = _.git.path.parse({ remotePath : o.remotePath, full : 0, atomic : 0, objects : 1 });

  const provider = _.repo.providerForPath({ remotePath : o.remotePath });
  const o2 = _.props.extend( null, o );
  o2.remotePath = parsed;

  const ready = provider.repositoryIssuesGetAct( o2 );
  ready.finally( ( err, arg ) =>
  {
    if( err )
    throw _.err( `Error code : ${ err.status }. ${ err.message }` );
    return arg || null;
  });

  if( o.sync )
  {
    ready.deasync();
    return ready.sync();
  }

  return ready;
}

issuesGet.defaults =
{
  ... repositoryIssuesGetAct.defaults,
  sync : 0,
};

//

const repositoryIssuesCreateAct = Object.create( null );

repositoryIssuesCreateAct.name = 'repositoryIssuesCreateAct';
repositoryIssuesCreateAct.defaults =
{
  token : null,
  remotePath : null,
  issues : null,
};

//

function issuesCreate( o )
{
  let localProvider = _.fileProvider;
  let path = localProvider.path;
  _.routine.options( issuesCreate, o );
  _.assert( _.str.is( o.remotePath ) || _.aux.is( o.remotePath ) );
  _.assert( _.str.defined( o.token ), 'Expects token {-o.token-}' );

  if( _.str.is( o.issues ) )
  o.issues = localProvider.fileReadUnknown( path.join( path.current(), o.issues ) );
  _.assert( _.array.is( o.issues ) || _.aux.is( o.issues ) );

  o.remotePath = _.git.path.normalize( o.remotePath );
  const parsed = _.git.path.parse({ remotePath : o.remotePath, full : 0, atomic : 0, objects : 1 });

  const provider = _.repo.providerForPath({ remotePath : o.remotePath });
  const o2 = _.props.extend( null, o );
  o2.remotePath = parsed;

  const ready = provider.repositoryIssuesCreateAct( o2 );
  ready.finally( ( err, arg ) =>
  {
    if( err )
    throw _.err( `Error code : ${ err.status }. ${ err.message }` );
    return arg || null;
  });

  if( o.sync )
  {
    ready.deasync();
    return ready.sync();
  }

  return ready;
}

issuesCreate.defaults =
{
  ... repositoryIssuesCreateAct.defaults,
  sync : 0,
};

// --
// pr
// --

function pullIs( element )
{
  if( !_.object.isBasic( element ) )
  return false;
  return element.type === 'repo.pull';
}

//

function pullExportString_body( element, o )
{

  _.assert( _.repo.pullIs( element ) );
  o.verbosity = _.logger.verbosityFrom( o.verbosity );

  if( o.verbosity <= 0 )
  return '';

  let id = `pr#${element.id}`;
  let fromUser = _.ct.format( 'from_user::', o.secondaryStyle ) + element.from.name;
  let fromBranch = _.ct.format( 'from_branch::', o.secondaryStyle ) + element.from.tag;
  let to = _.ct.format( 'to::', o.secondaryStyle ) + element.to.tag;
  let description = _.ct.format( 'description::', o.secondaryStyle ) + element.description.head;
  let result = `${ id } ${ fromUser } ${ fromBranch } ${ to } ${ description }`;

  return result;
}

pullExportString_body.defaults =
{
  secondaryStyle : 'tertiary',
  verbosity : 1,
  it : null,
};

let pullExportString = _.routine.unite( 1, pullExportString_body );

//

let pullCollectionExportString = _collectionExportString_functor
({
  elementExportRoutine : pullExportString,
  elementsString : 'program(s)',
});

//

let pullListAct = Object.create( null );
pullListAct.name = 'pullListAct';
pullListAct.defaults =
{
  token : null,
  remotePath : null,
  sync : 1,
  withOpened : 1,
  withClosed : 0,
};

//

let pullList = _request_functor
({
  description : 'get list of pull requests',
  act : pullListAct,
});

//

let pullOpenAct = Object.create( null );

pullOpenAct.name = 'pullOpenAct';
pullOpenAct.defaults =
{
  token : null,
  remotePath : null,
  descriptionHead : null,
  descriptionBody : null,
  srcBranch : null,
  dstBranch : null,
  logger : null,
};

//

function pullOpen( o )
{
  _.assert( arguments.length === 1 );
  _.routine.options( pullOpen, o );
  _.sure( _.str.defined( o.token ), 'Expects token {-o.token-}.' );
  _.assert( _.str.defined( o.remotePath ) );
  _.assert( _.str.is( o.srcBranch ) || _.str.is( o.dstBranch ), 'Expects either {-o.srcBranch-} or {-o.dstBranch-}.' );

  o.logger = _.logger.maybe( o.logger );

  if( o.srcBranch === null )
  o.srcBranch = currentBranchGet();
  if( o.dstBranch === null )
  o.dstBranch = currentBranchGet();

  const parsed = _.git.path.parse({ remotePath : o.remotePath, full : 1, atomic : 0 });

  const provider = _.repo.providerForPath({ remotePath : o.remotePath });
  const o2 = _.props.extend( null, o );
  o2.remotePath = parsed;

  const ready = provider.pullOpenAct( o2 );
  ready.finally( ( err, pr ) =>
  {
    if( err )
    {
      _.errAttend( err );
      if( o.throwing )
      throw _.err( err, '\nFailed to open pull request' );
    }
    return pr || false;
  });

  if( o.sync )
  {
    ready.deasync();
    return ready.sync();
  }

  return ready;

  /* */

  function currentBranchGet()
  {
    _.assert( _.strDefined( o.localPath ), 'Expects local path {-o.localPath-}' );

    let tag = _.git.tagLocalRetrive
    ({
      localPath : o.localPath,
      detailing : 1,
    });

    if( tag.isBranch )
    return tag.tag;
    else
    return 'master';
  }

  // /* aaa : for Dmytro : move out to github provider */ /* Dmytro : moved to provider */
  // function pullOpenOnGithub()
  // {
  //   let ready = _.take( null );
  //   ready
  //   .then( () =>
  //   {
  //     let github = require( 'octonode' );
  //     let client = github.client( o.token );
  //     let repo = client.repo( `${ parsed.user }/${ parsed.repo }` );
  //     let o2 =
  //     {
  //       descriptionHead : o.descriptionHead,
  //       descriptionBody : o.descriptionBody,
  //       head : o.srcBranch,
  //       base : o.dstBranch,
  //     };
  //     repo.pr( o2, onRequest );
  //
  //     /* */
  //
  //     return ready2
  //     .then( ( args ) =>
  //     {
  //       if( args[ 0 ] )
  //       throw _.err( `Error code : ${ args[ 0 ].statusCode }. ${ args[ 0 ].message }` ); /* Dmytro : the structure of HTTP error is : message, statusCode, headers, body */
  //
  //       if( o.logger && o.logger.verbosity >= 3 )
  //       o.logger.log( args[ 1 ] );
  //       else if( o.logger && o.logger.verbosity >= 1 )
  //       o.logger.log( `Succefully created pull request "${ o.descriptionHead }" in ${ o.remotePath }.` )
  //
  //       return args[ 1 ];
  //     });
  //   });
  //   return ready;
  // }
  //
  // /* aaa : for Dmytro : ?? */ /* Dmytro : really strange code */
  // function onRequest( err, body, headers )
  // {
  //   return _.time.begin( 0, () => ready2.take([ err, body ]) );
  // }

}

pullOpen.defaults =
{
  throwing : 1,
  sync : 1,
  logger : 2,
  token : null,
  remotePath : null,
  localPath : null,
  // title : null, /* aaa : for Dmytro : rename to descriptionHead */
  // body : null, /* aaa : for Dmytro : rename to descriptionBody */
  descriptionHead : null,
  descriptionBody : null,
  srcBranch : null, /* aaa : for Dmytro : should get current by default */ /* Dmytro : implemented and covered */
  dstBranch : null, /* aaa : for Dmytro : should get current by default */ /* Dmytro : implemented and covered */
};

// --
// release
// --

let releaseMakeAct = Object.create( null );

releaseMakeAct.name = 'releaseMakeAct';
releaseMakeAct.defaults =
{
  name : null,
  token : null,
  remotePath : null,
  descriptionBody : null,
  draft : null,
  prerelease : null,
  logger : null,
};

//

function releaseMake( o )
{
  _.assert( arguments.length === 1 );
  _.routine.options( releaseMake, o );
  _.sure( _.str.defined( o.token ), 'Expects token {-o.token-}.' );
  _.assert( _.str.defined( o.remotePath ) );

  const ready = _.take( null );
  const parsed = _.git.path.parse({ remotePath : o.remotePath, full : 1, atomic : 0 });

  if( o.force )
  {
    let o2 = _.mapOnly_( null, o, _.repo.releaseDelete.defaults );
    o2.throwing = 0;
    ready.then( () => _.repo.releaseDelete( o2 ) );
  };

  ready.then( () =>
  {
    const provider = _.repo.providerForPath({ remotePath : o.remotePath });
    let o2 = _.props.extend( null, o );
    o2.remotePath = parsed;
    return provider.releaseMakeAct( o2 );
  });
  ready.finally( ( err, arg ) =>
  {
    if( err )
    {
      _.errAttend( err );
      if( o.throwing )
      throw _.err( err, '\nFailed to create release.' );
    }
    return arg || false;
  });

  if( o.sync )
  {
    ready.deasync();
    return ready.sync();
  }

  return ready;
}

releaseMake.defaults =
{
  ... releaseMakeAct.defaults,
  localPath : null,
  throwing : 1,
  force : 0,
  sync : 1,
  logger : 2,
};

//

let releaseDeleteAct = Object.create( null );

releaseDeleteAct.name = 'releaseDeleteAct';
releaseDeleteAct.defaults =
{
  token : null,
  remotePath : null,
  logger : null,
};

//

function releaseDelete( o )
{
  _.assert( arguments.length === 1 );
  _.routine.options( releaseDelete, o );
  _.sure( _.str.defined( o.token ), 'Expects token {-o.token-}.' );
  _.assert( _.str.defined( o.remotePath ) );
  _.assert( _.str.defined( o.localPath ), 'Expects local path {-o.localPath-}.' );

  const parsed = _.git.path.parse({ remotePath : o.remotePath, full : 1, atomic : 0 });
  const provider = _.repo.providerForPath({ remotePath : o.remotePath });
  const o2 = _.props.extend( null, o );
  o2.remotePath = parsed;

  const ready = provider.releaseDeleteAct( o2 );
  ready.then( ( arg ) =>
  {
    _.git.tagDeleteTag
    ({
      localPath : o.localPath,
      tag : parsed.tag,
      remote : o.force,
      local : 1,
      throwing : 0,
      sync : 1,
    });
    return arg;
  })
  .finally( ( err, arg ) =>
  {
    if( err )
    {
      _.errAttend( err );
      if( o.throwing )
      throw _.err( err, '\nFailed to delete release.' );
    }
    return arg || false;
  });

  if( o.sync )
  {
    ready.deasync();
    return ready.sync();
  }

  return ready;
}

releaseDelete.defaults =
{
  ... releaseDeleteAct.defaults,
  localPath : null,
  force : 0,
  throwing : 1,
  sync : 1,
  logger : 2,
};

// --
// repository
// --

const repositoryInitAct = Object.create( null );

repositoryInitAct.name = 'repositoryInitAct';
repositoryInitAct.defaults =
{
  token : null,
  remotePath : null,
  description : null,
};

//

function repositoryInit( o )
{
  _.routine.options_( repositoryInit, o );
  _.assert( _.str.is( o.remotePath ) || _.aux.is( o.remotePath ) );
  _.sure( _.str.defined( o.token ), 'An access token is required to create a repository.' );

  /* */

  o.remotePath = _.git.path.normalize( o.remotePath );
  const parsed = _.git.path.parse({ remotePath : o.remotePath, full : 0, atomic : 0, objects : 1 });

  const provider = _.repo.providerForPath({ remotePath : o.remotePath });
  const o2 = _.props.extend( null, o );
  o2.remotePath = parsed;

  const ready = provider.repositoryInitAct( o2 );
  ready.finally( ( err, arg ) =>
  {
    if( err )
    {
      _.error.attend( err );
      if( o.throwing )
      throw _.err( `Error code : ${ err.status }. ${ err.message }` );
    }
    return arg || false;
  });

  if( o.sync )
  {
    ready.deasync();
    return ready.sync();
  }

  return ready;
}

repositoryInit.defaults =
{
  ... repositoryInitAct.defaults,
  throwing : 1,
  sync : 0,
};

//

const repositoryDeleteAct = Object.create( null );

repositoryDeleteAct.name = 'repositoryDeleteAct';
repositoryDeleteAct.defaults =
{
  token : null,
  remotePath : null,
};

//

function repositoryDelete( o )
{
  _.routine.options_( repositoryDelete, o );
  _.assert( _.str.is( o.remotePath ) || _.aux.is( o.remotePath ) );
  _.sure( _.str.defined( o.token ), 'An access token is required to delete the repository.' );

  /* */

  o.remotePath = _.git.path.normalize( o.remotePath );
  const parsed = _.git.path.parse({ remotePath : o.remotePath, full : 0, atomic : 0, objects : 1 });

  const provider = _.repo.providerForPath({ remotePath : o.remotePath });
  if( !provider.repositoryDeleteAct )
  throw _.err( `Can't remove remote repository, because the API is not implemented for provider ${ provider }.` );

  const o2 = _.props.extend( null, o );
  o2.remotePath = parsed;
  const ready = provider.repositoryDeleteAct( o2 );
  ready.finally( ( err, arg ) =>
  {
    if( err )
    {
      _.error.attend( err );
      if( o.throwing )
      throw _.err( `Error code : ${ err.status }. ${ err.message }` );
    }
    return arg || false;
  });

  if( o.sync )
  {
    ready.deasync();
    return ready.sync();
  }

  return ready;
}

repositoryDelete.defaults =
{
  ... repositoryDeleteAct.defaults,
  throwing : 1,
  sync : 0,
};

// --
// program
// --

function programIs( object )
{
  if( !_.object.isBasic( object ) )
  return false;
  return object.type === 'repo.program';
}

//

function programExportString_body( element, o )
{

  _.assert( _.repo.programIs( element ) );
  o.verbosity = _.logger.verbosityFrom( o.verbosity );

  if( o.verbosity <= 0 )
  return '';

  let name = _.ct.format( `name::`, o.secondaryStyle ) + element.name;
  let id = `program#${element.id}`;
  let state = _.ct.format( `state::`, o.secondaryStyle ) + element.state;
  let service = _.ct.format( `service::`, o.secondaryStyle ) + element.service;
  let result = `${id} ${name} ${state} ${service}`;

  return result;
}

programExportString_body.defaults =
{
  secondaryStyle : 'tertiary',
  verbosity : 1,
  it : null,
}

let programExportString = _.routine.unite( 1, programExportString_body );

//

let programCollectionExportString = _collectionExportString_functor
({
  elementExportRoutine : programExportString,
  elementsString : 'program(s)',
});

//

let programListAct = Object.create( null );
programListAct.name = 'programListAct';
programListAct.defaults =
{
  token : null,
  remotePath : null,
  sync : 1,
  withOpened : 1,
  withClosed : 0,
};

//

let programList = _request_functor
({
  description : 'get list of programs',
  act : programListAct,
});

// --
// etc
// --

function vcsFor( o )
{
  if( !_.map.is( o ) )
  o = { filePath : o };

  _.assert( arguments.length === 1 );
  _.routine.options( vcsFor, o );

  if( _.array.is( o.filePath ) && o.filePath.length === 0 )
  return null;

  if( !o.filePath )
  return null;

  _.assert( _.str.is( o.filePath ) );
  _.assert( _.git.path.isGlobal( o.filePath ) );

  let parsed = _.git.path.parse( o.filePath );

  if( _.git && _.git.protocols && _.longHas( _.git.protocols, parsed.protocol ) )
  return _.git;
  if( _.npm && _.npm.protocols && _.longHasAny( _.npm.protocols, parsed.protocol ) )
  return _.npm;
  if( _.http && _.http.protocols && _.longHasAny( _.http.protocols, parsed.protocol ) )
  return _.http;

  return null;
}

vcsFor.defaults =
{
  filePath : null,
};

// --
// declare
// --

let Extension =
{

  // meta

  _request_functor,
  _collectionExportString_functor,

  // provider

  providerForPath,
  providerAmend,

  // issue

  repositoryIssuesGetAct,
  issuesGet,
  repositoryIssuesCreateAct,
  issuesCreate,

  // pr

  pullIs,
  pullExportString,
  pullCollectionExportString,

  pullListAct,
  pullList, /* aaa : for Dmytro : cover */ /* Dmytro : covered */

  pullOpenAct, /* aaa : for Dmytro : add */ /* Dmytro : added */
  pullOpen,

  // release

  releaseMakeAct,
  releaseMake,
  releaseDeleteAct,
  releaseDelete,

  // repository

  repositoryInitAct,
  repositoryInit,
  repositoryDeleteAct,
  repositoryDelete,

  // program

  programIs,
  programExportString,
  programCollectionExportString,

  programListAct,
  programList,

  // etc

  vcsFor,

}

/* _.props.extend */Object.assign( _.repo, Extension );

//

if( typeof module !== 'undefined' )
module[ 'exports' ] = _global_.wTools;

})();

