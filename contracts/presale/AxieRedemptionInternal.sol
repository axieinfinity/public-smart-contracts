pragma solidity ^0.4.19;


import "zeppelin/contracts/lifecycle/Pausable.sol";
import "zeppelin/contracts/math/SafeMath.sol";
import "zeppelin/contracts/ownership/HasNoContracts.sol";

import "../core/AxieCore.sol";
import "./AxiePresaleExtended.sol";


contract AxieRedemptionInternal is HasNoContracts, Pausable {
  using SafeMath for uint256;

  uint8 constant public CLASS_BEAST = 0;
  uint8 constant public CLASS_BUG = 1;
  uint8 constant public CLASS_BIRD = 2;
  uint8 constant public CLASS_PLANT = 3;
  uint8 constant public CLASS_AQUATIC = 4;
  uint8 constant public CLASS_REPTILE = 5;

  struct Redemption {
    address receiver;
    uint256 clazz;
    uint256 redeemedAt;
  }

  AxieCore public coreContract;
  AxiePresaleExtended public presaleContract;

  mapping (uint256 => Redemption) public redemptionByQueryId;
  mapping (address => mapping (uint256 => uint256[])) public ownedRedemptions;
  mapping (uint256 => uint256) public ownedRedemptionIndex;

  event RedemptionStarted(uint256 indexed _queryId);
  event RedemptionRetried(uint256 indexed _queryId, uint256 indexed _oldQueryId);
  event RedemptionFinished(uint256 indexed _queryId);

  function () external payable {
    require(msg.sender == owner);
  }

  modifier requireDependencyContracts {
    require(coreContract != address(0) && presaleContract != address(0));
    _;
  }

  modifier whenStarted {
    require(now >= _startTimestamp());
    _;
  }

  function reclaimEther(uint256 remaining) external onlyOwner {
    if (this.balance > remaining) {
      owner.transfer(this.balance - remaining);
    }
  }

  function setCoreContract(address _coreAddress) external onlyOwner {
    coreContract = AxieCore(_coreAddress);
  }

  function setPresaleContract(address _presaleAddress) external onlyOwner {
    presaleContract = AxiePresaleExtended(_presaleAddress);
  }

  function numBeingRedeemedAxies(address _receiver, uint256 _class) external view returns (uint256) {
    return ownedRedemptions[_receiver][_class].length;
  }

  function redeemAdoptedAxies(
    uint256 _oldClass
  )
    external
    requireDependencyContracts
    whenStarted
    whenNotPaused
  {
    _redeemAdoptedAxies(msg.sender, _oldClass);
  }

  function redeemPlayersAdoptedAxies(
    address _receiver,
    uint256 _oldClass
  )
    external
    requireDependencyContracts
    onlyOwner
    whenStarted
  {
    _redeemAdoptedAxies(_receiver, _oldClass);
  }

  function redeemRewardedAxies()
    external
    requireDependencyContracts
    whenStarted
    whenNotPaused
  {
    _redeemRewardedAxies(msg.sender);
  }

  function redeemPlayersRewardedAxies(
    address _receiver
  )
    external
    requireDependencyContracts
    onlyOwner
    whenStarted
  {
    _redeemRewardedAxies(_receiver);
  }

  function retryRedemption(
    uint256 _oldQueryId,
    uint256 _gasLimit
  )
    external
    requireDependencyContracts
    onlyOwner
    whenStarted
  {
    Redemption memory _redemption = redemptionByQueryId[_oldQueryId];
    require(_redemption.receiver != address(0));

    uint256 _redemptionIndex = ownedRedemptionIndex[_oldQueryId];
    uint256 _queryId = _sendRandomQuery(_gasLimit);

    redemptionByQueryId[_queryId] = _redemption;
    delete redemptionByQueryId[_oldQueryId];

    ownedRedemptions[_redemption.receiver][_redemption.clazz][_redemptionIndex] = _queryId;
    ownedRedemptionIndex[_queryId] = _redemptionIndex;
    delete ownedRedemptionIndex[_oldQueryId];

    RedemptionRetried(_queryId, _oldQueryId);
  }

  function _startTimestamp() internal returns (uint256);

  function _sendRandomQuery(uint256 _gasLimit) internal returns (uint256);

  function _receiveRandomQuery(
    uint256 _queryId,
    string _result
  )
    internal
    whenStarted
    whenNotPaused
  {
    Redemption memory _redemption = redemptionByQueryId[_queryId];
    require(_redemption.receiver != address(0));

    uint256 _redemptionIndex = ownedRedemptionIndex[_queryId];
    uint256 _lastRedemptionIndex = ownedRedemptions[_redemption.receiver][_redemption.clazz].length.sub(1);
    uint256 _lastRedemptionQueryId = ownedRedemptions[_redemption.receiver][_redemption.clazz][_lastRedemptionIndex];

    uint256 _seed = uint256(keccak256(_result));
    uint256 _genes;

    if (_redemption.clazz != uint256(-1)) {
      _genes = _generateGenes(_redemption.clazz, _seed);
    } else {
      _genes = _generateGenes(_seed);
    }

    ownedRedemptions[_redemption.receiver][_redemption.clazz][_redemptionIndex] = _lastRedemptionQueryId;
    ownedRedemptionIndex[_lastRedemptionQueryId] = _redemptionIndex;

    delete ownedRedemptions[_redemption.receiver][_redemption.clazz][_lastRedemptionIndex];
    ownedRedemptions[_redemption.receiver][_redemption.clazz].length--;

    delete redemptionByQueryId[_queryId];
    delete ownedRedemptionIndex[_queryId];

    // Spawn an Axie with the generated `genes`.
    coreContract.spawnAxie(_genes, _redemption.receiver);

    RedemptionFinished(_queryId);
  }

  function _randomNumber(
    uint256 _upper,
    uint256 _initialSeed
  )
    private
    view
    returns (uint256 _number, uint256 _seed)
  {
    _seed = uint256(
      keccak256(
        _initialSeed,
        block.blockhash(block.number - 1),
        block.coinbase,
        block.difficulty
      )
    );

    _number = _seed % _upper;
  }

  function _randomClass(uint256 _initialSeed) private view returns (uint256 _class, uint256 _seed) {
    // solium-disable-next-line comma-whitespace
    (_class, _seed) = _randomNumber(6 /* CLASS_REPTILE + 1 */, _initialSeed);
  }

  function _generateGenes(uint256 _class, uint256 _initialSeed) private view returns (uint256) {
    // Gene generation logic is removed.
    return 0;
  }

  function _generateGenes(uint256 _initialSeed) private view returns (uint256) {
    uint256 _class;
    uint256 _seed;
    (_class, _seed) = _randomClass(_initialSeed);
    return _generateGenes(_class, _seed);
  }

  function _redeemAxies(address _receiver, uint256 _class) private {
    uint256 _queryId = _sendRandomQuery(300000);

    Redemption memory _redemption = Redemption(
      _receiver,
      _class,
      now
    );

    redemptionByQueryId[_queryId] = _redemption;

    uint256 _length = ownedRedemptions[_receiver][_class].length;
    ownedRedemptions[_receiver][_class].push(_queryId);
    ownedRedemptionIndex[_queryId] = _length;

    RedemptionStarted(_queryId);
  }

  function _redeemAdoptedAxies(address _receiver, uint256 _oldClass) private {
    uint256 _class;

    if (_oldClass == 0) { // Old Beast
      presaleContract.redeemAdoptedAxies(_receiver, 1, 0, 0);
      _class = CLASS_BEAST;
    } else if (_oldClass == 2) { // Old Aquatic
      presaleContract.redeemAdoptedAxies(_receiver, 0, 1, 0);
      _class = CLASS_AQUATIC;
    } else if (_oldClass == 4) { // Old Plant
      presaleContract.redeemAdoptedAxies(_receiver, 0, 0, 1);
      _class = CLASS_PLANT;
    } else {
      revert();
    }

    _redeemAxies(_receiver, _class);
  }

  function _redeemRewardedAxies(address _receiver) private {
    presaleContract.redeemRewardedAxies(_receiver, 1);
    _redeemAxies(_receiver, uint256(-1));
  }
}
