pragma solidity ^0.4.19;


import "./AxieManager.sol";


contract AxieDependency {

  address public whitelistSetterAddress;

  AxieSpawningManager public spawningManager;
  AxieRetirementManager public retirementManager;
  AxieMarketplaceManager public marketplaceManager;
  AxieGeneManager public geneManager;

  mapping (address => bool) public whitelistedSpawner;
  mapping (address => bool) public whitelistedByeSayer;
  mapping (address => bool) public whitelistedMarketplace;
  mapping (address => bool) public whitelistedGeneScientist;

  function AxieDependency() internal {
    whitelistSetterAddress = msg.sender;
  }

  modifier onlyWhitelistSetter() {
    require(msg.sender == whitelistSetterAddress);
    _;
  }

  modifier whenSpawningAllowed(uint256 _genes, address _owner) {
    require(
      spawningManager == address(0) ||
        spawningManager.isSpawningAllowed(_genes, _owner)
    );
    _;
  }

  modifier whenRebirthAllowed(uint256 _axieId, uint256 _genes) {
    require(
      spawningManager == address(0) ||
        spawningManager.isRebirthAllowed(_axieId, _genes)
    );
    _;
  }

  modifier whenRetirementAllowed(uint256 _axieId, bool _rip) {
    require(
      retirementManager == address(0) ||
        retirementManager.isRetirementAllowed(_axieId, _rip)
    );
    _;
  }

  modifier whenTransferAllowed(address _from, address _to, uint256 _axieId) {
    require(
      marketplaceManager == address(0) ||
        marketplaceManager.isTransferAllowed(_from, _to, _axieId)
    );
    _;
  }

  modifier whenEvolvementAllowed(uint256 _axieId, uint256 _newGenes) {
    require(
      geneManager == address(0) ||
        geneManager.isEvolvementAllowed(_axieId, _newGenes)
    );
    _;
  }

  modifier onlySpawner() {
    require(whitelistedSpawner[msg.sender]);
    _;
  }

  modifier onlyByeSayer() {
    require(whitelistedByeSayer[msg.sender]);
    _;
  }

  modifier onlyMarketplace() {
    require(whitelistedMarketplace[msg.sender]);
    _;
  }

  modifier onlyGeneScientist() {
    require(whitelistedGeneScientist[msg.sender]);
    _;
  }

  /*
   * @dev Setting the whitelist setter address to `address(0)` would be a irreversible process.
   *  This is to lock changes to Axie's contracts after their development is done.
   */
  function setWhitelistSetter(address _newSetter) external onlyWhitelistSetter {
    whitelistSetterAddress = _newSetter;
  }

  function setSpawningManager(address _manager) external onlyWhitelistSetter {
    spawningManager = AxieSpawningManager(_manager);
  }

  function setRetirementManager(address _manager) external onlyWhitelistSetter {
    retirementManager = AxieRetirementManager(_manager);
  }

  function setMarketplaceManager(address _manager) external onlyWhitelistSetter {
    marketplaceManager = AxieMarketplaceManager(_manager);
  }

  function setGeneManager(address _manager) external onlyWhitelistSetter {
    geneManager = AxieGeneManager(_manager);
  }

  function setSpawner(address _spawner, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedSpawner[_spawner] != _whitelisted);
    whitelistedSpawner[_spawner] = _whitelisted;
  }

  function setByeSayer(address _byeSayer, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedByeSayer[_byeSayer] != _whitelisted);
    whitelistedByeSayer[_byeSayer] = _whitelisted;
  }

  function setMarketplace(address _marketplace, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedMarketplace[_marketplace] != _whitelisted);
    whitelistedMarketplace[_marketplace] = _whitelisted;
  }

  function setGeneScientist(address _geneScientist, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedGeneScientist[_geneScientist] != _whitelisted);
    whitelistedGeneScientist[_geneScientist] = _whitelisted;
  }
}
