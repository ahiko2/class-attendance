const { Client } = require('pg');

exports.handler = async (event) => {
    const client = new Client({
        connectionString: process.env.DATABASE_URL,
        ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
    });

    try {
        await client.connect();
        
        // Clean up expired QR tokens
        const result = await client.query(`
            UPDATE sessions 
            SET qr_token = NULL, qr_expires_at = NULL 
            WHERE qr_expires_at < NOW() AND qr_token IS NOT NULL
        `);
        
        console.log(`Cleaned up ${result.rowCount} expired QR tokens`);
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: `Successfully cleaned up ${result.rowCount} expired QR tokens`
            })
        };
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({
                error: 'Failed to cleanup expired sessions'
            })
        };
    } finally {
        await client.end();
    }
};
