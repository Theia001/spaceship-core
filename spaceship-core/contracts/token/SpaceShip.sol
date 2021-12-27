// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../utils/ERC721Extra.sol";
import "../utils/Operator.sol";

contract SpaceShip is ERC721Extra("SpaceShip.Ship", "Ship"), Operator {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Ship {
        uint256 shipType;
        uint256 shipSubType;
        uint256 capacity;
    }

    uint256 public constant TYPE_S = 5;
    uint256 public constant TYPE_A = 4;
    uint256 public constant TYPE_B = 3;
    uint256 public constant TYPE_C = 2;
    uint256 public constant TYPE_D = 1;

    uint256 private _randomSalt;
    // type => array  arr[0] is min and arr[1] is max.
    mapping(uint256 => uint256[]) capacity;
    // type => subType => burnNum which num is subType burned.
    mapping(uint256 => mapping(uint256 => uint256)) private _subTypeBurnBalance;
    // type => subType => burnNum which num does not contain burned num.
    mapping(uint256 => mapping(uint256 => uint256)) private _subTypeBalance;
    // tokenId => ship
    mapping(uint256 => Ship) shipInfo;

    // type => subType => address => tokenIds
    mapping(uint256 => mapping(uint256 => mapping(address => EnumerableSet.UintSet))) private _holderTypeSubTokens;

    modifier checkType(uint256 _type) {
        require(
            _type == TYPE_A ||
            _type == TYPE_B ||
            _type == TYPE_C ||
            _type == TYPE_D, "SpaceShip: invalid type");
        _;
    }

    constructor(string memory _uri) public {
        _setBaseURI(_uri);

        // init capacity
        capacity[TYPE_A] = [80, 120];
        capacity[TYPE_B] = [40, 60];
        capacity[TYPE_C] = [20, 30];
        capacity[TYPE_D] = [10, 15];
        capacity[TYPE_S] = [240, 240];

        for (uint256 i = 1; i <= 4; i++) {
            _mintSub(msg.sender, TYPE_S, i);
        }
    }

    // only time lock to set
    function setBaseURI(string memory _uri) public onlyOwner {
        _setBaseURI(_uri);
    }

    // only time lock to set
    function setTypeCapacity(uint256 _type, uint256 _min, uint256 _max) public onlyOwner {
        require(_max >= _min, "SpaceShip: invalid min and max");
        capacity[_type][0] = _min;
        capacity[_type][1] = _max;
    }


    function mint(address _to, uint256 _type) public checkType(_type) onlyOperator {
        uint256 subType = _getSubType(_type);
        _mintSub(_to, _type, subType);
    }

    function mintSub(address _to, uint256 _type, uint256 _subType) public onlyOperator {
        _mintSub(_to, _type, _subType);
    }

    function burn(uint256 _tokenId) public override {
        address to = ownerOf(_tokenId);
        uint256 shipType = shipInfo[_tokenId].shipType;
        uint256 shipSubType = shipInfo[_tokenId].shipSubType;
        _subTypeBurnBalance[shipType][shipSubType] += 1;
        _subTypeBalance[shipType][shipSubType] -= 1;
        _holderTypeSubTokens[shipType][shipSubType][to].remove(_tokenId);
        super.burn(_tokenId);
    }

    function totalSubTypeSupply(uint256 _type, uint256 _subType) public view returns (uint256) {
        return _subTypeBalance[_type][_subType];
    }

    function totalBurnSubType(uint256 _type, uint256 _subType) public view returns (uint256) {
        return _subTypeBurnBalance[_type][_subType];
    }

    function balanceSubTypeOf(address _to, uint256 _type, uint256 _subType) public view returns (uint256) {
        return _holderTypeSubTokens[_type][_subType][_to].length();
    }

    function tokenSubTypeOfOwnerByIndex(address _owner, uint256 _index, uint256 _type, uint256 _subType) public view returns (uint256) {
        return _holderTypeSubTokens[_type][_subType][_owner].at(_index);
    }

    function getShip(uint256 _tokenId) public view returns (Ship memory ship) {
        ship = shipInfo[_tokenId];
    }

    /* ========== INTERNAL FUNCTION ========== */
    function _mintSub(address _to, uint256 _type, uint256 _subType) internal {

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        super._mintType(_to, newTokenId, _type);

        // update sub type info
        _subTypeBalance[_type][_subType] += 1;
        _holderTypeSubTokens[_type][_subType][_to].add(newTokenId);

        // set shipInfo
        shipInfo[newTokenId].shipType = _type;
        shipInfo[newTokenId].shipSubType = _subType;
        shipInfo[newTokenId].capacity = _getCapacity(_type);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal override {
        super._transfer(_from, _to, _tokenId);

        // update sub type info
        uint256 shipType = shipInfo[_tokenId].shipType;
        uint256 shipSubType = shipInfo[_tokenId].shipSubType;
        _holderTypeSubTokens[shipType][shipSubType][_from].remove(_tokenId);
        _holderTypeSubTokens[shipType][shipSubType][_to].add(_tokenId);
    }

    function _getSubType(uint256 _type) internal returns (uint256){
        uint256 subType;
        if (_type == TYPE_A) {
            subType = 1 + (_random() % 4);
        }
        if (_type == TYPE_B) {
            subType = 1 + (_random() % 8);
        }
        if (_type == TYPE_C) {
            subType = 1 + (_random() % 16);
        }
        if (_type == TYPE_D) {
            subType = 1 + (_random() % 32);
        }
        return subType;
    }

    function _getCapacity(uint256 _type) internal returns (uint256){
        uint256 min = capacity[_type][0];
        uint256 max = capacity[_type][1];
        uint256 base = max.sub(min);
        return base > 0 ? min.add(_random() % base) : min;
    }

    function _random() internal returns (uint256) {
        // inject global _randomSalt
        _randomSalt = uint256(keccak256(abi.encodePacked(
                (block.timestamp).add(block.difficulty)
                .add((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now))
                .add(block.gaslimit)
                .add((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now))
                .add(block.number)
                .add(_randomSalt))));
        return _randomSalt;
    }

}
