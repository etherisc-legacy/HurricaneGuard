/* global artifacts */

const strings = artifacts.require('./../vendors/strings.sol')
const usingOraclize = artifacts.require('./../vendors/usingOraclize.sol')

module.exports = async (deployer) => {
  await deployer.deploy(strings)
  await deployer.deploy(usingOraclize)
}
