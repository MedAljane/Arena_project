const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env'), debug: true });
const nodemailer = require('nodemailer');

console.log("SMTP_USER:", process.env.SMTP_USERNAME);
console.log("SMTP_PASS:", process.env.SMTP_PASSWORD);

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.SMTP_USERNAME,
        pass: process.env.SMTP_PASSWORD
    }
});

// @ts-ignore
transporter.verify(function(error, success) {
    if (error) {
        console.error('Error connecting to SMTP server:', error);
    } else {
        console.log('Successfully connected to SMTP server');
    }
});

// @ts-ignore
async function sendEmail(to, subject, text) {
    try {
        const info = await transporter.sendMail({
            from: process.env.SMTP_USERNAME,
            to,
            subject,
            text
        });
        console.log('Email sent:', info.response);
    } catch (error) {
        console.error('Error sending email:', error);
        throw error;
    }
}

module.exports = {
    sendEmail
};