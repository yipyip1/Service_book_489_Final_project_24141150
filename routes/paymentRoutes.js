const express = require('express');
const router = express.Router();
const { createPaymentIntent, refundPayment } = require('../controllers/paymentController');
const { protect } = require('../middlewares/authMiddleware');

router.post('/intent', protect, createPaymentIntent);
router.post('/refund/:bookingId', protect, refundPayment);

module.exports = router;
