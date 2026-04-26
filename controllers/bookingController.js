const Booking = require('../models/Booking');

// @desc    Create new booking
// @route   POST /api/bookings
// @access  Private
const createBooking = async (req, res) => {
  try {
    const { serviceId, startTime, endTime, totalAmount, notes, stripePaymentIntentId, paymentStatus } = req.body;

    const booking = new Booking({
      customerId: req.user._id,
      serviceId,
      startTime,
      endTime,
      totalAmount,
      notes,
      stripePaymentIntentId,
      paymentStatus: paymentStatus || 'pending'
    });

    const savedBooking = await booking.save();

    // Notify Provider
    const Service = require('../models/Service');
    const Notification = require('../models/Notification');
    
    const serviceDetails = await Service.findById(serviceId);
    if (serviceDetails) {
      await Notification.create({
        providerId: serviceDetails.providerId,
        message: `New Booking: ${req.user.fullName || 'A customer'} booked ${serviceDetails.title} for \$${totalAmount}.`
      });
    }

    res.status(201).json(savedBooking);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Get logged in user bookings
// @route   GET /api/bookings/my-bookings
// @access  Private
const getMyBookings = async (req, res) => {
  try {
    const bookings = await Booking.find({ customerId: req.user._id })
      .populate('serviceId', 'title category price')
      .sort({ startTime: -1 });
    
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Get bookings for a specific provider's services
// @route   GET /api/bookings/provider-bookings
// @access  Private (Provider)
const getProviderBookings = async (req, res) => {
  try {
    // 1. Find all services owned by this provider
    const Service = require('../models/Service');
    const myServices = await Service.find({ providerId: req.user._id }).select('_id');
    const serviceIds = myServices.map(s => s._id);

    // 2. Find bookings matching those services
    const bookings = await Booking.find({ serviceId: { $in: serviceIds } })
      .populate('customerId', 'fullName email phoneNumber')
      .populate('serviceId', 'title')
      .sort({ startTime: -1 });

    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Cancel a booking (Customer)
// @route   PUT /api/bookings/:id/cancel
// @access  Private
const cancelBooking = async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });

    // Only the customer who made the booking can cancel
    if (booking.customerId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    if (booking.status === 'cancelled') {
      return res.status(400).json({ message: 'Booking is already cancelled' });
    }
    if (booking.status === 'completed') {
      return res.status(400).json({ message: 'Cannot cancel a completed booking' });
    }

    booking.status = 'cancelled';
    await booking.save();

    // Notify Provider
    const Service = require('../models/Service');
    const Notification = require('../models/Notification');
    const serviceDetails = await Service.findById(booking.serviceId);
    if (serviceDetails) {
      await Notification.create({
        providerId: serviceDetails.providerId,
        message: `Booking Cancelled: ${req.user.fullName || 'A customer'} cancelled ${serviceDetails.title}.`
      });
    }

    res.json({ message: 'Booking cancelled', booking });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Confirm service received (Customer)
// @route   PUT /api/bookings/:id/complete
// @access  Private
const confirmServiceReceived = async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });

    if (booking.customerId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }

    if (booking.status === 'cancelled') {
      return res.status(400).json({ message: 'Cannot complete a cancelled booking' });
    }

    booking.status = 'completed';
    await booking.save();

    res.json({ message: 'Service marked as completed', booking });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = {
  createBooking,
  getMyBookings,
  getProviderBookings,
  cancelBooking,
  confirmServiceReceived
};
