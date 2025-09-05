import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

console.log('Testing email configuration...');
console.log('SMTP_HOST:', process.env.SMTP_HOST);
console.log('SMTP_USER:', process.env.SMTP_USER);
console.log('SMTP_PASS:', process.env.SMTP_PASS ? '***' : 'undefined');

const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT),
    secure: false,
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
    },
    debug: true
});

async function testEmail() {
    try {
        console.log('Testing SMTP connection...');
        await transporter.verify();
        console.log('✅ SMTP connection successful!');
        
        console.log('Sending test email...');
        const info = await transporter.sendMail({
            from: 'noreply@printmyride.app',
            to: 'test@example.com',
            subject: 'Test Email from PrintMyRide',
            text: 'This is a test email',
            html: '<h1>Test Email</h1><p>This is a test email from PrintMyRide</p>'
        });
        
        console.log('✅ Email sent successfully!');
        console.log('📧 Preview URL: https://ethereal.email/message/' + info.messageId);
        
    } catch (error) {
        console.error('❌ Email test failed:', error);
    }
}

testEmail();