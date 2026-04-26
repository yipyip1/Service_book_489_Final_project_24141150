const mongoose = require('mongoose');

const serviceSchema = new mongoose.Schema({
  providerId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  title: { 
    type: String, 
    required: true,
    trim: true
  },
  description: { 
    type: String,
    trim: true
  },
  category: { 
    type: String, 
    required: true 
  },
  price: { 
    type: Number, 
    required: true 
  },
  durationMinutes: { 
    type: Number, 
    required: true 
  },
  rating: {
    average: { type: Number, default: 0 },
    count: { type: Number, default: 0 }
  },
  imageUrl: {
    type: String,
    required: true
  },
  contactNumber: {
    type: String,
    required: true
  },
  isActive: { 
    type: Boolean, 
    default: true 
  }
}, { timestamps: true });

const Service = mongoose.model('Service', serviceSchema);
module.exports = Service;
