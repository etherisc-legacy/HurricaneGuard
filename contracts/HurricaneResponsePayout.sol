/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Payout contract
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
import "./HurricaneResponsePayoutInterface.sol";
import "./HurricaneResponseOraclizeInterface.sol";
import "./convertLib.sol";
import "./../vendors/strings.sol";

contract HurricaneResponsePayout is HurricaneResponseControlledContract, HurricaneResponseConstants, HurricaneResponseOraclizeInterface, ConvertLib {
  using strings for *;

  HurricaneResponseDatabaseInterface HR_DB;
  HurricaneResponseLedgerInterface HR_LG;
  HurricaneResponseAccessControllerInterface HR_AC;

  /*
   * @dev Contract constructor sets its controller
   * @param _controller FD.Controller
   */
  function HurricaneResponsePayout(address _controller) {
    setController(_controller);
  }

  /*
   * Public methods
   */

  /*
   * @dev Set access permissions for methods
   */
  function setContracts() public onlyController {
    HR_AC = HurricaneResponseAccessControllerInterface(getContract("HR.AccessController"));
    HR_DB = HurricaneResponseDatabaseInterface(getContract("HR.Database"));
    HR_LG = HurricaneResponseLedgerInterface(getContract("HR.Ledger"));

    HR_AC.setPermissionById(101, "HR.Underwrite");
    HR_AC.setPermissionByAddress(101, oraclize_cbAddress());
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

  /*
   * @dev Schedule oraclize call for payout
   * @param _policyId
   * @param _riskId
   * @param _oraclizeTime
   */
  function schedulePayoutOraclizeCall(uint _policyId, bytes32 _riskId) public {
    require(HR_AC.checkPermission(101, msg.sender));

    var (market, season) = HR_DB.getRiskParameters(_riskId);

    string memory oraclizeUrl = strConcat(
      /* ORACLIZE_STATUS_BASE_URL, */
      b32toString(market),
      b32toString(season)
      /* ORACLIZE_STATUS_QUERY */
    );

    bytes32 queryId = oraclize_query("URL", oraclizeUrl, ORACLIZE_GAS);

    HR_DB.createOraclizeCallback(
      queryId,
      _policyId,
      oraclizeState.ForPayout
    );

    LogOraclizeCall(_policyId, queryId, oraclizeUrl);
  }

  /*
   * @dev Oraclize callback. In an emergency case, we can call this directly from FD.Emergency Account.
   * @param _queryId
   * @param _result
   * @param _proof
   */
  function __callback(bytes32 _queryId, string _result, bytes _proof) public onlyOraclizeOr(getContract('HR.Emergency')) {
    var (policyId) = HR_DB.getOraclizeCallback(_queryId);
    LogOraclizeCallback(policyId, _queryId, _result, _proof);

    // check if policy was declined after this callback was scheduled
    var state = HR_DB.getPolicyState(policyId);
    require(uint8(state) != 5);

    bytes32 riskId = HR_DB.getRiskId(policyId);

    /* LogPolicyManualPayout(policyId, "No Callback at +120 min"); */

    ///////
    payOut(policyId, 0);
    /* if (delayInMinutes < 15) {
      payOut(policyId, 0, 0);
    } else if (delayInMinutes < 30) {
      payOut(policyId, 1, delayInMinutes);
    } else if (delayInMinutes < 45) {
      payOut(policyId, 2, delayInMinutes);
    } else {
      payOut(policyId, 3, delayInMinutes);
    } */
  }

  /*
   * Internal methods
   */

  /*
   * @dev Payout
   * @param _policyId
   * @param _windSpeed
   */
  function payOut(uint _policyId, uint8 _windSpeed)	internal {
    HR_DB.setWindSpeed(_policyId, _windSpeed);

    if (_windSpeed == 0) {
      HR_DB.setState(
        _policyId,
        policyState.Expired,
        now,
        "Expired - no hurricane event!"
      );
    } else {
      var (customer, weight, premium) = HR_DB.getPolicyData(_policyId);

      // TODO: Implement multiplier table
      uint payout = premium * 30;
      uint calculatedPayout = payout;

      if (payout > MAX_PAYOUT) {
        payout = MAX_PAYOUT;
      }

      HR_DB.setPayouts(_policyId, calculatedPayout, payout);

      if (!HR_LG.sendFunds(customer, Acc.Payout, payout)) {
        HR_DB.setState(
          _policyId,
          policyState.SendFailed,
          now,
          "Payout, send failed!"
        );

        HR_DB.setPayouts(_policyId, calculatedPayout, 0);
      } else {
        HR_DB.setState(
          _policyId,
          policyState.PaidOut,
          now,
          "Payout successful!"
        );
      }
    }
  }
}
