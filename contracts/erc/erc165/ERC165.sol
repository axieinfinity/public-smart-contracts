pragma solidity ^0.4.19;


import "./IERC165.sol";


contract ERC165 is IERC165 {
  /// @dev You must not set element 0xffffffff to true
  mapping (bytes4 => bool) internal supportedInterfaces;

  function ERC165() internal {
    supportedInterfaces[0x01ffc9a7] = true; // ERC-165
  }

  function supportsInterface(bytes4 interfaceID) external view returns (bool) {
    return supportedInterfaces[interfaceID];
  }
}
