const HDWalletProvider = require('truffle-hdwallet-provider')

// Pub address: 0x756d8bae674eb9e08f7d3644ee32a56aab828d59
const mnemonic =
  'payment local math advance attract region unveil energy barely kitten model armor'
const INFURA_KEY = 'npPr7wL0YRxP3ewG82AL'
const rinkebyProvider = new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/' + INFURA_KEY, 0, 10)

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    development: {
      host: '127.0.0.1',
      port: 7545,
      network_id: '*'
    },
    rinkeby: {
      provider: () => rinkebyProvider,
      gas: 6.9e6,
      gasPrice: 15000000001,
      network_id: 4
    }
  }
}
