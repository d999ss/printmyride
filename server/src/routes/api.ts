import { Router } from 'express';
import archiver from 'archiver';
import db from '../database/sqlite-db.js';
import { requireSession, getAthleteId, getAccessToken, withRateLimit } from '../middleware/auth.js';
import { decodePolyline, generateGPX } from '../utils/polyline.js';

const router = Router();

// 1. Get user's activities (privacy-compliant: user sees only their own)
router.get('/activities', requireSession, async (req, res) => {
    try {
        const athleteId = await getAthleteId(req.user_id!);
        if (!athleteId) {
            return res.status(400).json({ error: 'Strava not connected' });
        }
        
        const { since, until, page = '1', per_page = '50' } = req.query;
        
        // First, try to get from cache
        let activities = await getCachedActivities(athleteId, {
            since: since as string,
            until: until as string,
            page: parseInt(page as string),
            per_page: parseInt(per_page as string)
        });
        
        // If cache is empty or stale, fetch from Strava
        if (activities.length === 0 || shouldRefreshCache(athleteId)) {
            activities = await fetchAndCacheActivities(athleteId, {
                since: since as string,
                until: until as string,
                page: parseInt(page as string),
                per_page: parseInt(per_page as string)
            });
        }
        
        // Return normalized format
        const normalized = activities.map(activity => ({
            id: activity.id,
            name: activity.name,
            start: activity.start_date,
            distance_m: activity.distance,
            moving_time_s: activity.moving_time,
            elapsed_time_s: activity.elapsed_time,
            elev_gain_m: activity.total_elevation_gain,
            polyline: activity.map?.summary_polyline,
            type: activity.type || activity.sport_type,
            is_private: activity.private
        }));
        
        res.json(normalized);
    } catch (error) {
        console.error('❌ Activities API error:', error);
        res.status(500).json({ error: 'Failed to fetch activities' });
    }
});

// 2. Export selected activities as GPX ZIP
router.get('/exports/gpx', requireSession, async (req, res) => {
    try {
        const athleteId = await getAthleteId(req.user_id!);
        if (!athleteId) {
            return res.status(400).json({ error: 'Strava not connected' });
        }
        
        const { ids } = req.query;
        if (!ids || typeof ids !== 'string') {
            return res.status(400).json({ error: 'Activity IDs required' });
        }
        
        const activityIds = ids.split(',').map(id => parseInt(id.trim())).filter(id => !isNaN(id));
        if (activityIds.length === 0) {
            return res.status(400).json({ error: 'Valid activity IDs required' });
        }
        
        if (activityIds.length > 50) {
            return res.status(400).json({ error: 'Maximum 50 activities per export' });
        }
        
        // Get activities and verify ownership
        const activities = await getActivitiesForExport(athleteId, activityIds);
        
        if (activities.length === 0) {
            return res.status(404).json({ error: 'No activities found or access denied' });
        }
        
        // Set response headers for ZIP download
        const filename = `strava_export_${new Date().toISOString().split('T')[0]}.zip`;
        res.setHeader('Content-Type', 'application/zip');
        res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
        
        // Create ZIP stream
        const archive = archiver('zip', { zlib: { level: 9 } });
        
        archive.on('error', (err) => {
            console.error('❌ Archive error:', err);
            if (!res.headersSent) {
                res.status(500).json({ error: 'Export failed' });
            }
        });
        
        archive.pipe(res);
        
        // Add GPX files to archive
        for (const activity of activities) {
            try {
                const gpx = await createGPXFromActivity(activity, athleteId);
                if (gpx) {
                    const filename = `${activity.start_date?.split('T')[0] || 'unknown'}_${activity.name?.replace(/[^a-zA-Z0-9-_]/g, '_') || activity.id}.gpx`;
                    archive.append(gpx, { name: filename });
                }
            } catch (error) {
                console.error(`❌ Failed to create GPX for activity ${activity.id}:`, error);
            }
        }
        
        await archive.finalize();
        console.log(`✅ Exported ${activities.length} activities for athlete ${athleteId}`);
        
    } catch (error) {
        console.error('❌ GPX export error:', error);
        if (!res.headersSent) {
            res.status(500).json({ error: 'Export failed' });
        }
    }
});

// 3. Deauthorize Strava connection
router.post('/strava/deauthorize', requireSession, async (req, res) => {
    try {
        const athleteId = await getAthleteId(req.user_id!);
        if (!athleteId) {
            return res.status(400).json({ error: 'Strava not connected' });
        }
        
        // Get access token for deauthorization
        const accessToken = await getAccessToken(athleteId);
        
        // Deauthorize with Strava
        const deauthResponse = await fetch('https://www.strava.com/oauth/deauthorize', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${accessToken}`
            }
        });
        
        if (!deauthResponse.ok) {
            console.error('❌ Strava deauthorize failed:', await deauthResponse.text());
        }
        
        // Remove from our database regardless of Strava response
        await db.query('DELETE FROM user_identities WHERE user_id = $1 AND provider = $2', [req.user_id, 'strava']);
        await db.query('DELETE FROM strava_activities WHERE athlete_id = $1', [athleteId]);
        await db.query('DELETE FROM strava_tokens WHERE athlete_id = $1', [athleteId]);
        
        console.log(`✅ Deauthorized athlete ${athleteId} for user ${req.user_id}`);
        res.json({ message: 'Strava disconnected successfully' });
        
    } catch (error) {
        console.error('❌ Deauthorize error:', error);
        res.status(500).json({ error: 'Failed to disconnect Strava' });
    }
});

// Helper functions

async function getCachedActivities(athleteId: number, params: any) {
    let query = 'SELECT payload FROM strava_activities WHERE athlete_id = $1';
    const values: any[] = [athleteId];
    let paramIndex = 2;
    
    if (params.since) {
        query += ` AND (payload->>'start_date')::timestamp >= $${paramIndex}`;
        values.push(new Date(params.since * 1000));
        paramIndex++;
    }
    
    if (params.until) {
        query += ` AND (payload->>'start_date')::timestamp <= $${paramIndex}`;
        values.push(new Date(params.until * 1000));
        paramIndex++;
    }
    
    query += ' ORDER BY (payload->>\'start_date\') DESC';
    
    if (params.per_page) {
        query += ` LIMIT $${paramIndex}`;
        values.push(params.per_page);
        paramIndex++;
        
        if (params.page > 1) {
            query += ` OFFSET $${paramIndex}`;
            values.push((params.page - 1) * params.per_page);
        }
    }
    
    const result = await db.query(query, values);
    return result.rows.map(row => row.payload);
}

const fetchAndCacheActivities = withRateLimit(async (athleteId: number, params: any) => {
    const accessToken = await getAccessToken(athleteId);
    
    let url = `https://www.strava.com/api/v3/athlete/activities?per_page=${params.per_page}&page=${params.page}`;
    
    if (params.since) {
        url += `&after=${params.since}`;
    }
    if (params.until) {
        url += `&before=${params.until}`;
    }
    
    const response = await fetch(url, {
        headers: { 'Authorization': `Bearer ${accessToken}` }
    });
    
    if (!response.ok) {
        throw { status: response.status, message: await response.text() };
    }
    
    const activities = await response.json();
    
    // Cache activities
    for (const activity of activities) {
        await db.query(
            `INSERT INTO strava_activities (id, athlete_id, payload) 
             VALUES ($1, $2, $3) 
             ON CONFLICT (id) DO UPDATE SET payload = $3, updated_at = NOW()`,
            [activity.id, athleteId, JSON.stringify(activity)]
        );
    }
    
    console.log(`✅ Cached ${activities.length} activities for athlete ${athleteId}`);
    return activities;
});

async function shouldRefreshCache(athleteId: number): Promise<boolean> {
    const result = await db.query(
        'SELECT MAX(updated_at) as last_update FROM strava_activities WHERE athlete_id = $1',
        [athleteId]
    );
    
    if (!result.rows[0]?.last_update) {
        return true; // No cache
    }
    
    const lastUpdate = new Date(result.rows[0].last_update);
    const hoursSinceUpdate = (Date.now() - lastUpdate.getTime()) / (1000 * 60 * 60);
    
    return hoursSinceUpdate > 1; // Refresh if older than 1 hour
}

async function getActivitiesForExport(athleteId: number, activityIds: number[]) {
    const result = await db.query(
        'SELECT payload FROM strava_activities WHERE athlete_id = $1 AND id = ANY($2)',
        [athleteId, activityIds]
    );
    
    const found = result.rows.map(row => row.payload);
    
    // If some activities are missing from cache, fetch them
    const foundIds = found.map(a => a.id);
    const missingIds = activityIds.filter(id => !foundIds.includes(id));
    
    if (missingIds.length > 0) {
        const fetchedActivities = await fetchMissingActivities(athleteId, missingIds);
        found.push(...fetchedActivities);
    }
    
    return found;
}

const fetchMissingActivities = withRateLimit(async (athleteId: number, activityIds: number[]) => {
    const accessToken = await getAccessToken(athleteId);
    const activities = [];
    
    for (const id of activityIds) {
        try {
            const response = await fetch(`https://www.strava.com/api/v3/activities/${id}`, {
                headers: { 'Authorization': `Bearer ${accessToken}` }
            });
            
            if (response.ok) {
                const activity = await response.json();
                
                // Verify ownership
                if (activity.athlete.id === athleteId) {
                    // Cache the activity
                    await db.query(
                        `INSERT INTO strava_activities (id, athlete_id, payload) 
                         VALUES ($1, $2, $3) 
                         ON CONFLICT (id) DO UPDATE SET payload = $3, updated_at = NOW()`,
                        [activity.id, athleteId, JSON.stringify(activity)]
                    );
                    
                    activities.push(activity);
                }
            }
        } catch (error) {
            console.error(`❌ Failed to fetch activity ${id}:`, error);
        }
    }
    
    return activities;
});

async function createGPXFromActivity(activity: any, athleteId: number): Promise<string | null> {
    try {
        // Use summary polyline if available
        if (activity.map?.summary_polyline) {
            const coordinates = decodePolyline(activity.map.summary_polyline);
            
            if (coordinates.length === 0) {
                console.log(`⚠️ No coordinates for activity ${activity.id}`);
                return null;
            }
            
            return generateGPX(coordinates, activity.name, {
                distance: activity.distance,
                movingTime: activity.moving_time,
                elevationGain: activity.total_elevation_gain,
                type: activity.type || activity.sport_type,
                startTime: activity.start_date
            });
        }
        
        console.log(`⚠️ No polyline data for activity ${activity.id}`);
        return null;
        
    } catch (error) {
        console.error(`❌ GPX creation failed for activity ${activity.id}:`, error);
        return null;
    }
}

export default router;