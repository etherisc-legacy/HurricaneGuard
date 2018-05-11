/* global assert */
/* global web3 */
/* global artifacts */

/**
 * Assert previous error
 *
 * @param {any} error
 * @returns
 */
module.exports.assertJump = error => assert.isAbove(error.message.search('invalid opcode'), -1, 'Invalid opcode error must be returned')

/**
 * Returns value in ethers
 *
 * @param {any} number
 * @returns
 */
module.exports.ether = n => new web3.BigNumber(web3.toWei(n, 'ether'))

module.exports.EVMThow = () => 'invalid opcode'

/**
 *
 *
 * @param {any} artifacts
 * @returns
 */
module.exports.getDeployedContracts = async () => ({
  PY: await artifacts.require('HurricaneResponsePayout').deployed(),
  DB: await artifacts.require('HurricaneResponseDatabase').deployed(),
  AC: await artifacts.require('HurricaneResponseAccessController').deployed(),
  UW: await artifacts.require('HurricaneResponseUnderwrite').deployed(),
  LG: await artifacts.require('HurricaneResponseLedger').deployed(),
  NP: await artifacts.require('HurricaneResponseNewPolicy').deployed(),
  C: await artifacts.require('HurricaneResponseController').deployed()
})

/**
 *
 *
 * @param {any} contracts
 * @param {any} accounts
 * @param {any} permissions
 * @returns
 */
module.exports.expectedPermissions = (HR, accounts, permissions) => {
  const permissionsSet = [
    ['HR.Owner', accounts[1], false],
    ['HR.Funder', accounts[2], false],
    ['HR.CustomersAdmin', accounts[3], false],
    ['HR.Emergency', accounts[4], false],
    ['HR.Controller', HR.C.address, false],
    ['HR.Database', HR.DB.address, false],
    ['HR.Ledger', HR.LG.address, false],
    ['HR.Payout', HR.PY.address, false],
    ['HR.Underwrite', HR.UW.address, false],
    ['HR.NewPolicy', HR.NP.address, false],
    ['HR.AccessController', HR.AC.address, false],
    ['deployer', accounts[0], false],
    ['customer', accounts[5], false],
    ['oraclize', accounts[6], false]
  ]

  return permissionsSet.map((perm) => {
    if (permissions[perm[0]] !== undefined) {
      return [
        perm[0],
        perm[1],
        permissions[perm[0]]
      ]
    }

    return perm
  })
}
