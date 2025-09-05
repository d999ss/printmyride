import sqlite3 from 'sqlite3';
import { open, Database } from 'sqlite';
import path from 'path';

let db: Database<sqlite3.Database, sqlite3.Statement> | null = null;

export async function getDatabase(): Promise<Database<sqlite3.Database, sqlite3.Statement>> {
    if (!db) {
        const dbPath = process.env.DATABASE_PATH || path.join(process.cwd(), 'printmyride.db');
        
        db = await open({
            filename: dbPath,
            driver: sqlite3.Database
        });
        
        // Enable foreign keys
        await db.exec('PRAGMA foreign_keys = ON');
        
        console.log(`✅ SQLite database connected: ${dbPath}`);
    }
    
    return db;
}

export async function withTransaction<T>(
    callback: (db: Database<sqlite3.Database, sqlite3.Statement>) => Promise<T>
): Promise<T> {
    const database = await getDatabase();
    
    try {
        await database.exec('BEGIN TRANSACTION');
        const result = await callback(database);
        await database.exec('COMMIT');
        return result;
    } catch (error) {
        await database.exec('ROLLBACK');
        throw error;
    }
}

// Helper for running migrations
export async function runMigration(sql: string): Promise<void> {
    const database = await getDatabase();
    try {
        await database.exec(sql);
        console.log('✅ Migration completed successfully');
    } catch (error) {
        console.error('❌ Migration failed:', error);
        throw error;
    }
}

// Query helper that mimics pg interface
export const query = async (sql: string, params: any[] = []) => {
    const database = await getDatabase();
    
    if (sql.trim().toUpperCase().startsWith('SELECT')) {
        const rows = await database.all(sql, params);
        return { rows };
    } else {
        const result = await database.run(sql, params);
        return { 
            rows: [],
            rowCount: result.changes || 0,
            insertId: result.lastID
        };
    }
};

export default { query };