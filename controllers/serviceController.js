const Service = require('../models/Service');

// @desc    Get all services (Service Discovery)
// @route   GET /api/services
// @access  Public
const getServices = async (req, res) => {
  try {
    const { category, search } = req.query;
    
    // Filter logic
    const filter = { isActive: true };
    if (category) filter.category = { $regex: category, $options: 'i' };
    if (search) filter.title = { $regex: search, $options: 'i' };

    const services = await Service.find(filter)
      .populate('providerId', 'fullName email') // Fetch provider details alongside
      .sort({ createdAt: -1 });

    res.json(services);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Get single service details
// @route   GET /api/services/:id
// @access  Public
const getServiceById = async (req, res) => {
  try {
    const service = await Service.findById(req.params.id).populate('providerId', 'fullName email');
    
    if (service) {
      res.json(service);
    } else {
      res.status(404).json({ message: 'Service not found' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Create a new service
// @route   POST /api/services
// @access  Private (Providers)
const createService = async (req, res) => {
  try {
    const { title, description, category, price, durationMinutes, contactNumber } = req.body;
    
    // Check if image was uploaded
    let imageUrl = '';
    if (req.file) {
      // Create a URL path that the frontend can load
      imageUrl = '/uploads/' + req.file.filename;
    } else {
      return res.status(400).json({ message: 'Service Image is required' });
    }

    if (!contactNumber) {
      return res.status(400).json({ message: 'Contact Number is required' });
    }
    
    const service = await Service.create({
      providerId: req.user._id,
      title,
      description,
      category,
      price,
      durationMinutes,
      imageUrl,
      contactNumber
    });

    res.status(201).json(service);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Get services posted by logged-in provider
// @route   GET /api/services/my-services
// @access  Private (Providers)
const getMyServices = async (req, res) => {
  try {
    const services = await Service.find({ providerId: req.user._id })
      .sort({ createdAt: -1 });
    res.json(services);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = {
  getServices,
  getServiceById,
  createService,
  getMyServices
};
