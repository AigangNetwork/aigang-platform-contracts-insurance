var MocBytesHelper = artifacts.require('MocBytesHelper.sol')

let tryCatch = require('./exceptions.js').tryCatch
let errTypes = require('./exceptions.js').errTypes

contract('MocBytesHelper', accounts => {
  let mocBytesHelper
  let owner = accounts[0]
  let executor = accounts[1]
  let nonOwner = accounts[2]

  beforeEach(async function() {
    mocBytesHelper = await MocBytesHelper.new()
  })

  it('ping', async function() {
    let result = await mocBytesHelper.Ping({ from: owner })

    assert.equal(web3.toUtf8(result), 'Pong', 'result is not test')
  })

  it('happy flow', async function() {
    let value = 'test'
    let result = await mocBytesHelper.BytesToBytes32(web3.fromUtf8(value), { from: owner })

    assert.equal(web3.toUtf8(result), value, `result is not ${value}`)
  })

  it('max limit is reach', async function() {
    let value = '123456789012345678901234567890123'
    let result = await mocBytesHelper.BytesToBytes32(web3.fromUtf8(value), { from: owner })

    assert.equal(web3.toUtf8(result), '12345678901234567890123456789012', `result is not ${value}`)
  })
})
