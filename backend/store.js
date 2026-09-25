import mysql from 'mysql2/promise';
export const config={host:process.env.DB_HOST||'127.0.0.1',port:Number(process.env.DB_PORT||3306),user:process.env.DB_USER||'root',password:process.env.DB_PASSWORD||'',database:process.env.DB_NAME||'gaming_analyzer',timezone:'Z',dateStrings:true};
export const pool=mysql.createPool({...config,connectionLimit:8,decimalNumbers:true});
pool.on('connection',c=>c.query("SET time_zone = '+00:00'"));
export async function query(sql,args=[]){const [rows]=await pool.execute(sql,args);return rows;}
export async function transaction(fn){const c=await pool.getConnection();try{await c.beginTransaction();const result=await fn(async(s,a=[])=>{const [r]=await c.execute(s,a);return r;});await c.commit();return result;}catch(e){await c.rollback();throw e;}finally{c.release();}}
