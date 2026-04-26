const Stripe = require('stripe');
const stripe = Stripe(process.env.STRIPE_SECRET_KEY);
const Booking = require('../models/Booking');

// @desc    Create Payment Intent
// @route   POST /api/payments/intent
// @access  Private
const createPaymentIntent = async (req, res) => {
  try {
    const { amount } = req.body;
    
    // Stripe expects amount in cents
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100),
      currency: 'usd',
      automatic_payment_methods: {
        enabled: true,
      },
    });

    res.json({
      paymentIntent: paymentIntent.client_secret,
      id: paymentIntent.id
    });
  } catch (error) {
    res.status(500).json({ message: 'Stripe error', error: error.message });
  }
};

// @desc    Refund Payment
// @route   POST /api/payments/refund/:bookingId
// @access  Private (Provider or Admin)
const refundPayment = async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.bookingId);
    
    if (!booking) {
      return res.status(404).json({ message: 'Booking not found' });
    }

    if (booking.paymentStatus !== 'paid' || !booking.stripePaymentIntentId) {
      return res.status(400).json({ message: 'Booking is not eligible for refund' });
    }

    // Process refund via Stripe
    const refund = await stripe.refunds.create({
      payment_intent: booking.stripePaymentIntentId,
    });

    booking.paymentStatus = 'refunded';
    await booking.save();

    res.json({ message: 'Refund processed successfully', refund });
  } catch (error) {
    res.status(500).json({ message: 'Stripe Refund Error', error: error.message });
  }
};

module.exports = {
  createPaymentIntent,
  refundPayment
};
