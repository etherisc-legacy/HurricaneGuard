🌀 Parametric Hurricane Insurance Contracts 🌀
=============================================

HurricaneGuard is the first blockchain powered insurance contract available to people and businesses for weather risk coverage. The purpose of HurricaneGuard is to protect people and businesses from hurricane losses such as property damage, business losses, and loss of income using smart contracts on the blockchain and NOAA-validated weather parameters for immediate payout within days of a catastrophic disaster.
A web user interface can be found [here](http://hurricaneguard.io).

Features
-----------
* Available for property damage to homes, business losses, and loss of income
* Built using Ethereum smart contracts
* Measures hurricane force using NOAA-approved models
* Policy contract terms are public
* Coverage is fully licensed
* Cryptocurrency payment options
* Optional email notifications when an hurricane event is close to your location

Development
-----------

* Install [Truffle Framework](https://truffleframework.com)
* Run [Ganache](https://truffleframework.com/ganache)
* Use [Oraclize Ethereum Bridge](https://github.com/oraclize/ethereum-bridge)
for testing contracts with Oraclize integration `ethereum-bridge -H localhost:7545 --dev -a 9`
* Update [HurricaneGuardUnderwrite.sol#L43](https://github.com/etherisc/HurricaneGuard/blob/master/contracts/HurricaneGuardUnderwrite.sol#L43)
and [HurricaneGuardPayout.sol#L45](https://github.com/etherisc/HurricaneGuard/blob/master/contracts/HurricaneGuardPayout.sol#L45)
to include the address provided by ethereum bridge
* Copy `.env-sample` into `.env` and set values
* To run tests `npm install` then `npm test`

Contributors
------------

* Joel Martínez [@j0x0j](https://github.com/j0x0j)
