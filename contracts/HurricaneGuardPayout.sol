/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Payout contract
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 *
 * HurricaneGuard with Underwriting and Payout
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */


pragma solidity 0.4.21;


import "./HurricaneGuardControlledContract.sol";
import "./HurricaneGuardConstants.sol";
import "./HurricaneGuardDatabaseInterface.sol";
import "./HurricaneGuardAccessControllerInterface.sol";
import "./HurricaneGuardLedgerInterface.sol";
import "./HurricaneGuardPayoutInterface.sol";
import "./HurricaneGuardOraclizeInterface.sol";
import "./convertLib.sol";
import "./../vendors/strings.sol";


// solhint-disable-next-line max-line-length
contract HurricaneGuardPayout is HurricaneGuardControlledContract, HurricaneGuardConstants, HurricaneGuardOraclizeInterface, ConvertLib {
  using strings for *;

  HurricaneGuardDatabaseInterface internal HG_DB;
  HurricaneGuardLedgerInterface internal HG_LG;
  HurricaneGuardAccessControllerInterface internal HG_AC;

  /*
   * @dev Contract constructor sets its controller
   * @param _controller FD.Controller
   */
  function HurricaneGuardPayout(address _controller) public {
    setController(_controller);
    /* For testnet and mainnet */
    /* oraclize_setProof(proofType_TLSNotary); */
    /* For development */
    OAR = OraclizeAddrResolverI(0xa6EA251E638409159926894544808916A91C6605);
  }

  /*
   * @dev Set access permissions for methods
   */
  function setContracts() public onlyController {
    HG_AC = HurricaneGuardAccessControllerInterface(getContract("HG.AccessController"));
    HG_DB = HurricaneGuardDatabaseInterface(getContract("HG.Database"));
    HG_LG = HurricaneGuardLedgerInterface(getContract("HG.Ledger"));

    // Calling payout function does not depend on Underwrite contract
    // Customer Admin contract should have access to call schedulePayoutOraclizeCall
    // Maybe it makes sense to leave the schedulePayoutOraclizeCall open
    // that way a policy holder could event trigger a policy payout process
    // themselves and don't need to trust keepers to execute payout process
    HG_AC.setPermissionById(101, "HG.CustomersAdmin");
    HG_AC.setPermissionByAddress(101, oraclize_cbAddress());
    HG_AC.setPermissionById(102, "HG.Funder");
  }

  /*
   * @dev Fund contract
   */
  function fund() public payable {
    require(HG_AC.checkPermission(102, msg.sender));

    // todo: bookkeeping
    // todo: fire funding event
  }

  /*
   * @dev Schedule oraclize call for payout
   * @param _policyId
   * @param _riskId
   * @param _oraclizeTime
   */
  function schedulePayoutOraclizeCall(uint _policyId, bytes32 _riskId, uint _oraclizeTime) public {
    // TODO: decide wether a policy holder could trigger their own payout function
    require(HG_AC.checkPermission(101, msg.sender));
    bytes32 season;
    bytes32 latlng;

    (, season) = HG_DB.getRiskParameters(_riskId);
    // Require payout to be in current season
    // TODO: should set policy as expired
    /* require(season == strings.uintToBytes(getYear(block.timestamp))); */

    (, , , latlng) = HG_DB.getPolicyData(_policyId);

    string memory oraclizeUrl = strConcat(
      ORACLIZE_STATUS_BASE_URL, "latlng=", b32toString(latlng), ").result"
    );

    bytes32 queryId = oraclize_query(_oraclizeTime, "URL", oraclizeUrl, ORACLIZE_GAS);

    HG_DB.createOraclizeCallback(
      queryId,
      _policyId,
      OraclizeState.ForPayout
    );

    emit LogOraclizeCall(_policyId, queryId, oraclizeUrl);
  }

  /*
   * @dev Oraclize callback. In an emergency case, we can call this directly from FD.Emergency Account.
   * @param _queryId
   * @param _result
   * @param _proof
   */
  // solhint-disable-next-line max-line-length
  function __callback(bytes32 _queryId, string _result, bytes _proof) public onlyOraclizeOr(getContract("HG.Emergency")) {
    uint policyId;

    (policyId) = HG_DB.getOraclizeCallback(_queryId);
    emit LogOraclizeCallback(policyId, _queryId, _result, _proof);

    // check if policy was declined after this callback was scheduled
    PolicyState state = HG_DB.getPolicyState(policyId);
    require(uint8(state) != 5);

    /* bytes32 riskId = HG_DB.getRiskId(policyId); */

    if (bytes(_result).length == 0) {
      // empty Result
      // could try again to be redundant
      return;
    }

    // _result looks like: "cat5;100"
    // where first part is event Category
    // and second part is distance from event

    strings.slice memory s = _result.toSlice();
    strings.slice memory delim = ";".toSlice();
    var parts = new string[](s.count(delim) + 1);
    for (uint i = 0; i < parts.length; i++) {
      parts[i] = s.split(delim).toString();
    }

    bytes32 category = stringToBytes32(parts[0]);
    uint distance = parseInt(parts[1]);

    payOut(policyId, category, distance);
  }

  /*
   * @dev Payout
   * @param _policyId internal id
   * @param _category the intensity of the event
   * @param _distance the distance from the latlng to the event
   */
  // solhint-disable-next-line code-complexity
  function payOut(uint _policyId, bytes32 _cat, uint _dist) internal {
    // TODO: only setPayoutEvent for the initial trigger
    // this could be a waste of gas
    HG_DB.setHurricaneCategory(_policyId, _cat);

    // Distance is more than 30 miles
    if (_dist > 48281) {
      // is too far, therfore not covered
      HG_DB.setState(_policyId, PolicyState.Expired, now, "Too far for payout"); // solhint-disable-line
    } else {
      address customer;
      uint weight;
      uint premium;

      (customer, weight, premium, ) = HG_DB.getPolicyData(_policyId);

      uint multiplier = 0;
      // 0 - 5 miles
      if (_dist < 8048) {
        if (_cat == "cat3_lower") multiplier = 10;
        if (_cat == "cat4_lower") multiplier = 20;
        if (_cat == "cat5_lower") multiplier = 30;
      }
      // 5 - 15 miles
      if (8048 < _dist && _dist < 24141) {
        // cat3 pays 50% at this distance
        if (_cat == "cat3_lower") multiplier = 5;
        if (_cat == "cat4_lower") multiplier = 20;
        if (_cat == "cat5_lower") multiplier = 30;
      }
      // 15 - 30 miles
      if (24141 < _dist && _dist < 48280) {
        // cat3 pays 20% at this distance
        if (_cat == "cat3_lower") multiplier = 2;
        // cat4 pays 50% at this distance
        if (_cat == "cat4_lower") multiplier = 10;
        // cat5 pays 70% at this distance
        if (_cat == "cat5_lower") multiplier = 21;
      }

      if (multiplier == 0) {
        // No payable event happened for this policy
        HG_DB.setState(
          _policyId,
          PolicyState.Expired,
          now, // solhint-disable-line
          "No covered event for payout"
        );
      } else {
        uint payout = premium * multiplier;
        uint calculatedPayout = payout;

        if (payout > MAX_PAYOUT) {
          payout = MAX_PAYOUT;
        }

        HG_DB.setPayouts(_policyId, calculatedPayout, payout);

        if (!HG_LG.sendFunds(customer, Acc.Payout, payout)) {
          HG_DB.setState(
            _policyId,
            PolicyState.SendFailed,
            now, // solhint-disable-line
            "Payout, send failed!"
          );

          HG_DB.setPayouts(_policyId, calculatedPayout, 0);
        } else {
          HG_DB.setState(
            _policyId,
            PolicyState.PaidOut,
            now, // solhint-disable-line
            "Payout successful!"
          );
        }
      }
    }
  }
}
