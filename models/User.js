const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  email: { 
    type: String, 
    required: true, 
    unique: true, 
    lowercase: true,
    trim: true
  },
  phoneNumber: { 
    type: String, 
    unique: true, 
    sparse: true,
    trim: true
  },
  passwordHash: { 
    type: String,
    required: true // We'll make it required for now unless using social login
  },
  fullName: { 
    type: String, 
    required: true,
    trim: true
  },
  role: { 
    type: String, 
    enum: ['customer', 'provider', 'admin'], 
    default: 'customer' 
  },
  isBanned: {
    type: Boolean,
    default: false
  },
  preferences: {
    notifications: { type: Boolean, default: true }
  }
}, { timestamps: true });

const User = mongoose.model('User', userSchema);
module.exports = User;
