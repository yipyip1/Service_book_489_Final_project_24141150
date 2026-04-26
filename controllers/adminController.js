const User = require('../models/User');
const Service = require('../models/Service');
const Booking = require('../models/Booking');

// @desc    Get all users
// @route   GET /api/admin/users
// @access  Private/Admin
const getUsers = async (req, res) => {
  try {
    const users = await User.find({}).select('-passwordHash');
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Ban or unban a user
// @route   PUT /api/admin/users/:id/ban
// @access  Private/Admin
const toggleBanUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (user.role === 'admin') {
      return res.status(400).json({ message: 'Cannot ban another admin' });
    }

    user.isBanned = !user.isBanned;
    await user.save();

    res.json({ message: `User ${user.isBanned ? 'banned' : 'unbanned'} successfully`, user });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Delete a service (Admin override)
// @route   DELETE /api/admin/services/:id
// @access  Private/Admin
const deleteServiceAdmin = async (req, res) => {
  try {
    const service = await Service.findByIdAndDelete(req.params.id);
    if (!service) {
      return res.status(404).json({ message: 'Service not found' });
    }
    res.json({ message: 'Service removed successfully by Admin' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Get all bookings (Admin)
// @route   GET /api/admin/bookings
// @access  Private/Admin
const getAllBookings = async (req, res) => {
  try {
    const bookings = await Booking.find({})
      .populate('customerId', 'fullName email')
      .populate('serviceId', 'title price category')
      .sort({ createdAt: -1 });
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Get analytics overview (Admin)
// @route   GET /api/admin/analytics
// @access  Private/Admin
const getAnalytics = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments({ role: { $ne: 'admin' } });
    const totalCustomers = await User.countDocuments({ role: 'customer' });
    const totalProviders = await User.countDocuments({ role: 'provider' });
    const totalServices = await Service.countDocuments({});
    const totalBookings = await Booking.countDocuments({});

    const bookingsByStatus = {
      pending: await Booking.countDocuments({ status: 'pending' }),
      confirmed: await Booking.countDocuments({ status: 'confirmed' }),
      completed: await Booking.countDocuments({ status: 'completed' }),
      cancelled: await Booking.countDocuments({ status: 'cancelled' }),
    };

    const paymentStats = {
      paid: await Booking.countDocuments({ paymentStatus: 'paid' }),
      refunded: await Booking.countDocuments({ paymentStatus: 'refunded' }),
      pending: await Booking.countDocuments({ paymentStatus: 'pending' }),
    };

    // Revenue calculations
    const paidBookings = await Booking.find({ paymentStatus: 'paid' });
    const totalRevenue = paidBookings.reduce((sum, b) => sum + (b.totalAmount || 0), 0);

    const refundedBookings = await Booking.find({ paymentStatus: 'refunded' });
    const totalRefunded = refundedBookings.reduce((sum, b) => sum + (b.totalAmount || 0), 0);

    const netRevenue = totalRevenue - totalRefunded;

    res.json({
      totalUsers,
      totalCustomers,
      totalProviders,
      totalServices,
      totalBookings,
      bookingsByStatus,
      paymentStats,
      totalRevenue,
      totalRefunded,
      netRevenue,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = {
  getUsers,
  toggleBanUser,
  deleteServiceAdmin,
  getAllBookings,
  getAnalytics,
};
