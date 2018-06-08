/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description Database contract
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock, Stephan Karpischek
 *
 * HurricaneGuard with Underwriting and Payout
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */


pragma solidity ^0.4.11;


import "./HurricaneGuardControlledContract.sol";
import "./HurricaneGuardDatabaseInterface.sol";
import "./HurricaneGuardAccessControllerInterface.sol";
import "./HurricaneGuardConstants.sol";

contract HurricaneGuardDatabase is HurricaneGuardControlledContract, HurricaneGuardDatabaseInterface, HurricaneGuardConstants {
  // Table of policies
  Policy[] public policies;

  mapping (bytes32 => uint[]) public extCustomerPolicies;

  mapping (address => Customer) public customers;

  // Lookup policyIds from customer addresses
  mapping (address => uint[]) public customerPolicies;

  // Lookup policy Ids from queryIds
  mapping (bytes32 => OraclizeCallback) public oraclizeCallbacks;

  // Lookup risks from risk IDs
  mapping (bytes32 => Risk) public risks;

  // Lookup AccessControl
  mapping(address => mapping(address => mapping(uint8 => bool))) public accessControl;

  // Lookup accounts of internal ledger
  int[6] public ledger;

  HurricaneGuardAccessControllerInterface HG_AC;

  function HurricaneGuardDatabase (address _controller) {
    setController(_controller);
  }

  function setContracts() onlyController {
    HG_AC = HurricaneGuardAccessControllerInterface(getContract("HG.AccessController"));

    HG_AC.setPermissionById(101, "HG.NewPolicy");
    HG_AC.setPermissionById(101, "HG.Underwrite");

    HG_AC.setPermissionById(101, "HG.Payout");
    HG_AC.setPermissionById(101, "HG.Ledger");
  }

  // Getter and Setter for AccessControl
  function setAccessControl(
    address _contract,
    address _caller,
    uint8 _perm,
    bool _access
  ) {
    // one and only hardcoded accessControl
    require(msg.sender == HG_CI.getContract("HG.AccessController"));
    accessControl[_contract][_caller][_perm] = _access;
  }

  function setAccessControl(address _contract, address _caller, uint8 _perm) {
    setAccessControl(
      _contract,
      _caller,
      _perm,
      true
    );
  }

  function getAccessControl(address _contract, address _caller, uint8 _perm) returns (bool _allowed) {
    _allowed = accessControl[_contract][_caller][_perm];
  }

  // Getter and Setter for ledger
  function setLedger(uint8 _index, int _value) {
    require(HG_AC.checkPermission(101, msg.sender));

    int previous = ledger[_index];
    ledger[_index] += _value;

    // check for int overflow
    if (_value < 0) {
      assert(ledger[_index] < previous);
    } else if (_value > 0) {
      assert(ledger[_index] > previous);
    }
  }

  function getLedger(uint8 _index) returns (int _value) {
    _value = ledger[_index];
  }

  // Getter and Setter for policies
  function getCustomerPremium(uint _policyId) returns (address _customer, uint _premium) {
    Policy storage p = policies[_policyId];
    _customer = p.customer;
    _premium = p.premium;
  }

  function getPolicyData(uint _policyId) returns (address _customer, uint _weight, uint _premium, bytes32 _latlng) {
    Policy storage p = policies[_policyId];
    _customer = p.customer;
    _weight = p.weight;
    _premium = p.premium;
    _latlng = p.latlng;
  }

  function getPolicyState(uint _policyId) returns (policyState _state) {
    Policy storage p = policies[_policyId];
    _state = p.state;
  }

  function getRiskId(uint _policyId) returns (bytes32 _riskId) {
    Policy storage p = policies[_policyId];
    _riskId = p.riskId;
  }

  function createPolicy(address _customer, uint _premium, Currency _currency, bytes32 _customerExternalId, bytes32 _riskId, bytes32 _latlng) returns (uint _policyId) {
    require(HG_AC.checkPermission(101, msg.sender));

    _policyId = policies.length++;

    customerPolicies[_customer].push(_policyId);
    extCustomerPolicies[_customerExternalId].push(_policyId);

    Policy storage p = policies[_policyId];

    p.customer = _customer;
    p.currency = _currency;
    p.customerExternalId = _customerExternalId;
    p.premium = _premium;
    p.riskId = _riskId;
    p.latlng = _latlng;
  }

  function setState(
    uint _policyId,
    policyState _state,
    uint _stateTime,
    bytes32 _stateMessage
  ) {
    require(HG_AC.checkPermission(101, msg.sender));

    LogSetState(
      _policyId,
      uint8(_state),
      _stateTime,
      _stateMessage
    );

    Policy storage p = policies[_policyId];

    p.state = _state;
    p.stateTime = _stateTime;
    p.stateMessage = _stateMessage;
  }

  function setWeight(uint _policyId, uint _weight, bytes _proof) {
    require(HG_AC.checkPermission(101, msg.sender));

    Policy storage p = policies[_policyId];

    p.weight = _weight;
    p.proof = _proof;
  }

  function setPayouts(uint _policyId, uint _calculatedPayout, uint _actualPayout) {
    require(HG_AC.checkPermission(101, msg.sender));

    Policy storage p = policies[_policyId];

    p.calculatedPayout = _calculatedPayout;
    p.actualPayout = _actualPayout;
  }

  function setHurricaneCategory(uint _policyId, bytes32 _category) {
    require(HG_AC.checkPermission(101, msg.sender));

    Risk storage r = risks[policies[_policyId].riskId];

    r.category = _category;
  }

  // Getter and Setter for risks
  function getRiskParameters(bytes32 _riskId) returns (bytes32 _market, bytes32 _season) {
    Risk storage r = risks[_riskId];
    _market = r.market;
    _season = r.season;
  }

  function getPremiumFactors(bytes32 _riskId) returns (uint _cumulatedWeightedPremium, uint _premiumMultiplier) {
    Risk storage r = risks[_riskId];
    _cumulatedWeightedPremium = r.cumulatedWeightedPremium;
    _premiumMultiplier = r.premiumMultiplier;
  }

  function createUpdateRisk(bytes32 _market, bytes32 _season) returns (bytes32 _riskId) {
    require(HG_AC.checkPermission(101, msg.sender));

    _riskId = keccak256(
      _market,
      _season
    );

    Risk storage r = risks[_riskId];

    if (r.premiumMultiplier == 0) {
      r.market = _market;
      r.season = _season;
    }
  }

  function setPremiumFactors(bytes32 _riskId, uint _cumulatedWeightedPremium, uint _premiumMultiplier) {
    require(HG_AC.checkPermission(101, msg.sender));

    Risk storage r = risks[_riskId];
    r.cumulatedWeightedPremium = _cumulatedWeightedPremium;
    r.premiumMultiplier = _premiumMultiplier;
  }

  // Getter and Setter for oraclizeCallbacks
  function getOraclizeCallback(bytes32 _queryId) returns (uint _policyId) {
    _policyId = oraclizeCallbacks[_queryId].policyId;
  }

  function getOraclizePolicyId(bytes32 _queryId) returns (uint _policyId) {
    OraclizeCallback storage o = oraclizeCallbacks[_queryId];
    _policyId = o.policyId;
  }

  function createOraclizeCallback(
    bytes32 _queryId,
    uint _policyId,
    oraclizeState _oraclizeState
  ) {
    require(HG_AC.checkPermission(101, msg.sender));

    oraclizeCallbacks[_queryId] = OraclizeCallback(_policyId, _oraclizeState);
  }
}
