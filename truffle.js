module.exports = {
  networks: {
    development: {
      host: '127.0.0.1',
      port: 7545,
      network_id: '*',
      gas: 6721975,
      gasPrice: 10000000000,
    }
  }
  // , mocha: {
  //   reporter: 'eth-gas-reporter',
  //   reporterOptions: {
  //     currency: 'EUR',
  //     gasPrice: 1
  //   }
  // }
}