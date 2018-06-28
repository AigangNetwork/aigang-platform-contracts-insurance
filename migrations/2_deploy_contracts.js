var PremiumCalculator = artifacts.require('./PremiumCalculator.sol')

module.exports = function(deployer) {
  deployer.deploy(PremiumCalculator)
}
