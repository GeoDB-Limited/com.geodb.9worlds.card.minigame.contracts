// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IVikings {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isVikingLocked(uint256 vikingId) external view returns (bool vikingStatus);
    function mintByType(address _owner, uint256 _type) external;
    function lockToken(uint256 tokenId, bool status) external;
    function tokenStrength(uint256 tokenId) external view returns (uint256 strength);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
}