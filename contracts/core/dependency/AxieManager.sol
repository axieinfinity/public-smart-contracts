pragma solidity ^0.4.19;


interface AxieSpawningManager {
	function isSpawningAllowed(uint256 _genes, address _owner) external returns (bool);
  function isRebirthAllowed(uint256 _axieId, uint256 _genes) external returns (bool);
}

interface AxieRetirementManager {
  function isRetirementAllowed(uint256 _axieId, bool _rip) external returns (bool);
}

interface AxieMarketplaceManager {
  function isTransferAllowed(address _from, address _to, uint256 _axieId) external returns (bool);
}

interface AxieGeneManager {
  function isEvolvementAllowed(uint256 _axieId, uint256 _newGenes) external returns (bool);
}
