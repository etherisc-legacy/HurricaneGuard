/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description NewPolicy contract.
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 *
 * Hurricane Response with Underwriting and Payout
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */


pragma solidity ^0.4.11;


import "./HurricaneGuardControlledContract.sol";
import "./HurricaneGuardConstants.sol";
import "./HurricaneGuardDatabaseInterface.sol";
import "./HurricaneGuardAccessControllerInterface.sol";
import "./HurricaneGuardLedgerInterface.sol";
import "./HurricaneGuardUnderwriteInterface.sol";
import "./convertLib.sol";
import "./../vendors/strings.sol";

contract HurricaneGuardNewPolicy is HurricaneGuardControlledContract, HurricaneGuardConstants, ConvertLib {
  HurricaneGuardAccessControllerInterface HG_AC;
  HurricaneGuardDatabaseInterface HG_DB;
  HurricaneGuardLedgerInterface HG_LG;
  HurricaneGuardUnderwriteInterface HG_UW;

  function HurricaneGuardNewPolicy(address _controller) {
    setController(_controller);
  }

  function setContracts() onlyController {
    HG_AC = HurricaneGuardAccessControllerInterface(getContract("HG.AccessController"));
    HG_DB = HurricaneGuardDatabaseInterface(getContract("HG.Database"));
    HG_LG = HurricaneGuardLedgerInterface(getContract("HG.Ledger"));
    HG_UW = HurricaneGuardUnderwriteInterface(getContract("HG.Underwrite"));

    HG_AC.setPermissionByAddress(101, 0x0);
    HG_AC.setPermissionById(102, "HG.Controller");
    HG_AC.setPermissionById(103, "HG.Owner");
  }

  function bookAndCalcRemainingPremium() internal returns (uint) {
    uint v = msg.value;
    uint reserve = v * RESERVE_PERCENT / 100;
    uint remain = v - reserve;
    uint reward = remain * REWARD_PERCENT / 100;

    // HG_LG.bookkeeping(Acc.Balance, Acc.Premium, v);
    HG_LG.bookkeeping(Acc.Premium, Acc.RiskFund, reserve);
    HG_LG.bookkeeping(Acc.Premium, Acc.Reward, reward);

    return (uint(remain - reward));
  }

  function maintenanceMode(bool _on) {
    if (HG_AC.checkPermission(103, msg.sender)) {
      HG_AC.setPermissionByAddress(101, 0x0, !_on);
    }
  }

  /**
  * @dev newPolicy creates a new policy
  * and returns latest wind speed parameter in knots to __callback
  * @param _market the market or risk pool for the policy
  * @param _season the current season for the risk pool
  * @param _latlng the geo position for the policy
  * @param _currency the currency used to pay the premium
  * @param _customerExternalId the id created by the api
  */
  function newPolicy(
    bytes32 _market,
    bytes32 _season,
    bytes32 _latlng,
    Currency _currency,
    bytes32 _customerExternalId) payable
  {
    // here we can switch it off.
    require(HG_AC.checkPermission(101, 0x0));

    // solidity checks for valid _currency parameter
    if (_currency == Currency.ETH) {
      // ETH
      if (msg.value < MIN_PREMIUM || msg.value > MAX_PREMIUM) {
        LogPolicyDeclined(0, "Invalid premium value ETH");
        HG_LG.sendFunds(msg.sender, Acc.Premium, msg.value);
        return;
      }
    } else {
      require(msg.sender == getContract("HG.CustomersAdmin"));

      if (_currency == Currency.USD) {
        // USD
        if (msg.value < MIN_PREMIUM_USD || msg.value > MAX_PREMIUM_USD) {
          LogPolicyDeclined(0, "Invalid premium value USD");
          HG_LG.sendFunds(msg.sender, Acc.Premium, msg.value);
          return;
        }
      }
    }

    // forward premium
    HG_LG.receiveFunds.value(msg.value)(Acc.Premium);

    // develop conditions to decline policies
    // 1- ideally we have a registry of markets
    //  - and a safe way to create them
    // 2- _season is not current year
    // 3- TODO: the amount of policies for the pilot are filled

    if (_season != strings.uintToBytes(getYear(block.timestamp))) {
      LogPolicyDeclined(0, "Invalid market/season");
      HG_LG.sendFunds(msg.sender, Acc.Premium, msg.value);
      return;
    }

    bytes32 riskId = HG_DB.createUpdateRisk(_market, _season);

    uint premium = bookAndCalcRemainingPremium();
    uint policyId = HG_DB.createPolicy(msg.sender, premium, _currency, _customerExternalId, riskId, _latlng);

    // now we have successfully applied
    HG_DB.setState(
      policyId,
      policyState.Applied,
      now,
      "Policy applied by customer"
    );

    LogPolicyApplied(
      policyId,
      msg.sender,
      _market,
      premium
    );

    LogExternal(
      policyId,
      msg.sender,
      _customerExternalId
    );

    HG_UW.scheduleUnderwriteOraclizeCall(policyId, _latlng);
  }
}
