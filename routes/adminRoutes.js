const express = require('express');
const router = express.Router();
const { getUsers, toggleBanUser, deleteServiceAdmin, getAllBookings, getAnalytics } = require('../controllers/adminController');
const { protect, admin } = require('../middlewares/authMiddleware');

router.get('/users', protect, admin, getUsers);
router.put('/users/:id/ban', protect, admin, toggleBanUser);
router.delete('/services/:id', protect, admin, deleteServiceAdmin);
router.get('/bookings', protect, admin, getAllBookings);
router.get('/analytics', protect, admin, getAnalytics);

module.exports = router;
