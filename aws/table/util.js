const generateOTP = () => {
          
    // Declare a digits variable 
    // which stores all digits
    var digits = '0123456789';
    let OTP = '';
    for (let i = 0; i < 4; i++ ) {
        OTP += digits[Math.floor(Math.random() * 10)];
    }
    return OTP;
}

function generateToken() { 
    return Date.now().toString(36) + Math.random().toString(36).substring(2);
}

export {generateOTP, generateToken};