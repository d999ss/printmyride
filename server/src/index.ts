import express from 'express';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import dotenv from 'dotenv';
import authRoutes from './routes/auth.js';
import apiRoutes from './routes/api.js';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors({
    origin: [
        process.env.APP_BASE_URL || 'http://localhost:3000',
        'http://localhost:3000', // Dev frontend
        'https://printmyride.app', // Production
    ],
    credentials: true
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});

// Routes
app.use('/auth', authRoutes);
app.use('/api', apiRoutes);

// Error handler
app.use((error: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
    console.error('❌ Unhandled error:', error);
    
    if (res.headersSent) {
        return next(error);
    }
    
    res.status(error.status || 500).json({
        error: process.env.NODE_ENV === 'production' 
            ? 'Internal server error' 
            : error.message || 'Something went wrong'
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({ error: 'Route not found' });
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('🔄 SIGTERM received, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('🔄 SIGINT received, shutting down gracefully');
    process.exit(0);
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 PrintMyRide server running on port ${PORT}`);
    console.log(`📧 App base URL: ${process.env.APP_BASE_URL}`);
    console.log(`🔗 Server base URL: ${process.env.SERVER_BASE_URL}`);
    console.log(`🔐 Strava client ID: ${process.env.STRAVA_CLIENT_ID ? 'configured' : 'MISSING'}`);
    console.log(`🗄️  Database: SQLite - ${process.env.DATABASE_PATH || './printmyride.db'}`);
});

export default app;