import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { runMigration } from '../database/sqlite-db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function migrate() {
    try {
        console.log('🔄 Running database migrations...');
        
        const schemaPath = path.join(__dirname, '../database/sqlite-schema.sql');
        const schema = fs.readFileSync(schemaPath, 'utf-8');
        
        await runMigration(schema);
        
        console.log('🎉 All migrations completed successfully!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Migration failed:', error);
        process.exit(1);
    }
}

// Run migration if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
    migrate();
}