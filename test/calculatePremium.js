var PremiumCalculator = artifacts.require('./PremiumCalculator.sol')

contract('PremiumCalculator', function(accounts) {
  it('...should calculate minimum possible premium', async function() {
    const PremiumCalculatorInstance = await PremiumCalculator.deployed()

    const basePremium = 0.000001
    const basePremiumInWei = web3.toWei(basePremium, 'ether')
    const loading = 99

    await PremiumCalculatorInstance.initialize(basePremiumInWei, loading, { from: accounts[0] })

    // const batteryDesignCapacity = 70 // not implemented
    const currentChargeLevel = 40 // 1
    const deviceAgeInMonths = 1 // 0.9
    const totalCpuUsage = 5 // 0.95
    const region = 'fi' // 1
    const deviceBrand = 'huawei' // 1
    const batteryWearLevel = '100' // 1

    // premium = 0.000001 * 1 * 0.9 * 0.95 * 1 * 1 * 1 = 0.000000855
    // premium - loading = 0.000000855 * 0.01 = 0.00000000855

    const premiumInWei = await PremiumCalculatorInstance.calculatePremium(
      // batteryDesignCapacity,
      currentChargeLevel,
      deviceAgeInMonths,
      totalCpuUsage,
      region,
      deviceBrand,
      batteryWearLevel,
      { from: accounts[0] }
    )

    const premium = web3.fromWei(premiumInWei.toNumber(), 'ether')

    assert.equal(premium, 0.00000000855)
  })

  it('...should calculate maximum possible premium', async function() {
    const PremiumCalculatorInstance = await PremiumCalculator.deployed()

    const basePremium = 999999.999999
    const basePremiumInWei = web3.toWei(basePremium, 'ether')
    const loading = 1

    await PremiumCalculatorInstance.initialize(basePremiumInWei, loading, { from: accounts[0] })

    // const batteryDesignCapacity = 70 // not implemented
    const currentChargeLevel = 5 // 1.2
    const deviceAgeInMonths = 71 // 1.2
    const totalCpuUsage = 99 // 1.1
    const region = 'fi' // 1
    const deviceBrand = 'elephone' // 1.1
    const batteryWearLevel = '100' // 1

    // premium = 999999.999999 * 1.2 * 1.2 * 1.1 * 1 * 1.1 * 1 = 1742399.9999982576
    // premium - loading = 1742399.9999982576 * 0.99 = 1724975.999998275024

    const premiumInWei = await PremiumCalculatorInstance.calculatePremium(
      // batteryDesignCapacity,
      currentChargeLevel,
      deviceAgeInMonths,
      totalCpuUsage,
      region,
      deviceBrand,
      batteryWearLevel,
      { from: accounts[0] }
    )

    const premium = web3.fromWei(premiumInWei.toNumber(), 'ether')

    assert.equal(premium, 1724975.999998275024)
  })
})
