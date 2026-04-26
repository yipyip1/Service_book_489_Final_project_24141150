const multer = require('multer');
const path = require('path');

// Set Storage Engine
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    // Save to the /uploads folder in the root directory
    cb(null, 'uploads/');
  },
  filename: function (req, file, cb) {
    // Rename file to prevent collisions (e.g. image-168392193.jpg)
    cb(null, file.fieldname + '-' + Date.now() + path.extname(file.originalname));
  }
});

// Check File Type
function checkFileType(file, cb) {
  // Allowed ext
  const filetypes = /jpeg|jpg|png|webp|gif|bmp|heic|heif/;
  // Check ext
  const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
  // Check mime - accept any image type
  const mimetype = file.mimetype.startsWith('image/');

  if (mimetype || extname) {
    return cb(null, true);
  } else {
    cb('Error: Images Only!');
  }
}

// Initialize Upload
const upload = multer({
  storage: storage,
  limits: { fileSize: 5000000 }, // 5MB limit
  fileFilter: function (req, file, cb) {
    checkFileType(file, cb);
  }
});

module.exports = upload;
