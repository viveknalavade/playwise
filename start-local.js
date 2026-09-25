import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {config,pool} from './backend/store.js';
process.chdir(fileURLToPath(new URL('.',import.meta.url)));
function run(file,args){const result=spawnSync(file,args,{stdio:'inherit',windowsHide:true});if(result.error)throw result.error;if(result.status!==0)throw new Error(`${path.basename(file)} exited with code ${result.status}.`);}
try {
 run(process.execPath,['--env-file-if-exists=.env','database/setup.js']);
 const url=`http://127.0.0.1:${process.env.PORT||'5000'}`;
 let health;
 try{const response=await fetch(url+'/health',{signal:AbortSignal.timeout(1500)});if(response.ok)health=await response.json();}catch{}
 if(health){
  if(health.database!=='mysql'||health.connection?.host!==config.host||health.connection?.port!==config.port||health.connection?.name!==config.database)throw new Error('An app with different database settings is already running. Stop its terminal with Ctrl+C and run this launcher again.');
  console.log(`The dashboard is already running: ${url}/dashboard/`);
 }else run(process.execPath,['--env-file-if-exists=.env','backend/app.js']);
}catch(e){console.error(`Startup failed: ${e.message}`);process.exitCode=1;}
finally{await pool.end();}
