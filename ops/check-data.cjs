const fs=require('node:fs');
const {createRequire}=require('node:module');
const fail=m=>{console.error(m);process.exit(1)};
const file='/data/server-files/account.sqlite';
const bootstrap=process.env.BOOTSTRAP_MODE==='true';
if(!fs.existsSync(file)){
 if(bootstrap&&fs.readdirSync('/data').length===0){console.log('Datastore vacio: inicializacion nativa privada.');process.exit(0)}
 fail('Falta account.sqlite: realizar setup privado o revisar datastore parcial; no se sobreescribe.');
}
const Database=createRequire('/app/package.json')('better-sqlite3');
let db;
try{
 db=new Database(file,{readonly:true,fileMustExist:true});
 if(db.pragma('quick_check',{simple:true})!=='ok')fail('SQLite no pasa quick_check');
 const tables=db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name IN ('auth','files','users')").all();
 if(tables.length!==3)fail('Datastore incompleto o ajeno: revisar antes de migrar');
 if(bootstrap){console.log('Bootstrap privado: continuar setup nativo.');process.exit(0)}
 const row=db.prepare("SELECT active, extra_data FROM auth WHERE method='password'").get();
 if(!row||row.active!==1||typeof row.extra_data!=='string'||row.extra_data.length<40||!/^\$(argon2(?:id|i|d)\$|2[aby]\$)/.test(row.extra_data))fail('Configurar password nativo en bootstrap antes de publicar');
 const owner=db.prepare("SELECT id FROM users WHERE enabled=1 AND owner=1 AND role='ADMIN' AND user_name='' LIMIT 1").get();
 if(!owner)fail('Completar primer login nativo antes de publicar');
 console.log('Datastore y metodo password comprobados; inicio nativo.');
}catch(err){fail('No se pudo comprobar SQLite/esquema; revisar version, permisos o restauracion antes de arrancar')}
finally{if(db)db.close()}
