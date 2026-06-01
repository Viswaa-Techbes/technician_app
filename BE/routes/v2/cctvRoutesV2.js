const express = require('express');
const cctvController = require('../../controllers/v2/cctvControllerV2');

const router = express.Router();

router.get('/categories', cctvController.listCategories);
router.get('/subcategories', cctvController.listSubcategories);
router.get('/subcategories/:slug', cctvController.getSubcategoryBySlug);
router.get('/camera-types', cctvController.listCameraTypes);
router.get('/addons', cctvController.listAddons);
router.get('/pricing-config', cctvController.getPricingConfig);
router.post('/calculate-price', cctvController.calculatePrice);

module.exports = router;
