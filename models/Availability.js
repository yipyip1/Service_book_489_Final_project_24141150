const mongoose = require('mongoose');

const availabilitySchema = new mongoose.Schema({
  providerId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  dayOfWeek: { 
    type: Number, 
    min: 0, 
    max: 6, 
    required: true // 0 = Sunday, 1 = Monday, etc.
  },
  startTime: { 
    type: String, 
    required: true // e.g., "09:00"
  },
  endTime: { 
    type: String, 
    required: true // e.g., "17:00"
  },
  isAvailable: { 
    type: Boolean, 
    default: true 
  }
}, { timestamps: true });

const Availability = mongoose.model('Availability', availabilitySchema);
module.exports = Availability;
