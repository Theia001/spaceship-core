// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";

contract ERC721Extra is ERC721Burnable {
    // burn num.
    uint256 private _burnBalance;
    // key is type and from address to get tokenId set.
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) private _holderTypeTokens;
    // key is tokenId return type
    mapping(uint256 => uint256) private _tokenIdToType;
    // key is type return num which num does not contain burned num.
    mapping(uint256 => uint256) private _typeBalance;
    // key is type return num which num is burned num.
    mapping(uint256 => uint256) private _typeBurnBalance;

    constructor (string memory name, string memory symbol) public ERC721(name, symbol){}

    function _mintType(address _to, uint256 _tokenId, uint256 _type) internal virtual {
        super._mint(_to, _tokenId);
        _tokenIdToType[_tokenId] = _type;
        _holderTypeTokens[_type][_to].add(_tokenId);
        _typeBalance[_type] += 1;
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal virtual override {
        super._transfer(_from, _to, _tokenId);
        _holderTypeTokens[_tokenIdToType[_tokenId]][_from].remove(_tokenId);
        _holderTypeTokens[_tokenIdToType[_tokenId]][_to].add(_tokenId);
    }

    function burn(uint256 _tokenId) public virtual override {
        address to = ownerOf(_tokenId);
        _holderTypeTokens[_tokenIdToType[_tokenId]][to].remove(_tokenId);
        _burnBalance += 1;
        _typeBalance[_tokenIdToType[_tokenId]] -= 1;
        _typeBurnBalance[_tokenIdToType[_tokenId]] += 1;
        super.burn(_tokenId);
    }

    function getTypeByTokenId(uint256 _tokenId) public view returns (uint256) {
        return _tokenIdToType[_tokenId];
    }

    function balanceTypeOf(address _to, uint256 _type) public view returns (uint256) {
        return _holderTypeTokens[_type][_to].length();
    }

    function totalTypeSupply(uint256 _type) public view returns (uint256) {
        return _typeBalance[_type];
    }

    function totalBurnType(uint256 _type) public view returns (uint256) {
        return _typeBurnBalance[_type];
    }

    function totalBurn() public view returns (uint256) {
        return _burnBalance;
    }

    function tokenTypeOfOwnerByIndex(address _owner, uint256 _index, uint256 _type) public view returns (uint256) {
        return _holderTypeTokens[_type][_owner].at(_index);
    }
}
