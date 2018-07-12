var TestToken = artifacts.require('TestToken.sol')
var PremiumCalculator = artifacts.require('./PremiumCalculator.sol')
var Product = artifacts.require('./Product.sol')
// var BytesHelper = artifacts.require('./utils/BytesHelper.sol')

let tryCatch = require('./exceptions.js').tryCatch
let errTypes = require('./exceptions.js').errTypes

contract('Product', accounts => {
  let premiumCalculatorInstance
  let testTokenInstance
  let productInstance
  let now
  let endDate
  let owner = accounts[0]
  let executor = accounts[1]
  let nonOwner = accounts[2]
  let addresses = [
    '0xD7dFCEECe5bb82F397f4A9FD7fC642b2efB1F565',
    '0x501AC3B461e7517D07dCB5492679Cc7521AadD42',
    '0xDc76C949100FbC502212c6AA416195Be30CE0732',
    '0x2C49e8184e468F7f8Fb18F0f29f380CD616eaaeb',
    '0xB3d3c445Fa47fe40a03f62d5D41708aF74a5C387',
    '0x34D468BFcBCc0d83F4DF417E6660B3Cf3e14F62A',
    '0x27E6FaE913861180fE5E95B130d4Ae4C58e2a4F4',
    '0x7B199FAf7611421A02A913EAF3d150E359718C2B',
    '0x086282022b8D0987A30CdD508dBB3236491F132e',
    '0xdd39B760748C1CA92133FD7Fc5448F3e6413C138',
    '0x0868411cA03e6655d7eE957089dc983d74b9Bf1A',
    '0x4Ec993E1d6980d7471Ca26BcA67dE6C513165922'
  ]

  describe('#initialize', async function() {
    beforeEach(async function() {
      premiumCalculatorInstance = await PremiumCalculator.new()
      testTokenInstance = await TestToken.new()
      productInstance = await Product.new()

      const basePremium = web3.toWei(10, 'ether')
      const payout = web3.toWei(20, 'ether')
      const loading = web3.toWei(1, 'ether')
      now = Date.now()
      endDate = now + 60

      await premiumCalculatorInstance.initialize(basePremium, loading, payout, { from: owner })
    })

    it('happy flow', async function() {
      await productInstance.initialize(premiumCalculatorInstance.address, testTokenInstance.address, now, endDate, {
        from: owner
      })

      let paused = await productInstance.paused({ from: owner })
      let premiumCalculator = await productInstance.premiumCalculator({ from: owner })
      let token = await productInstance.token({ from: owner })
      let utcProductStartDate = await productInstance.utcProductStartDate({ from: owner })
      let utcProductEndDate = await productInstance.utcProductEndDate({ from: owner })

      assert.equal(paused, false)
      assert.equal(premiumCalculator, premiumCalculatorInstance.address)
      assert.equal(utcProductStartDate, now)
      assert.equal(utcProductEndDate, endDate)
    })

    it('throws than not owner', async function() {
      await tryCatch(
        productInstance.initialize(premiumCalculatorInstance.address, testTokenInstance.address, now, endDate, {
          from: nonOwner
        }),
        errTypes.revert
      )

      let paused = await productInstance.paused({ from: nonOwner })
      let utcProductStartDate = await productInstance.utcProductStartDate({ from: nonOwner })
      let utcProductEndDate = await productInstance.utcProductEndDate({ from: nonOwner })

      assert.equal(paused, true)
      assert.equal(utcProductStartDate, 0)
      assert.equal(utcProductEndDate, 0)
    })
  })

  describe('#policies', async function() {
    beforeEach(async function() {
      premiumCalculatorInstance = await PremiumCalculator.new()
      testTokenInstance = await TestToken.new()
      productInstance = await Product.new()

      const basePremium = web3.toWei(10, 'ether')
      const payout = web3.toWei(20, 'ether')
      const loading = web3.toWei(1, 'ether')
      now = Date.now()
      endDate = now + 6000

      await premiumCalculatorInstance.initialize(basePremium, loading, payout, { from: owner })
      await productInstance.initialize(premiumCalculatorInstance.address, testTokenInstance.address, now, endDate, {
        from: owner
      })
    })

    it('happy flow', async function() {
      let id = 'productID1'
      let p_owner = addresses[0]
      let start = Date.now()
      let end = start + 100
      let calculatedPayOut = web3.toWei(1.6, 'ether')
      let properties = 'test 1'

      //testTokenInstance = await TestToken.new()

      await productInstance.addPolicy(id, start, end, calculatedPayOut, properties, { from: owner })

      let policiesCount = await productInstance.policiesCount({ from: owner })

      assert.equal(policiesCount, 1)
    })
  })

  describe('#payment', async function() {
    beforeEach(async function() {
      premiumCalculatorInstance = await PremiumCalculator.new()
      testTokenInstance = await TestToken.new()
      productInstance = await Product.new()
    })

    it('happy flow', async function() {
      const premium = 300
      const policyId = 'fasdfa213'
      const paymentValue = web3.toWei(premium.toString(), 'ether')
      const policyIdBytes = web3.fromAscii(policyId)
      now = Date.now()
      endDate = now + 6000

      await testTokenInstance.transfer(owner, web3.toWei(400))

      await productInstance.initialize(premiumCalculatorInstance.address, testTokenInstance.address, now, endDate, {
        from: owner
      })

      await productInstance.pause(false, { from: owner })

      await testTokenInstance.approveAndCall(productInstance.contract.address, paymentValue, policyIdBytes, {
        from: owner
      })
    })
  })
})
