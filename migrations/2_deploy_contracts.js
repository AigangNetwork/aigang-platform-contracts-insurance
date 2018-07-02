var BytesHelper = artifacts.require('./utils/BytesHelper.sol')

var Product = artifacts.require('./Product.sol')
var PremiumCalculator = artifacts.require('./PremiumCalculator.sol')

var MocBytesHelper = artifacts.require('MocBytesHelper.sol')

module.exports = function(deployer) {
  deployer.deploy(PremiumCalculator)
  deployer.deploy(BytesHelper)
  deployer.link(BytesHelper, Product)

  deployer.deploy(Product)
}
