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


import "./HurricaneResponseControlledContract.sol";
import "./HurricaneResponseConstants.sol";
import "./HurricaneResponseDatabaseInterface.sol";
import "./HurricaneResponseAccessControllerInterface.sol";
import "./HurricaneResponseLedgerInterface.sol";
import "./HurricaneResponseUnderwriteInterface.sol";
import "./HurricaneResponsePayoutInterface.sol";
import "./HurricaneResponseOraclizeInterface.sol";
import "./convertLib.sol";
import "./../vendors/strings.sol";

contract HurricaneResponseUnderwrite is HurricaneResponseControlledContract, HurricaneResponseConstants, HurricaneResponseOraclizeInterface, ConvertLib {
  using strings for *;

  HurricaneResponseDatabaseInterface HR_DB;
  HurricaneResponseLedgerInterface HR_LG;
  HurricaneResponsePayoutInterface HR_PY;
  HurricaneResponseAccessControllerInterface HR_AC;

  function HurricaneResponseUnderwrite(address _controller) {
    setController(_controller);
    oraclize_setProof(proofType_TLSNotary);
  }

  function setContracts() onlyController {
    HR_AC = HurricaneResponseAccessControllerInterface(getContract("HR.AccessController"));
    HR_DB = HurricaneResponseDatabaseInterface(getContract("HR.Database"));
    HR_LG = HurricaneResponseLedgerInterface(getContract("HR.Ledger"));
    HR_PY = HurricaneResponsePayoutInterface(getContract("HR.Payout"));

    HR_AC.setPermissionById(101, "HR.NewPolicy");
    HR_AC.setPermissionById(102, "HR.Funder");
  }

  /*
   * @dev Fund contract
   */
  function fund() payable {
    require(HR_AC.checkPermission(102, msg.sender));

    // todo: bookkeeping
    // todo: fire funding event
  }

  function scheduleUnderwriteOraclizeCall(uint _policyId, bytes32 _latlng) {
    require(HR_AC.checkPermission(101, msg.sender));

    string memory oraclizeUrl = strConcat(
      ORACLIZE_RATINGS_BASE_URL,
      /* b32toString(_latlng), */
      "TJSJ",
      ORACLIZE_RATINGS_QUERY
    );

    bytes32 queryId = oraclize_query("URL", oraclizeUrl, ORACLIZE_GAS);

    // call oraclize to get Flight Stats; this will also call underwrite()
    HR_DB.createOraclizeCallback(
      queryId,
      _policyId,
      oraclizeState.ForUnderwriting
    );

    LogOraclizeCall(_policyId, queryId, oraclizeUrl);
  }

  function __callback(bytes32 _queryId, string _result, bytes _proof) onlyOraclizeOr(getContract('HR.Emergency')) {
    var (policyId,) = HR_DB.getOraclizeCallback(_queryId);
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
    require(msg.sender == HR_CI.getContract("HR.CustomersAdmin"));

    LogPolicyDeclined(_policyId, _reason);

    HR_DB.setState(
      _policyId,
      policyState.Declined,
      now,
      _reason
    );

    HR_DB.setWeight(_policyId, 0, "");

    var (customer, premium) = HR_DB.getCustomerPremium(_policyId);

    if (!HR_LG.sendFunds(customer, Acc.Premium, premium)) {
      HR_DB.setState(
        _policyId,
        policyState.SendFailed,
        now,
        "decline: Send failed."
      );
    }
  }

  function decline(uint _policyId, bytes32 _reason, bytes _proof)	internal {
    LogPolicyDeclined(_policyId, _reason);

    HR_DB.setState(
      _policyId,
      policyState.Declined,
      now,
      _reason
    );

    HR_DB.setWeight(_policyId, 0, _proof);

    var (customer, premium) = HR_DB.getCustomerPremium(_policyId);

    // TODO: LOG
    if (!HR_LG.sendFunds(customer, Acc.Premium, premium)) {
      HR_DB.setState(
        _policyId,
        policyState.SendFailed,
        now,
        "decline: Send failed."
      );
    }
  }

  function underwrite(uint _policyId, uint[6] _statistics, bytes _proof) internal {
    var (, premium) = HR_DB.getCustomerPremium(_policyId); // throws if _policyId invalid
    bytes32 riskId = HR_DB.getRiskId(_policyId);

    var (, premiumMultiplier) = HR_DB.getPremiumFactors(riskId);
    var (, , arrivalTime) = HR_DB.getRiskParameters(riskId);

    // we calculate the factors to limit cluster risks.
    if (premiumMultiplier == 0) {
      // it's the first call, we accept any premium
      HR_DB.setPremiumFactors(riskId, premium * 100000, 100000);
    }

    HR_DB.setState(
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
