pragma solidity ^0.4.19;


import "zeppelin/contracts/lifecycle/Pausable.sol";
import "zeppelin/contracts/math/SafeMath.sol";
import "zeppelin/contracts/ownership/HasNoContracts.sol";

import "./AxiePresale.sol";


contract AxiePresaleExtended is HasNoContracts, Pausable {
  using SafeMath for uint256;

  // No Axies can be adopted after this end date: Monday, April 16, 2018 11:59:59 PM GMT.
  uint256 constant public PRESALE_END_TIMESTAMP = 1523923199;

  // The total number of adopted Axies will be capped at 5250,
  // so the number of Axies which have Mystic parts will be capped roughly at 2000.
  uint256 constant public MAX_TOTAL_ADOPTED_AXIES = 5250;

  uint8 constant public CLASS_BEAST = 0;
  uint8 constant public CLASS_AQUATIC = 2;
  uint8 constant public CLASS_PLANT = 4;

  // The initial price increment and the initial price are for reference only
  uint256 constant public INITIAL_PRICE_INCREMENT = 1600 szabo; // 0.0016 Ether
  uint256 constant public INITIAL_PRICE = INITIAL_PRICE_INCREMENT;

  uint256 constant public REF_CREDITS_PER_AXIE = 5;

  AxiePresale public presaleContract;
  address public redemptionAddress;

  mapping (uint8 => uint256) public currentPrice;
  mapping (uint8 => uint256) public priceIncrement;

  mapping (uint8 => uint256) private _totalAdoptedAxies;
  mapping (uint8 => uint256) private _totalDeductedAdoptedAxies;
  mapping (address => mapping (uint8 => uint256)) private _numAdoptedAxies;
  mapping (address => mapping (uint8 => uint256)) private _numDeductedAdoptedAxies;

  mapping (address => uint256) private _numRefCredits;
  mapping (address => uint256) private _numDeductedRefCredits;
  uint256 public numBountyCredits;

  uint256 private _totalRewardedAxies;
  uint256 private _totalDeductedRewardedAxies;
  mapping (address => uint256) private _numRewardedAxies;
  mapping (address => uint256) private _numDeductedRewardedAxies;

  event AxiesAdopted(
    address indexed _adopter,
    uint8 indexed _class,
    uint256 _quantity,
    address indexed _referrer
  );

  event AxiesRewarded(address indexed _receiver, uint256 _quantity);

  event AdoptedAxiesRedeemed(address indexed _receiver, uint8 indexed _class, uint256 _quantity);
  event RewardedAxiesRedeemed(address indexed _receiver, uint256 _quantity);

  event RefCreditsMinted(address indexed _receiver, uint256 _numMintedCredits);

  function AxiePresaleExtended() public payable {
    require(msg.value == 0);
    paused = true;
    numBountyCredits = 300;
  }

  function () external payable {
    require(msg.sender == address(presaleContract));
  }

  modifier whenNotInitialized {
    require(presaleContract == address(0));
    _;
  }

  modifier whenInitialized {
    require(presaleContract != address(0));
    _;
  }

  modifier onlyRedemptionAddress {
    require(msg.sender == redemptionAddress);
    _;
  }

  function reclaimEther() external onlyOwner whenInitialized {
    presaleContract.reclaimEther();
    owner.transfer(this.balance);
  }

  /**
   * @dev This must be called only once after the owner of the presale contract
   *  has been updated to this contract.
   */
  function initialize(address _presaleAddress) external onlyOwner whenNotInitialized {
    // Set the presale address.
    presaleContract = AxiePresale(_presaleAddress);

    presaleContract.pause();

    // Restore price increments from the old contract.
    priceIncrement[CLASS_BEAST] = presaleContract.priceIncrements(CLASS_BEAST);
    priceIncrement[CLASS_AQUATIC] = presaleContract.priceIncrements(CLASS_AQUATIC);
    priceIncrement[CLASS_PLANT] = presaleContract.priceIncrements(CLASS_PLANT);

    // Restore current prices from the old contract.
    currentPrice[CLASS_BEAST] = presaleContract.currentPrices(CLASS_BEAST);
    currentPrice[CLASS_AQUATIC] = presaleContract.currentPrices(CLASS_AQUATIC);
    currentPrice[CLASS_PLANT] = presaleContract.currentPrices(CLASS_PLANT);

    paused = false;
  }

  function setRedemptionAddress(address _redemptionAddress) external onlyOwner whenInitialized {
    redemptionAddress = _redemptionAddress;
  }

  function totalAdoptedAxies(
    uint8 _class,
    bool _deduction
  )
    external
    view
    whenInitialized
    returns (uint256 _number)
  {
    _number = _totalAdoptedAxies[_class]
      .add(presaleContract.totalAxiesAdopted(_class));

    if (_deduction) {
      _number = _number.sub(_totalDeductedAdoptedAxies[_class]);
    }
  }

  function numAdoptedAxies(
    address _owner,
    uint8 _class,
    bool _deduction
  )
    external
    view
    whenInitialized
    returns (uint256 _number)
  {
    _number = _numAdoptedAxies[_owner][_class]
      .add(presaleContract.axiesAdopted(_owner, _class));

    if (_deduction) {
      _number = _number.sub(_numDeductedAdoptedAxies[_owner][_class]);
    }
  }

  function numRefCredits(
    address _owner,
    bool _deduction
  )
    external
    view
    whenInitialized
    returns (uint256 _number)
  {
    _number = _numRefCredits[_owner]
      .add(presaleContract.referralCredits(_owner));

    if (_deduction) {
      _number = _number.sub(_numDeductedRefCredits[_owner]);
    }
  }

  function totalRewardedAxies(
    bool _deduction
  )
    external
    view
    whenInitialized
    returns (uint256 _number)
  {
    _number = _totalRewardedAxies
      .add(presaleContract.totalAxiesRewarded());

    if (_deduction) {
      _number = _number.sub(_totalDeductedRewardedAxies);
    }
  }

  function numRewardedAxies(
    address _owner,
    bool _deduction
  )
    external
    view
    whenInitialized
    returns (uint256 _number)
  {
    _number = _numRewardedAxies[_owner]
      .add(presaleContract.axiesRewarded(_owner));

    if (_deduction) {
      _number = _number.sub(_numDeductedRewardedAxies[_owner]);
    }
  }

  function axiesPrice(
    uint256 _beastQuantity,
    uint256 _aquaticQuantity,
    uint256 _plantQuantity
  )
    external
    view
    whenInitialized
    returns (uint256 _totalPrice)
  {
    uint256 price;

    (price,,) = _sameClassAxiesPrice(CLASS_BEAST, _beastQuantity);
    _totalPrice = _totalPrice.add(price);

    (price,,) = _sameClassAxiesPrice(CLASS_AQUATIC, _aquaticQuantity);
    _totalPrice = _totalPrice.add(price);

    (price,,) = _sameClassAxiesPrice(CLASS_PLANT, _plantQuantity);
    _totalPrice = _totalPrice.add(price);
  }

  function adoptAxies(
    uint256 _beastQuantity,
    uint256 _aquaticQuantity,
    uint256 _plantQuantity,
    address _referrer
  )
    external
    payable
    whenInitialized
    whenNotPaused
  {
    require(now <= PRESALE_END_TIMESTAMP);
    require(_beastQuantity <= 3 && _aquaticQuantity <= 3 && _plantQuantity <= 3);

    uint256 _totalAdopted = this.totalAdoptedAxies(CLASS_BEAST, false)
      .add(this.totalAdoptedAxies(CLASS_AQUATIC, false))
      .add(this.totalAdoptedAxies(CLASS_PLANT, false))
      .add(_beastQuantity)
      .add(_aquaticQuantity)
      .add(_plantQuantity);

    require(_totalAdopted <= MAX_TOTAL_ADOPTED_AXIES);

    address _adopter = msg.sender;
    address _actualReferrer = 0x0;

    // An adopter cannot be his/her own referrer.
    if (_referrer != _adopter) {
      _actualReferrer = _referrer;
    }

    uint256 _value = msg.value;
    uint256 _price;

    if (_beastQuantity > 0) {
      _price = _adoptSameClassAxies(
        _adopter,
        CLASS_BEAST,
        _beastQuantity,
        _actualReferrer
      );

      require(_value >= _price);
      _value -= _price;
    }

    if (_aquaticQuantity > 0) {
      _price = _adoptSameClassAxies(
        _adopter,
        CLASS_AQUATIC,
        _aquaticQuantity,
        _actualReferrer
      );

      require(_value >= _price);
      _value -= _price;
    }

    if (_plantQuantity > 0) {
      _price = _adoptSameClassAxies(
        _adopter,
        CLASS_PLANT,
        _plantQuantity,
        _actualReferrer
      );

      require(_value >= _price);
      _value -= _price;
    }

    msg.sender.transfer(_value);

    // The current referral is ignored if the referrer's address is 0x0.
    if (_actualReferrer != 0x0) {
      _applyRefCredits(
        _actualReferrer,
        _beastQuantity.add(_aquaticQuantity).add(_plantQuantity)
      );
    }
  }

  function mintRefCredits(
    address _receiver,
    uint256 _numMintedCredits
  )
    external
    onlyOwner
    whenInitialized
    returns (uint256)
  {
    require(_receiver != address(0));
    numBountyCredits = numBountyCredits.sub(_numMintedCredits);
    _applyRefCredits(_receiver, _numMintedCredits);
    RefCreditsMinted(_receiver, _numMintedCredits);
    return numBountyCredits;
  }

  function redeemAdoptedAxies(
    address _receiver,
    uint256 _beastQuantity,
    uint256 _aquaticQuantity,
    uint256 _plantQuantity
  )
    external
    onlyRedemptionAddress
    whenInitialized
    returns (
      uint256 /* remainingBeastQuantity */,
      uint256 /* remainingAquaticQuantity */,
      uint256 /* remainingPlantQuantity */
    )
  {
    return (
      _redeemSameClassAdoptedAxies(_receiver, CLASS_BEAST, _beastQuantity),
      _redeemSameClassAdoptedAxies(_receiver, CLASS_AQUATIC, _aquaticQuantity),
      _redeemSameClassAdoptedAxies(_receiver, CLASS_PLANT, _plantQuantity)
    );
  }

  function redeemRewardedAxies(
    address _receiver,
    uint256 _quantity
  )
    external
    onlyRedemptionAddress
    whenInitialized
    returns (uint256 _remainingQuantity)
  {
    _remainingQuantity = this.numRewardedAxies(_receiver, true).sub(_quantity);

    if (_quantity > 0) {
      _numDeductedRewardedAxies[_receiver] = _numDeductedRewardedAxies[_receiver].add(_quantity);
      _totalDeductedRewardedAxies = _totalDeductedRewardedAxies.add(_quantity);

      RewardedAxiesRedeemed(_receiver, _quantity);
    }
  }

  /**
   * @notice Calculate price of Axies from the same class.
   * @param _class The class of Axies.
   * @param _quantity Number of Axies to be calculated.
   */
  function _sameClassAxiesPrice(
    uint8 _class,
    uint256 _quantity
  )
    private
    view
    returns (
      uint256 _totalPrice,
      uint256 /* should be _subsequentIncrement */ _currentIncrement,
      uint256 /* should be _subsequentPrice */ _currentPrice
    )
  {
    _currentIncrement = priceIncrement[_class];
    _currentPrice = currentPrice[_class];

    uint256 _nextPrice;

    for (uint256 i = 0; i < _quantity; i++) {
      _totalPrice = _totalPrice.add(_currentPrice);
      _nextPrice = _currentPrice.add(_currentIncrement);

      if (_nextPrice / 100 finney != _currentPrice / 100 finney) {
        _currentIncrement >>= 1;
      }

      _currentPrice = _nextPrice;
    }
  }

  /**
   * @notice Adopt some Axies from the same class.
   * @dev The quantity MUST be positive.
   * @param _adopter Address of the adopter.
   * @param _class The class of adopted Axies.
   * @param _quantity Number of Axies to be adopted.
   * @param _referrer Address of the referrer.
   */
  function _adoptSameClassAxies(
    address _adopter,
    uint8 _class,
    uint256 _quantity,
    address _referrer
  )
    private
    returns (uint256 _totalPrice)
  {
    (_totalPrice, priceIncrement[_class], currentPrice[_class]) = _sameClassAxiesPrice(_class, _quantity);

    _numAdoptedAxies[_adopter][_class] = _numAdoptedAxies[_adopter][_class].add(_quantity);
    _totalAdoptedAxies[_class] = _totalAdoptedAxies[_class].add(_quantity);

    AxiesAdopted(
      _adopter,
      _class,
      _quantity,
      _referrer
    );
  }

  function _applyRefCredits(address _receiver, uint256 _numAppliedCredits) private {
    _numRefCredits[_receiver] = _numRefCredits[_receiver].add(_numAppliedCredits);

    uint256 _numCredits = this.numRefCredits(_receiver, true);
    uint256 _numRewards = _numCredits / REF_CREDITS_PER_AXIE;

    if (_numRewards > 0) {
      _numDeductedRefCredits[_receiver] = _numDeductedRefCredits[_receiver]
        .add(_numRewards.mul(REF_CREDITS_PER_AXIE));

      _numRewardedAxies[_receiver] = _numRewardedAxies[_receiver].add(_numRewards);
      _totalRewardedAxies = _totalRewardedAxies.add(_numRewards);

      AxiesRewarded(_receiver, _numRewards);
    }
  }

  /**
   * @notice Redeem adopted Axies from the same class.
   * @dev Emit the `AdoptedAxiesRedeemed` event if the quantity is positive.
   * @param _receiver The address of the receiver.
   * @param _class The class of adopted Axies.
   * @param _quantity The number of adopted Axies to be redeemed.
   */
  function _redeemSameClassAdoptedAxies(
    address _receiver,
    uint8 _class,
    uint256 _quantity
  )
    private
    returns (uint256 _remainingQuantity)
  {
    _remainingQuantity = this.numAdoptedAxies(_receiver, _class, true).sub(_quantity);

    if (_quantity > 0) {
      _numDeductedAdoptedAxies[_receiver][_class] = _numDeductedAdoptedAxies[_receiver][_class].add(_quantity);
      _totalDeductedAdoptedAxies[_class] = _totalDeductedAdoptedAxies[_class].add(_quantity);

      AdoptedAxiesRedeemed(_receiver, _class, _quantity);
    }
  }
}
