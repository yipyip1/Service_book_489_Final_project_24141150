const express = require('express');
const router = express.Router();
const { getServices, getServiceById, createService } = require('../controllers/serviceController');
const { protect } = require('../middlewares/authMiddleware');

router.get('/', getServices);
router.post('/', protect, createService);
router.get('/:id', getServiceById);

module.exports = router;
