/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Underwrite contract
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
import "./HurricaneGuardPayoutInterface.sol";
import "./HurricaneGuardOraclizeInterface.sol";
import "./convertLib.sol";
import "./../vendors/strings.sol";

contract HurricaneGuardUnderwrite is HurricaneGuardControlledContract, HurricaneGuardConstants, HurricaneGuardOraclizeInterface, ConvertLib {
  using strings for *;

  HurricaneGuardDatabaseInterface HG_DB;
  HurricaneGuardLedgerInterface HG_LG;
  HurricaneGuardPayoutInterface HG_PY;
  HurricaneGuardAccessControllerInterface HG_AC;

  function HurricaneGuardUnderwrite(address _controller) {
    setController(_controller);
    /* For testnet and mainnet */
    /* oraclize_setProof(proofType_TLSNotary); */
    /* For development */
    OAR = OraclizeAddrResolverI(0x80e9c30A9dae62BCCf777E741bF2E312d828b65f);
  }

  function setContracts() onlyController {
    HG_AC = HurricaneGuardAccessControllerInterface(getContract("HG.AccessController"));
    HG_DB = HurricaneGuardDatabaseInterface(getContract("HG.Database"));
    HG_LG = HurricaneGuardLedgerInterface(getContract("HG.Ledger"));
    HG_PY = HurricaneGuardPayoutInterface(getContract("HG.Payout"));

    HG_AC.setPermissionById(101, "HG.NewPolicy");
    HG_AC.setPermissionById(102, "HG.Funder");
  }

  /*
   * @dev Fund contract
   */
  function fund() payable {
    require(HG_AC.checkPermission(102, msg.sender));

    // todo: bookkeeping
    // todo: fire funding event
  }

  function scheduleUnderwriteOraclizeCall(uint _policyId, bytes32 _latlng) {
    require(HG_AC.checkPermission(101, msg.sender));

    string memory oraclizeUrl = strConcat(
      ORACLIZE_RATINGS_BASE_URL, "latlng=", b32toString(_latlng), ").result"
    );

    bytes32 queryId = oraclize_query("URL", oraclizeUrl, ORACLIZE_GAS);

    // call oraclize to get Flight Stats; this will also call underwrite()
    HG_DB.createOraclizeCallback(
      queryId,
      _policyId,
      oraclizeState.ForUnderwriting
    );

    LogOraclizeCall(_policyId, queryId, oraclizeUrl);
  }

  function __callback(bytes32 _queryId, string _result, bytes _proof) onlyOraclizeOr(getContract('HG.Emergency')) {
    var (policyId,) = HG_DB.getOraclizeCallback(_queryId);
    LogOraclizeCallback(policyId, _queryId, _result, _proof);

    if (bytes(_result).length == 0) {
      decline(policyId, "Declined (empty result)", _proof);
    } else {
      // TODO: Implement stat calculations
      // TODO: Validate data received from real oracle
      uint[6] memory statistics;
      for (uint i = 1; i <= 5; i++) {
        // MOCKED
        statistics[i] = parseInt(_result);
      }
      // underwrite policy
      underwrite(policyId, statistics, _proof);
    }
  } // __callback

  function externalDecline(uint _policyId, bytes32 _reason) external {
    require(msg.sender == HG_CI.getContract("HG.CustomersAdmin"));

    LogPolicyDeclined(_policyId, _reason);

    HG_DB.setState(
      _policyId,
      policyState.Declined,
      now,
      _reason
    );

    HG_DB.setWeight(_policyId, 0, "");

    var (customer, premium) = HG_DB.getCustomerPremium(_policyId);

    if (!HG_LG.sendFunds(customer, Acc.Premium, premium)) {
      HG_DB.setState(
        _policyId,
        policyState.SendFailed,
        now,
        "decline: Send failed."
      );
    }
  }

  function decline(uint _policyId, bytes32 _reason, bytes _proof)	internal {
    LogPolicyDeclined(_policyId, _reason);

    HG_DB.setState(
      _policyId,
      policyState.Declined,
      now,
      _reason
    );

    HG_DB.setWeight(_policyId, 0, _proof);

    var (customer, premium) = HG_DB.getCustomerPremium(_policyId);

    // TODO: LOG
    if (!HG_LG.sendFunds(customer, Acc.Premium, premium)) {
      HG_DB.setState(
        _policyId,
        policyState.SendFailed,
        now,
        "decline: Send failed."
      );
    }
  }

  function underwrite(uint _policyId, uint[6] _statistics, bytes _proof) internal {
    var (, premium) = HG_DB.getCustomerPremium(_policyId); // throws if _policyId invalid
    bytes32 riskId = HG_DB.getRiskId(_policyId);

    var (, premiumMultiplier) = HG_DB.getPremiumFactors(riskId);
    var (, , arrivalTime) = HG_DB.getRiskParameters(riskId);

    // we calculate the factors to limit cluster risks.
    if (premiumMultiplier == 0) {
      // it's the first call, we accept any premium
      HG_DB.setPremiumFactors(riskId, premium * 100000, 100000);
    }

    HG_DB.setState(
      _policyId,
      policyState.Accepted,
      now,
      "Policy underwritten by oracle"
    );

    LogPolicyAccepted(
      _policyId,
      _statistics[0],
      _statistics[1],
      _statistics[2],
      _statistics[3],
      _statistics[4],
      _statistics[5]
    );
  }
}
