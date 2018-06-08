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
  PY: await artifacts.require('HurricaneGuardPayout').deployed(),
  DB: await artifacts.require('HurricaneGuardDatabase').deployed(),
  AC: await artifacts.require('HurricaneGuardAccessController').deployed(),
  UW: await artifacts.require('HurricaneGuardUnderwrite').deployed(),
  LG: await artifacts.require('HurricaneGuardLedger').deployed(),
  NP: await artifacts.require('HurricaneGuardNewPolicy').deployed(),
  C: await artifacts.require('HurricaneGuardController').deployed()
})

/**
 *
 *
 * @param {any} contracts
 * @param {any} accounts
 * @param {any} permissions
 * @returns
 */
module.exports.expectedPermissions = (HG, accounts, permissions) => {
  const permissionsSet = [
    ['HG.Owner', accounts[1], false],
    ['HG.Funder', accounts[2], false],
    ['HG.CustomersAdmin', accounts[3], false],
    ['HG.Emergency', accounts[4], false],
    ['HG.Controller', HG.C.address, false],
    ['HG.Database', HG.DB.address, false],
    ['HG.Ledger', HG.LG.address, false],
    ['HG.Payout', HG.PY.address, false],
    ['HG.Underwrite', HG.UW.address, false],
    ['HG.NewPolicy', HG.NP.address, false],
    ['HG.AccessController', HG.AC.address, false],
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
