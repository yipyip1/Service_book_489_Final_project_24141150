const express = require('express');
const router = express.Router();
const { getServices, getServiceById, createService, getMyServices } = require('../controllers/serviceController');
const { protect, provider } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware');

router.get('/', getServices);
router.get('/my-services', protect, provider, getMyServices);
router.post('/', protect, provider, upload.single('image'), createService);
router.get('/:id', getServiceById);

module.exports = router;
