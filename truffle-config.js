const dotenv = require('dotenv')
const HDWalletProvider = require('truffle-hdwallet-provider')
const { MNEMONIC, INFURA_KEY } = dotenv.load().parsed

const rinkebyProvider =
  new HDWalletProvider(MNEMONIC, 'https://rinkeby.infura.io/' + INFURA_KEY, 0, 10)

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
