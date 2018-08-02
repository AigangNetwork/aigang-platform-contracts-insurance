var BytesHelper = artifacts.require('./utils/BytesHelper.sol')
var Strings = artifacts.require('./utils/Strings.sol')

var Product = artifacts.require('./Product.sol')
var PremiumCalculator = artifacts.require('./PremiumCalculator.sol')

var MocBytesHelper = artifacts.require('MocBytesHelper.sol')

module.exports = function (deployer) {
  deployer.deploy(Strings)
  deployer.link(Strings, PremiumCalculator)
  deployer.deploy(PremiumCalculator)

  deployer.deploy(BytesHelper)
  deployer.link(BytesHelper, Product)

  deployer.deploy(Product)
}