const express = require('express');
const router = express.Router();
const { createBooking, getMyBookings, getProviderBookings, cancelBooking, confirmServiceReceived } = require('../controllers/bookingController');
const { protect, provider } = require('../middlewares/authMiddleware');

router.post('/', protect, createBooking);
router.get('/my-bookings', protect, getMyBookings);
router.get('/provider-bookings', protect, provider, getProviderBookings);
router.put('/:id/cancel', protect, cancelBooking);
router.put('/:id/complete', protect, confirmServiceReceived);

module.exports = router;
