import mysql from 'mysql2/promise';
import {readFile} from 'node:fs/promises';
import {config,pool} from '../backend/store.js';
const name=config.database;if(!/^[a-zA-Z0-9_]+$/.test(name))throw new Error('Invalid DB_NAME');
const c=await mysql.createConnection({...config,database:undefined,multipleStatements:true});
try{
 await c.query(`CREATE DATABASE IF NOT EXISTS \`${name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`);
 await c.query(`USE \`${name}\``);await c.query("SET time_zone='+00:00'");
 await c.query(await readFile(new URL('./schema.sql',import.meta.url),'utf8'));
 const [[{n}]]=await c.query('SELECT COUNT(*) n FROM PLAYERS');
 if(!n){await c.beginTransaction();try{
 await c.query("INSERT INTO PLAYERS(username) VALUES ('Alex'),('Jordan'),('New player')");
 await c.query("INSERT INTO GAMES(game_name,genre,color) VALUES ('Valorant','Tactical shooter','#b49cff'),('Minecraft','Sandbox','#74d8b0'),('Rocket League','Sports','#ffbd70'),('Stardew Valley','Simulation','#75baff')");
 await c.query("INSERT INTO PLATFORMS(platform_name) VALUES ('PC'),('PlayStation'),('Xbox'),('Mobile')");
 for(let p=1;p<=3;p++){for(let g=1;g<=4;g++)await c.query('INSERT INTO PLAYER_GAME_LIBRARY(player_id,game_id,platform_id) VALUES(?,?,1)',[p,g]);await c.query('INSERT INTO PLAYER_LIMITS VALUES(?,180,1080,3000)',[p]);await c.query('INSERT INTO LIMIT_HISTORY(player_id,daily_playtime_limit,weekly_playtime_limit,monthly_spending_limit) VALUES(?,180,1080,3000)',[p]);}
 const now=Date.now(),offset=330*60000,midnight=Date.parse(new Date(now+offset).toISOString().slice(0,10)+'T00:00:00Z')-offset;
 const sqlDate=v=>new Date(v).toISOString().slice(0,19).replace('T',' ');
 for(let p=1;p<=2;p++)for(let d=0;d<40;d++){if((d+p)%6===0)continue;const length=35+((d*37+p*19)%155),start=midnight-d*86400000+(d%7===0?23:17)*3600000,end=start+length*60000;if(end>=now)continue;await c.query('INSERT INTO PLAYER_SESSIONS(player_id,game_id,platform_id,session_start,session_end) VALUES(?,?,1,?,?)',[p,(d%4)+1,sqlDate(start),sqlDate(end)]);}
 // A short completed session today, always in the past.
 await c.query('INSERT INTO PLAYER_SESSIONS(player_id,game_id,platform_id,session_start,session_end) VALUES(1,1,1,?,?)',[sqlDate(now-55*60000),sqlDate(now-10*60000)]);
 for(let p=1;p<=2;p++)for(let i=0;i<6;i++)await c.query('INSERT INTO PURCHASES(player_id,game_id,amount,purchase_type,purchase_date,note) VALUES(?,?,?,?,?,?)',[p,i%4+1,[499,299,799,199,349,599][i],i%2?'Game':'In-game',sqlDate(now-(i*6+1)*86400000),'Sample purchase']);
 for(let g=1;g<=4;g++)for(const [title,points] of [['First steps',10],['Finding your rhythm',25],['Mastery unlocked',100]])await c.query('INSERT INTO ACHIEVEMENTS(game_id,title,points) VALUES(?,?,?)',[g,title,points]);
 await c.query('INSERT INTO PLAYER_ACHIEVEMENTS(player_id,achievement_id) VALUES(1,1),(1,4),(1,7),(1,2),(2,1)');
 await c.commit();}catch(e){await c.rollback();throw e;}}
 await c.query(await readFile(new URL('./views.sql',import.meta.url),'utf8'));
 console.log(`MySQL database ${name} ready. Sample profiles: Alex, Jordan, New player.`);
}finally{await c.end();await pool.end();}
