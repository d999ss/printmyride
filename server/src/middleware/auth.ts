import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import db from '../database/sqlite-db.js';

// Extend Request to include user_id
declare global {
    namespace Express {
        interface Request {
            user_id?: number;
            athlete_id?: number;
        }
    }
}

export function requireSession(req: Request, res: Response, next: NextFunction) {
    const token = req.cookies.pmr_session;
    
    if (!token) {
        return res.status(401).json({ error: 'Authentication required' });
    }
    
    try {
        const payload = jwt.verify(token, process.env.JWT_SECRET!) as { user_id: number };
        req.user_id = payload.user_id;
        next();
    } catch (error) {
        return res.status(401).json({ error: 'Invalid session' });
    }
}

export async function getAthleteId(user_id: number): Promise<number | null> {
    const result = await db.query(
        'SELECT provider_user_id FROM user_identities WHERE user_id = $1 AND provider = $2',
        [user_id, 'strava']
    );
    
    return result.rows[0]?.provider_user_id || null;
}

export async function getAccessToken(athlete_id: number): Promise<string> {
    const result = await db.query(
        'SELECT access_token, refresh_token, expires_at FROM strava_tokens WHERE athlete_id = $1',
        [athlete_id]
    );
    
    if (!result.rows[0]) {
        throw new Error('No Strava tokens found for athlete');
    }
    
    const { access_token, refresh_token, expires_at } = result.rows[0];
    
    // Check if token expires within 60 seconds
    if (Date.now() / 1000 >= expires_at - 60) {
        console.log(`🔄 Refreshing token for athlete ${athlete_id}`);
        return await refreshToken(athlete_id, refresh_token);
    }
    
    return access_token;
}

async function refreshToken(athlete_id: number, refresh_token: string): Promise<string> {
    const response = await fetch('https://www.strava.com/oauth/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            client_id: process.env.STRAVA_CLIENT_ID,
            client_secret: process.env.STRAVA_CLIENT_SECRET,
            grant_type: 'refresh_token',
            refresh_token
        })
    });
    
    if (!response.ok) {
        const error = await response.text();
        console.error('❌ Token refresh failed:', error);
        throw new Error('Token refresh failed');
    }
    
    const tokens = await response.json();
    
    // Update tokens in database
    await db.query(
        `UPDATE strava_tokens 
         SET access_token = $1, refresh_token = $2, expires_at = $3, updated_at = NOW() 
         WHERE athlete_id = $4`,
        [tokens.access_token, tokens.refresh_token, tokens.expires_at, athlete_id]
    );
    
    console.log(`✅ Token refreshed for athlete ${athlete_id}`);
    return tokens.access_token;
}

// Rate limiting helper for Strava API
export function withRateLimit<T extends any[], R>(
    fn: (...args: T) => Promise<R>,
    maxRetries = 3
): (...args: T) => Promise<R> {
    return async (...args: T): Promise<R> => {
        let retries = 0;
        
        while (retries < maxRetries) {
            try {
                return await fn(...args);
            } catch (error: any) {
                if (error.status === 429 && retries < maxRetries - 1) {
                    const delay = Math.pow(2, retries) * 1000 + Math.random() * 1000;
                    console.log(`⏳ Rate limited, retrying in ${delay}ms...`);
                    await new Promise(resolve => setTimeout(resolve, delay));
                    retries++;
                } else {
                    throw error;
                }
            }
        }
        
        throw new Error('Max retries exceeded');
    };
}