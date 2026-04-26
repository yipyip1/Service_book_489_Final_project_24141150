const express = require('express');
const router = express.Router();
const { getNotifications, markAsRead } = require('../controllers/notificationController');
const { protect, provider } = require('../middlewares/authMiddleware');

router.get('/', protect, provider, getNotifications);
router.put('/:id/read', protect, provider, markAsRead);

module.exports = router;
